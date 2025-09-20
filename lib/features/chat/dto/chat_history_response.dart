import '../websocket/ChatService.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';

class ChatHistoryResponse {
  final List<ChatMessage> messages;
  final int total;

  ChatHistoryResponse({required this.messages, required this.total});

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    print("=== ChatHistoryResponse: Parsing JSON: $json ===");

    final messagesList = json['messages'] as List<dynamic>? ?? [];
    print(
      "=== ChatHistoryResponse: Messages list length: ${messagesList.length} ===",
    );

    final messages = messagesList
        .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
        .toList();

    final total = json['total'] as int? ?? messagesList.length;
    print("=== ChatHistoryResponse: Total: $total ===");

    return ChatHistoryResponse(messages: messages, total: total);
  }

  /// 現在のユーザーIDを考慮してメッセージを解析
  static Future<ChatHistoryResponse> fromJsonWithCurrentUser(
    Map<String, dynamic> json,
  ) async {
    print("=== ChatHistoryResponse: Parsing JSON with current user: $json ===");

    final messagesList = json['messages'] as List<dynamic>? ?? [];
    print(
      "=== ChatHistoryResponse: Messages list length: ${messagesList.length} ===",
    );

    // 現在のユーザーIDを取得
    final currentUserId = await ApiService.getCurrentUserId();
    print("=== ChatHistoryResponse: Current user ID: $currentUserId ===");

    final messages = <ChatMessage>[];
    for (final msgJson in messagesList) {
      final msg = await ChatMessage.fromJsonWithCurrentUser(
        msgJson as Map<String, dynamic>,
        currentUserId,
      );
      messages.add(msg);
    }

    final total = json['total'] as int? ?? messagesList.length;
    print("=== ChatHistoryResponse: Total: $total ===");

    return ChatHistoryResponse(messages: messages, total: total);
  }
}
