import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:grow_up/core/config/api_config.dart';
import 'package:grow_up/core/utils/auth/token_store.dart';
import 'package:grow_up/core/utils/auth/jwt_utils.dart';
import 'package:grow_up/features/chat/dto/chat_history_response.dart';

/// 認証付き HTTP 通信まわりの共通処理を提供するサービスクラス。
/// 主な責務:
/// - ログイン/登録とトークン保管 (access / refresh / userId)
/// - アクセストークン期限の事前判定 & 自動リフレッシュ
/// - 401 発生時の再試行 (1 回) と失敗時のトークン破棄
/// - サーバー一時障害 (408 / 429 / 5xx) の指数バックオフ付き再試行
/// - テスト注入 (TokenStore / http.Client) 用フック
/// - 認証失効通知コールバック (onAuthExpired)
class ApiService {
  static String get baseUrl => ApiConfig.authBaseUrl;

  // Token store (default: Composite -> refresh token secure, access in prefs)
  /// Token の永続化レイヤ。デフォルトは Composite:
  ///  - access / userId: SharedPreferences
  ///  - refresh: flutter_secure_storage (Keychain / Keystore)
  static TokenStore _store = CompositeTokenStore();

  // HTTP client (injectable for tests)
  /// HTTP クライアント。テスト時に MockClient を差し替え可能。
  static http.Client httpClient = http.Client();

  // メモリキャッシュ
  /// メモリキャッシュ (I/O 削減 & 同期的参照用)。
  static String? _cachedAccess;
  static String? _cachedRefresh;

  // ログ/デバッグ (必要なら差し替え可能)
  /// 開発ビルドのみログ出力する簡易ラッパ。
  static bool _forceVerbose = false; // 強制詳細ログフラグ
  static void enableVerboseLogging([bool enable = true]) =>
      _forceVerbose = enable;
  static void _log(String msg) {
    // リリースでは forceVerbose が true のときのみ
    final should = _forceVerbose || (!kReleaseMode);
    if (should) {
      // ignore: avoid_print
      print('[ApiService] $msg');
    }
  }

  // 先行リフレッシュ閾値(秒)
  /// アクセストークン有効期限の何秒前から事前リフレッシュを試みるか。
  static const int _kProactiveRefreshThreshold = 30;

  // 認証失効通知用コールバック (UIで設定)
  /// 認証状態が無効(リフレッシュ不能/再試行後401)になった際に 1 度呼ばれるコールバック。
  static VoidCallback? onAuthExpired;

  // ================= Auth: Register & Login =================
  /// ユーザー登録。成功時 data 内の token 群を保存する。
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await httpClient.post(
      Uri.parse('$baseUrl/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = _decode(res);
    final payload = data is Map ? data['data'] : null;
    if (_isSuccess(res, data) && payload != null) {
      await _storeTokensFromResponse(payload);
    } else if (!_isSuccess(res, data)) {
      _log('register failed status=${res.statusCode} body=${res.body}');
    }
    return data;
  }

  /// ログイン。既存トークン破棄後に新しい token を保存し、成功フックを実行。
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    await clearTokens();
    _cachedAccess = null;
    _cachedRefresh = null;
    final res = await httpClient.post(
      Uri.parse('$baseUrl/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    final payload = data is Map ? data['data'] : null;
    if (_isSuccess(res, data) && payload != null) {
      await _storeTokensFromResponse(payload);
      _onLoginSuccessHook();
    } else if (!_isSuccess(res, data)) {
      _log('login failed status=${res.statusCode} body=${res.body}');
    }
    return data;
  }

  // ================= Refresh =================
  /// リフレッシュトークンを使い新しいアクセストークン(と場合により新しい refresh)を取得。
  /// 失敗時は false を返し、呼び出し元で破棄判断を行う。
  static Future<bool> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    // refreshToken 自体の期限近いなら即失敗扱い (サーバー401想定)
    if (JwtUtils.willExpireSoon(refresh, thresholdSec: 0)) {
      _log('refresh token already expired');
      return false;
    }
    try {
      final res = await httpClient.post(
        Uri.parse('$baseUrl/refresh'),
        headers: _jsonHeaders(),
        body: jsonEncode({'refreshToken': refresh}),
      );
      final data = _decode(res);
      if (!_isSuccess(res, data)) {
        _log('refresh failed status=${res.statusCode} body=${res.body}');
        return false;
      }
      final p = data['data'];
      final newAccess = p?['newAccessToken'] ?? p?['token'];
      final newRefresh = p?['newRefreshToken'] ?? p?['refreshToken'];
      if (newAccess is! String || newAccess.isEmpty) {
        _log('refresh missing new access token');
        return false;
      }
      await _store.save(
        access: newAccess,
        refresh: (newRefresh is String && newRefresh.isNotEmpty)
            ? newRefresh
            : null,
      );
      _cachedAccess = newAccess;
      if (newRefresh is String && newRefresh.isNotEmpty) {
        _cachedRefresh = newRefresh;
      }
      _log('refresh success');
      return true;
    } catch (e) {
      _log('refresh exception: $e');
      return false;
    }
  }

  // ================= Chat History =================
  /// チャット履歴を取得する
  static Future<ChatHistoryResponse?> getChatHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      // チャット履歴APIは8081ポートを使用し、直接 /chats エンドポイントにアクセス
      final uri = Uri.parse(
        '${ApiConfig.chatBaseUrl}/chats',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      // JWTトークンの内容をデバッグ
      final token = await getToken();
      if (token != null) {
        final payload = JwtUtils.decodePayload(token);
        _log('JWT payload: $payload');
        _log('JWT sub: ${JwtUtils.getSubject(token)}');
        _log('JWT userId: ${JwtUtils.getUserId(token)}');
      }

      _log('getChatHistory requesting: ${uri.toString()}');
      final response = await getWithAuth(uri.toString());

      _log('getChatHistory response status: ${response.statusCode}');
      _log('getChatHistory response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _decode(response);
        _log('getChatHistory decoded data: $data');

        // チャット履歴APIは他のAPIと異なり、直接messagesとtotalを返す
        if (data is Map && data.containsKey('messages')) {
          _log('getChatHistory success, parsing data...');
          return ChatHistoryResponse.fromJson(Map<String, dynamic>.from(data));
        } else if (_isSuccess(response, data)) {
          // 従来のAPI形式（data.dataの形式）の場合
          _log('getChatHistory success (standard format), parsing data...');
          return ChatHistoryResponse.fromJson(data['data']);
        } else {
          _log('getChatHistory not successful: ${data['status']}');
        }
      }

      _log('getChatHistory failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      _log('getChatHistory error: $e');
      return null;
    }
  }

  // ================= Authorized GET (401→refresh→retry) =================
  /// 認証付き GET。必要に応じて事前リフレッシュ → 401 時の再試行を行う。
  static Future<http.Response> getWithAuth(String url) async {
    return _authorizedRequest(() async {
      final token = await _getValidAccessToken();
      if (token == null || token.isEmpty) {
        _log('skip request (no token) GET $url');
        return http.Response('Unauthorized', 401);
      }
      return httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  // ================= Authorized POST/PUT/DELETE =================
  /// 認証付き POST。
  static Future<http.Response> postWithAuth(String url, {Object? body}) async {
    return _authorizedRequest(() async {
      final token = await _getValidAccessToken();
      if (token == null || token.isEmpty) {
        _log('skip request (no token) POST $url');
        return http.Response('Unauthorized', 401);
      }
      return httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    });
  }

  /// 認証付き PUT。
  static Future<http.Response> putWithAuth(String url, {Object? body}) async {
    return _authorizedRequest(() async {
      final token = await _getValidAccessToken();
      if (token == null || token.isEmpty) {
        _log('skip request (no token) PUT $url');
        return http.Response('Unauthorized', 401);
      }
      return httpClient.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    });
  }

  /// 認証付き DELETE。
  static Future<http.Response> deleteWithAuth(String url) async {
    return _authorizedRequest(() async {
      final token = await _getValidAccessToken();
      if (token == null || token.isEmpty) {
        _log('skip request (no token) DELETE $url');
        return http.Response('Unauthorized', 401);
      }
      return httpClient.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    });
  }

  /// 401 検知とリフレッシュ再試行を統合管理する内部ラッパ。
  static Future<http.Response> _authorizedRequest(
    Future<http.Response> Function() fn,
  ) async {
    var res = await _withRetry(fn, label: 'request');
    if (res.statusCode != 401) return res;

    final refreshed = await _refreshAccessTokenSafe();
    if (!refreshed) {
      // refresh 失敗時はトークンをクリアして 401 をそのまま返す
      await clearTokens();
      _notifyAuthExpired();
      return res;
    }
    // retry once after successful refresh
    res = await _withRetry(fn, label: 'request-after-refresh');
    if (res.statusCode == 401) {
      // still unauthorized after refresh
      await clearTokens();
      _notifyAuthExpired();
    }
    return res;
  }

  // ===== Concurrency-safe refresh (prevents multiple parallel refresh calls) =====
  static Future<bool>? _ongoingRefresh;

  /// 進行中リフレッシュを共有し、同時複数リフレッシュを防ぐ。
  static Future<bool> _refreshAccessTokenSafe() async {
    // 既に進行中ならそれを待つ
    if (_ongoingRefresh != null) return await _ongoingRefresh!;
    final completer = Completer<bool>();
    _ongoingRefresh = completer.future;
    bool ok = false;
    try {
      ok = await refreshAccessToken();
      completer.complete(ok);
    } catch (e) {
      completer.complete(false);
    } finally {
      _ongoingRefresh = null;
    }
    return ok;
  }

  // ================= Token Helpers =================
  /// レスポンス data から token / refresh / userId を抽出して保存 & キャッシュ。
  static Future<void> _storeTokensFromResponse(dynamic d) async {
    if (d == null) return;
    final access = d['accessToken'] ?? d['token'];
    final refresh = d['refreshToken'] ?? d['refresh_token'];
    final userId = d['id'] ?? (d['user'] != null ? d['user']['id'] : null);
    await _store.save(access: access, refresh: refresh, userId: userId);
    if (access is String) _cachedAccess = access;
    if (refresh is String) _cachedRefresh = refresh;
  }

  /// アクセストークン取得 (キャッシュ優先)。
  static Future<String?> getToken() async {
    if (_cachedAccess != null) return _cachedAccess;
    _cachedAccess = await _store.readAccess();
    return _cachedAccess;
  }

  /// リフレッシュトークン取得 (キャッシュ優先)。
  static Future<String?> getRefreshToken() async {
    if (_cachedRefresh != null) return _cachedRefresh;
    _cachedRefresh = await _store.readRefresh();
    return _cachedRefresh;
  }

  /// 旧 API 互換。現在は clearTokens と同義。
  static Future<void> removeToken() async {
    // Deprecated: use clearTokens(); keep behavior simple -> full clear
    await clearTokens();
  }

  /// すべてのトークンとキャッシュを削除。
  static Future<void> clearTokens() async {
    await _store.clear();
    _cachedAccess = null;
    _cachedRefresh = null;
  }

  /// ログアウト（トークン完全削除）。
  static Future<void> logout() async => clearTokens();

  // ================= Utils =================
  /// 共通 JSON ヘッダ。
  static Map<String, String> _jsonHeaders() => {
    'Content-Type': 'application/json',
  };

  /// API の共通 success 判定: HTTP 200 かつ JSON の status = success。
  static bool _isSuccess(http.Response res, dynamic data) =>
      res.statusCode == 200 && data is Map && data['status'] == 'success';

  /// JSON デコード。失敗時はエラー形式の Map を返す。
  static dynamic _decode(http.Response res) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return {'status': 'error', 'message': 'Invalid JSON'};
    }
  }

  /// 認証失効通知 (UI 側で再ログイン誘導など)。
  static void _notifyAuthExpired() {
    final cb = onAuthExpired;
    if (cb != null) {
      try {
        cb();
      } catch (_) {}
    }
  }

  // 事前リフレッシュ付きアクセストークン取得
  /// 有効なアクセストークンを取得。期限接近なら事前リフレッシュ。
  static Future<String?> _getValidAccessToken() async {
    var token = await getToken();
    if (token == null || token.isEmpty) {
      _log('no access token in cache');
      _notifyAuthExpired();
      return null;
    }
    if (JwtUtils.willExpireSoon(
      token,
      thresholdSec: _kProactiveRefreshThreshold,
    )) {
      _log('access token will expire soon -> proactive refresh');
      final ok = await _refreshAccessTokenSafe();
      if (ok) {
        token = await getToken();
        _log('proactive refresh succeeded');
      } else {
        _log('proactive refresh failed');
        _notifyAuthExpired();
        return null;
      }
    }
    return token;
  }

  // ログイン成功後フック例(必要ならプロフィールプリロード等を追加)
  /// ログイン成功時のフック。将来プロフィールプリロード等を追加可能。
  static void _onLoginSuccessHook() {
    _log('login success: tokens stored');
  }

  // ========= Retry Logic =========
  /// 一時的エラー用指数バックオフ付きリトライヘルパー。
  static Future<http.Response> _withRetry(
    Future<http.Response> Function() call, {
    String label = 'req',
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    http.Response? last;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        last = await call();
        if (!_shouldRetryStatus(last.statusCode)) return last;
        _log('$label attempt=$attempt status=${last.statusCode} -> retry');
      } catch (e) {
        if (attempt >= maxAttempts) {
          _log('$label exception final: $e');
          rethrow;
        }
        _log('$label exception=$e attempt=$attempt -> retry');
      }
      if (attempt < maxAttempts) {
        final backoff = Duration(milliseconds: 150 * attempt * attempt);
        await Future.delayed(backoff);
      }
    }
    return last ?? http.Response('No Response', 599);
  }

  /// リトライ対象となる HTTP ステータス判定。
  static bool _shouldRetryStatus(int code) {
    if (code == 408 || code == 429) return true; // timeout / rate limit
    if (code >= 500 && code < 600) return true; // server errors
    return false;
  }

  // ========= Test / Config Helpers =========
  /// TokenStore を差し替える (テストやポリシー変更用)。
  static void setTokenStore(TokenStore store) {
    _store = store;
  }

  /// メモリキャッシュをクリア (テスト・手動リセット用)。
  static void resetCache() {
    _cachedAccess = null;
    _cachedRefresh = null;
  }

  // ========= Diagnostics =========
  /// 現在の baseUrl / アクセストークン / リフレッシュトークン(省略表示) をログ出力。
  static Future<void> debugPrintEnv() async {
    final t = await getToken();
    final r = await getRefreshToken();
    _log('ENV baseUrl=$baseUrl access=${_short(t)} refresh=${_short(r)}');
  }

  /// 任意パスへシンプルな GET を送りステータスと本文冒頭を返す。
  static Future<String> ping(String relativePath) async {
    final url = relativePath.startsWith('http')
        ? relativePath
        : '${ApiConfig.baseUrl}$relativePath';
    try {
      final res = await httpClient.get(Uri.parse(url));
      final preview = res.body.length > 120
          ? res.body.substring(0, 120) + '...'
          : res.body;
      final msg =
          'PING status=${res.statusCode} url=$url bodyPreview="$preview"';
      _log(msg);
      return msg;
    } catch (e) {
      final msg = 'PING exception url=$url error=$e';
      _log(msg);
      return msg;
    }
  }

  static String _short(String? token) {
    if (token == null || token.isEmpty) return 'NULL';
    if (token.length <= 10) return token;
    return token.substring(0, 4) + '...' + token.substring(token.length - 4);
  }

  /// 現在ログインしているユーザーのIDを取得
  static Future<String?> getCurrentUserId() async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        return JwtUtils.getUserId(token);
      }
      return null;
    } catch (e) {
      _log('Error getting current user ID: $e');
      return null;
    }
  }
}
