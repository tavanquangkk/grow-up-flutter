// プラットフォーム対応Token Store Factory
import 'package:flutter/foundation.dart' show kIsWeb;
import 'token_store.dart';

/// プラットフォーム対応Token Store Factory
class PlatformTokenStore {
  static TokenStore create() {
    if (kIsWeb) {
      // Web環境では実際にはSharedPreferencesがlocalStorageにマップされる
      return SharedPrefsTokenStore();
    } else {
      // Mobile/Desktop環境
      return CompositeTokenStore();
    }
  }
}
