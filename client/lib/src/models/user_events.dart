import 'event.dart';

class UserEvents {
  final List<Event> userEvents;
  final List<Event> joinedEvents;
  final List<Event> pastEvents;

  const UserEvents({
    required this.userEvents,
    required this.joinedEvents,
    required this.pastEvents,
  });

  factory UserEvents.fromJson(Map<String, dynamic> json) {
    return UserEvents(
      userEvents: _parseEvents(json['userEvents']),
      joinedEvents: _parseEvents(json['joinedEvents']),
      pastEvents: _parseEvents(json['pastEvents']),
    );
  }

  static List<Event> _parseEvents(dynamic value) {
    if (value is! List) {
      throw const FormatException('Invalid user events response.');
    }
    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid event response.');
      }
      return Event.fromJson(item);
    }).toList();
  }
}
