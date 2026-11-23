import 'message.dart';

class ChatView {
  final String id;
  final String name;
  final Message? lastMessage;

  const ChatView({
    required this.id,
    required this.name,
    this.lastMessage,
  });

  factory ChatView.fromJson(Map<String, dynamic> rawJson) {
    final id = rawJson['id'];
    final name = rawJson['name'];
    final rawLastMessage = rawJson['lastMessage'];

    if (id is! String || name is! String) {
      throw const FormatException('Failed to load chat.');
    }
    if (rawLastMessage != null && rawLastMessage is! Map) {
      throw const FormatException('Invalid last message response.');
    }

    return ChatView(
      id: id,
      name: name,
      lastMessage: rawLastMessage == null
          ? null
          : Message.fromJson(Map<String, dynamic>.from(rawLastMessage)),
    );
  }
}
