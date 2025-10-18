import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API接続設定を管理するクラス
/// 新しいPCでテストする際は、DEV_SERVER_IPを変更してください
class ApiConfig {
  /// 開発用サーバーのIPアドレス
  /// 新しいPCに移行する際は、このIPアドレスを新しいPCのものに変更してください
  ///
  /// IPアドレスの確認方法:
  /// - Windows: ipconfig | findstr "IPv4"
  /// - Mac: ifconfig | grep "inet " | grep -v 127.0.0.1
  /// - Linux: ip addr show | grep "inet " | grep -v 127.0.0.1
  static const String DEV_SERVER_IP = '127.0.0.1';

  /// サーバーポート番号
  static const String SERVER_PORT = '8080';

  /// 環境に応じてbaseURLを自動で切り替える
  /// 実機(iOS/Android): 開発用PCのIPアドレスを使用
  /// シミュレータ/デスクトップ: localhostを使用
  static String get baseUrl {
    String url;
    if (kIsWeb) {
      // ブラウザー用
      url = 'http://$DEV_SERVER_IP:$SERVER_PORT';
      print('🌐 [API_CONFIG] ブラウザー環境detected - Using URL: $url');
      return url;
    } else if (Platform.isIOS || Platform.isAndroid) {
      // 実機用 - 開発用PCのIPアドレス
      url = 'http://$DEV_SERVER_IP:$SERVER_PORT';
      print('� [API_CONFIG] 実機環境detected - Using URL: $url');
    } else {
      // シミュレータ・デスクトップ用
      url = 'http://localhost:$SERVER_PORT';
      print('�️ [API_CONFIG] シミュレータ環境detected - Using URL: $url');
    }
    print(
      '🔧 [API_CONFIG] Platform.isIOS: ${Platform.isIOS}, Platform.isAndroid: ${Platform.isAndroid}',
    );
    return url;
  }

  /// 認証API用のbaseURL
  static String get authBaseUrl => '${baseUrl}/api/v1/auth';

  /// ホーム・ワークショップAPI用のbaseURL
  static String get workshopBaseUrl => '${baseUrl}/api/v1';

  /// チャット履歴API用のbaseURL（ポート8081）
  static String get chatBaseUrl {
    String url;

    if (kIsWeb) {
      // ブラウザー用
      url = 'http://$DEV_SERVER_IP:8081';
      print('🌐 [API_CONFIG] Chat ブラウザー環境 - Using URL: $url');
    } else if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      // 実機用
      url = 'http://$DEV_SERVER_IP:8081';
      print('📱 [API_CONFIG] Chat 実機環境 - Using URL: $url');
    } else {
      // シミュレータ・デスクトップ用
      url = 'http://localhost:8081';
      print('🖥️ [API_CONFIG] Chat シミュレータ環境 - Using URL: $url');
    }

    return url;
  }

  /// WebSocket URL（ブラウザー対応）
  static String get wsBaseUrl {
    String url;

    if (kIsWeb) {
      // ブラウザー用 - wsプロトコル使用
      url = 'ws://$DEV_SERVER_IP:8081';
      print('🌐 [API_CONFIG] WebSocket ブラウザー環境 - Using URL: $url');
    } else if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      // 実機用
      url = 'ws://$DEV_SERVER_IP:8081';
      print('📱 [API_CONFIG] WebSocket 実機環境 - Using URL: $url');
    } else {
      // シミュレータ・デスクトップ用
      url = 'ws://localhost:8081';
      print('🖥️ [API_CONFIG] WebSocket シミュレータ環境 - Using URL: $url');
    }

    return url;
  }
}
