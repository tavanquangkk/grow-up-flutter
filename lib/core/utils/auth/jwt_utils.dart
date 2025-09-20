import 'dart:convert';

class JwtUtils {
  /// JWT の exp が threshold 秒以内なら true を返す (既に切れている場合も true)
  static bool willExpireSoon(String? jwt, {int thresholdSec = 30}) {
    if (jwt == null || jwt.isEmpty) return true;
    final parts = jwt.split('.');
    if (parts.length != 3) return true;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson);
      final exp = payload['exp'];
      if (exp is int) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return (exp - now) < thresholdSec;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// JWT ペイロードをデコードして返す (デバッグ用)
  static Map<String, dynamic>? decodePayload(String? jwt) {
    if (jwt == null || jwt.isEmpty) return null;
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payloadJson);
    } catch (e) {
      print('JWT decode error: $e');
      return null;
    }
  }

  /// JWT から userId を取得する
  static String? getUserId(String? jwt) {
    final payload = decodePayload(jwt);
    return payload?['userId'] as String?;
  }

  /// JWT から sub (subject) を取得する
  static String? getSubject(String? jwt) {
    final payload = decodePayload(jwt);
    return payload?['sub'] as String?;
  }
}
