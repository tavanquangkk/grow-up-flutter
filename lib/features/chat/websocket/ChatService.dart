import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:grow_up/features/chat/dto/chat_history_response.dart';
import 'package:grow_up/core/config/api_config.dart';

// サーバーから送られてくるメッセージのデータ構造
class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // senderNameが"Unknown User"の場合は、senderIdを使用
    String senderName = json['senderName'] ?? 'Unknown User';
    final senderId = json['senderId'] ?? 'unknown';

    if (senderName == 'Unknown User' || senderName.isEmpty) {
      senderName = 'User_$senderId';
      print("📝 [ChatMessage] Using senderId for name: $senderName");
    }

    return ChatMessage(
      messageId: json['messageId'],
      senderId: senderId,
      senderName: senderName,
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// 現在のユーザーIDと比較して表示名を決定
  static Future<ChatMessage> fromJsonWithCurrentUser(
    Map<String, dynamic> json,
    String? currentUserId,
  ) async {
    String senderName = json['senderName'] ?? 'Unknown User';
    final senderId = json['senderId'] ?? 'unknown';

    // 現在のユーザーの場合は「You」と表示
    if (currentUserId != null && senderId == currentUserId) {
      senderName = 'You';
    } else if (senderName == 'Unknown User' || senderName.isEmpty) {
      // 他のユーザーでsenderNameが不明な場合はUser_[ID]
      senderName = 'User_$senderId';
    }

    print(
      "📝 [ChatMessage] Display name: $senderName (senderId: $senderId, currentUserId: $currentUserId)",
    );

    return ChatMessage(
      messageId: json['messageId'],
      senderId: senderId,
      senderName: senderName,
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatService {
  WebSocketChannel? _channel;
  Stream<ChatMessage>? messageStream;

  // 1. WebSocketに接続する（保存されているtokenを自動取得）
  Future<void> connect() async {
    // 既に接続があれば、一度切断する
    disconnect();

    try {
      // 保存されているアクセストークンを取得
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        print("No access token found. Cannot connect to WebSocket.");
        return;
      }

      print("Connecting with token: ${token.substring(0, 20)}..."); // デバッグ用

      // トークンの末尾の不要な文字を除去（# など）
      final cleanToken = token.trim().replaceAll(RegExp(r'[#\s]+$'), '');
      print("Clean token: ${cleanToken.substring(0, 20)}..."); // デバッグ用

      // WebSocket接続のURLを作成 - パスパラメータとして送信（元の方法）
      final wsUrl = '${ApiConfig.wsBaseUrl}/chat-socket/$cleanToken';
      print("Connecting to: $wsUrl"); // デバッグ用

      final uri = Uri.parse(wsUrl);

      // または、ヘッダーでトークンを送信する場合：
      // final uri = Uri.parse('ws://localhost:8081/chat-socket');

      // WebSocket接続を作成 - IOWebSocketChannelを使用して明示的にws://プロトコルを使用
      try {
        _channel = IOWebSocketChannel.connect(
          uri,
          headers: {'Origin': 'http://localhost:8081'},
        );
      } catch (e) {
        print("Error creating WebSocket channel: $e");
        // フォールバック: 標準のWebSocketChannelを使用
        _channel = WebSocketChannel.connect(uri);
      }

      // サーバーからのメッセージを待ち受ける（1つのstreamのみを使用）
      messageStream = _channel!.stream
          .asyncMap((message) async {
            print("Received message: $message"); // デバッグ用
            final decoded = jsonDecode(message);

            // 現在のユーザーIDを取得して表示名を調整
            final currentUserId = await ApiService.getCurrentUserId();
            return await ChatMessage.fromJsonWithCurrentUser(
              decoded,
              currentUserId,
            );
          })
          .handleError((error) {
            print("WebSocket stream error: $error");
            disconnect();
          })
          .asBroadcastStream(); // 複数のウィジェットでlistenできるようにする

      print("WebSocket connected successfully");
    } catch (e) {
      print("Failed to connect to WebSocket: $e");
      disconnect();
    }
  } // 接続状態をチェックする

  bool get isConnected => _channel != null && _channel!.closeCode == null;

  // 2. メッセージをサーバーに送信する
  void sendMessage(String content) {
    if (!isConnected) {
      print("WebSocket is not connected. Cannot send message.");
      return;
    }

    try {
      final message = {"content": content};
      final jsonMessage = jsonEncode(message);
      print("Sending message: $jsonMessage"); // デバッグ用
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // 3. 接続を切断する
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    print("WebSocket disconnected");
  }

  // トークンが更新された場合の再接続メソッド
  Future<void> reconnect() async {
    print("Attempting to reconnect WebSocket...");
    disconnect();
    await connect();
  }

  // トークンのリフレッシュと再接続
  Future<void> refreshTokenAndReconnect() async {
    try {
      // トークンをリフレッシュ（ApiServiceに実装されている場合）
      // await ApiService.refreshToken();
      print("Refreshing token and reconnecting...");
      await reconnect();
    } catch (e) {
      print("Error refreshing token: $e");
    }
  }

  // 4. チャット履歴を取得する
  Future<List<ChatMessage>> getChatHistory({int? limit, int? offset}) async {
    print("=== ChatService: Starting getChatHistory ===");
    try {
      // 現在のユーザーIDを取得
      final currentUserId = await ApiService.getCurrentUserId();
      print("=== ChatService: Current user ID: $currentUserId ===");

      final response = await ApiService.getChatHistory(
        limit: limit ?? 50,
        offset: offset ?? 0,
      );

      print(
        "=== ChatService: ApiService.getChatHistory returned: $response ===",
      );

      if (response != null) {
        print(
          "=== ChatService: Chat history loaded: ${response.messages.length} messages ===",
        );
        print("=== ChatService: Total messages in DB: ${response.total} ===");

        // メッセージの表示名を現在ユーザーに合わせて調整
        final adjustedMessages = <ChatMessage>[];
        for (final msg in response.messages) {
          String displayName = msg.senderName;
          if (currentUserId != null && msg.senderId == currentUserId) {
            displayName = 'You';
          } else if (msg.senderName == 'Unknown User' ||
              msg.senderName.isEmpty) {
            displayName = 'User_${msg.senderId}';
          }

          adjustedMessages.add(
            ChatMessage(
              messageId: msg.messageId,
              senderId: msg.senderId,
              senderName: displayName,
              content: msg.content,
              timestamp: msg.timestamp,
            ),
          );
        }

        // メッセージの詳細をデバッグ出力
        for (int i = 0; i < adjustedMessages.length && i < 3; i++) {
          final msg = adjustedMessages[i];
          print(
            "=== ChatService: Message $i: ${msg.senderName} - ${msg.content} - ${msg.timestamp} ===",
          );
        }

        return adjustedMessages;
      } else {
        print(
          "=== ChatService: Failed to load chat history (response is null) ===",
        );
        return [];
      }
    } catch (e, stackTrace) {
      print("=== ChatService: Error loading chat history: $e ===");
      print("=== ChatService: Stack trace: $stackTrace ===");
      return [];
    }
  }
}
