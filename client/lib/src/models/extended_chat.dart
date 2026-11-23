import 'message.dart';

class ExtendedChat {
  final String id;
  final String name;
  final String description;
  final List<Message> messages;

  const ExtendedChat({
    required this.id,
    required this.name,
    required this.description,
    required this.messages,
  });

  factory ExtendedChat.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final description = json['description'];
    final rawMessages = json['messages'];

    if (id is! String ||
        name is! String ||
        description is! String ||
        rawMessages is! List) {
      throw const FormatException('Failed to load chat.');
    }

    return ExtendedChat(
      id: id,
      name: name,
      description: description,
      messages: rawMessages.map((rawMessage) {
        if (rawMessage is! Map) {
          throw const FormatException('Invalid message response.');
        }
        return Message.fromJson(Map<String, dynamic>.from(rawMessage));
      }).toList(),
    );
  }
}
