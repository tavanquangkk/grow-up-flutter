import 'dart:async';
import 'package:flutter/material.dart';
import '../features/chat/websocket/ChatService.dart'; // 作成したサービスをインポート

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print("=== Initializing chat ===");

    // まず過去のチャット履歴を読み込み
    await _loadChatHistory();

    // その後にWebSocket接続
    await _chatService.connect();

    // 既存の購読がある場合はキャンセル
    _messageSubscription?.cancel();

    // メッセージストリームをリッスン
    print("=== Setting up message stream listener ===");
    _messageSubscription = _chatService.messageStream?.listen(
      (message) {
        print(
          "=== Received message in ChatScreen: ${message.content} from ${message.senderName} ===",
        );
        setState(() {
          // 重複チェック：同じmessageIdがすでに存在するかチェック
          final exists = _messages.any((m) => m.messageId == message.messageId);
          if (!exists) {
            _messages.insert(0, message); // 新しいメッセージをリストの先頭に追加
            print(
              "=== Message added to UI. Total messages: ${_messages.length} ===",
            );
          } else {
            print("=== Duplicate message ignored: ${message.messageId} ===");
          }
        });
      },
      onError: (error) {
        print("=== WebSocket error in ChatScreen: $error ===");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("接続エラーが発生しました: $error")));
      },
      onDone: () {
        print("=== WebSocket connection closed in ChatScreen ===");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("接続が切断されました")));
      },
    );

    if (_messageSubscription == null) {
      print("=== ERROR: Failed to set up message stream subscription ===");
    } else {
      print("=== Message stream subscription set up successfully ===");
    }
  }

  Future<void> _loadChatHistory() async {
    print("=== Starting to load chat history ===");
    try {
      final history = await _chatService.getChatHistory(limit: 50, offset: 0);
      print("=== Chat history result: ${history.length} messages ===");
      setState(() {
        // 履歴は新しい順で取得されるので、そのまま設定
        _messages.clear(); // 既存のメッセージをクリア
        _messages.addAll(history);
        // 最新のメッセージが下に来るようにソート（timestampの降順）
        _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
      print("Loaded ${history.length} messages from history");

      // デバッグ用：取得したメッセージの詳細をログ出力
      for (int i = 0; i < history.length && i < 3; i++) {
        final msg = history[i];
        print("History message $i: ${msg.senderName} - ${msg.content}");
      }
    } catch (e) {
      print("Error loading chat history: $e");
      // エラーが発生した場合もUIに表示
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("履歴の読み込みに失敗しました: $e")));
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel(); // ストリーム購読をキャンセル
    _chatService.disconnect(); // 画面が閉じるときに接続を切断
    _textController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    if (!_chatService.isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("WebSocketに接続されていません")));
      return;
    }

    _chatService.sendMessage(content);
    _textController.clear();
  }

  Future<void> _reconnect() async {
    _messageSubscription?.cancel(); // 既存の購読をキャンセル
    await _chatService.reconnect();
    await _initializeChat(); // 再接続後に初期化をやり直し
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("再接続しました")));
  }

  Future<void> _refreshHistory() async {
    print("=== Refreshing chat history ===");
    await _loadChatHistory();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("履歴を更新しました")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _refreshHistory,
            tooltip: '履歴更新',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reconnect,
            tooltip: '再接続',
          ),
        ],
      ),
      body: Column(
        children: [
          // 接続状態表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _chatService.isConnected ? Colors.green : Colors.red,
            child: Text(
              _chatService.isConnected ? '接続中' : '未接続',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          // メッセージリスト
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'メッセージがありません\nメッセージを送信してみてください',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    reverse: true, // 新しいメッセージが下に表示されるように
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            message.senderName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(message.content),
                          trailing: Text(
                            "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // メッセージ入力
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _handleSendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
