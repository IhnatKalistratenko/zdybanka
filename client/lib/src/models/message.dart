class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  bool isOwner;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.isOwner = false,
  });

  factory Message.fromJson(Map<String, dynamic> rawJson) {
    final id = rawJson['id'];
    final chatId = rawJson['chatId'];
    final senderId = rawJson['senderId'];
    final senderName = rawJson['senderName'];
    final content = rawJson['content'];
    final sentAtValue = rawJson['sentAt'];
    final sentAt = sentAtValue is String ? DateTime.tryParse(sentAtValue) : null;
    final isOwner = rawJson['isOwner'];

    if (id is! String ||
        chatId is! String ||
        senderId is! String ||
        senderName is! String ||
        content is! String ||
        sentAt == null ||
        (isOwner != null && isOwner is! bool)) {
      throw const FormatException('Failed to load message.');
    }

    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      sentAt: sentAt,
      isOwner: isOwner as bool? ?? false,
    );
  }
}
