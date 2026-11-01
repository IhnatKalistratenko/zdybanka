class EventTag {
  final String id;
  final String name;

  const EventTag({
    required this.id,
    required this.name,
  });

  factory EventTag.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];

    if (id is String && name is String) {
      return EventTag(id: id, name: name);
    }

    throw const FormatException('Invalid tag response.');
  }
}
