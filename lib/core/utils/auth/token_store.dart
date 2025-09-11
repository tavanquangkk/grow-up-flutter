import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 抽象化: 将来的に flutter_secure_storage へ差し替えやすくする
abstract class TokenStore {
  Future<void> save({String? access, String? refresh, String? userId});
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<String?> readUserId();
  Future<void> clear();
}

class SharedPrefsTokenStore implements TokenStore {
  static const _kAccess = 'auth_token';
  static const _kRefresh = 'refresh_token';
  static const _kUserId = 'userId';

  @override
  Future<void> save({String? access, String? refresh, String? userId}) async {
    final p = await SharedPreferences.getInstance();
    if (access != null) await p.setString(_kAccess, access);
    if (refresh != null) await p.setString(_kRefresh, refresh);
    if (userId != null) await p.setString(_kUserId, userId);
  }

  @override
  Future<String?> readAccess() async =>
      (await SharedPreferences.getInstance()).getString(_kAccess);

  @override
  Future<String?> readRefresh() async =>
      (await SharedPreferences.getInstance()).getString(_kRefresh);

  @override
  Future<String?> readUserId() async =>
      (await SharedPreferences.getInstance()).getString(_kUserId);

  @override
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kUserId);
  }
}

/// SecureStorage 実装: refresh を安全に保存 (iOS Keychain / Android Keystore)
class SecureTokenStore implements TokenStore {
  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'auth_token';
  static const _kRefresh = 'refresh_token';
  static const _kUserId = 'userId';

  @override
  Future<void> save({String? access, String? refresh, String? userId}) async {
    final futures = <Future<void>>[];
    if (access != null)
      futures.add(_storage.write(key: _kAccess, value: access));
    if (refresh != null)
      futures.add(_storage.write(key: _kRefresh, value: refresh));
    if (userId != null)
      futures.add(_storage.write(key: _kUserId, value: userId));
    await Future.wait(futures);
  }

  @override
  Future<String?> readAccess() => _storage.read(key: _kAccess);

  @override
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  @override
  Future<String?> readUserId() => _storage.read(key: _kUserId);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUserId);
  }
}

/// Composite: access は SharedPreferences, refresh は SecureStorage
class CompositeTokenStore implements TokenStore {
  final SharedPrefsTokenStore _prefs = SharedPrefsTokenStore();
  final SecureTokenStore _secure = SecureTokenStore();

  @override
  Future<void> save({String? access, String? refresh, String? userId}) async {
    final futures = <Future<void>>[];
    if (access != null || userId != null) {
      futures.add(_prefs.save(access: access, userId: userId));
    }
    if (refresh != null) {
      futures.add(_secure.save(refresh: refresh));
    }
    await Future.wait(futures);
  }

  @override
  Future<String?> readAccess() => _prefs.readAccess();

  @override
  Future<String?> readRefresh() => _secure.readRefresh();

  @override
  Future<String?> readUserId() => _prefs.readUserId();

  @override
  Future<void> clear() async {
    await _prefs.clear();
    await _secure.clear();
  }
}
