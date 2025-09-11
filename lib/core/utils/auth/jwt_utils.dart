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
}
