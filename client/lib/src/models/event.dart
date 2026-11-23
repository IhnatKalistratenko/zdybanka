import 'event_tag.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String address;
  final String status;
  final String creatorId;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final int participantsCount;
  final List<EventTag> tags;
  final double distanceKm;
  final double? latitude;
  final double? longitude;
  final String userStatus;

  const Event({
    required this.status,
    required this.creatorId,
    required this.createdAt,
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    this.participantsCount = 0,
    required this.tags,
    required this.distanceKm,
    this.latitude,
    this.longitude,
    this.userStatus = 'available',
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final status = json['status'];
    final creatorId = json['creatorId'];
    final createdAt = _parseDateTime(json['createdAt']);
    final startTime = _parseDateTime(json['startTime']);
    final endTime = _parseDateTime(json['endTime']);
    final maxParticipants = json['maxParticipants'];
    final description = json['description'];
    final address = json['address'];
    final userStatus = json['userStatus'];

    if (id is! String ||
        name is! String ||
        status is! String ||
        creatorId is! String ||
        createdAt == null ||
        startTime == null ||
        endTime == null ||
        maxParticipants is! int ||
        (description != null && description is! String) ||
        (address != null && address is! String) ||
        userStatus is! String) {
      throw const FormatException('Failed to load event');
    }

    final rawTags = json['tags'];
    final tags = rawTags == null
        ? <EventTag>[]
        : rawTags is List
        ? rawTags.map((tag) {
            if (tag is! Map) {
              throw const FormatException('Invalid event tag response.');
            }
            return EventTag.fromJson(Map<String, dynamic>.from(tag));
          }).toList()
        : throw const FormatException('Invalid event tags response.');
    final rawDistanceToUser = json['distanceToUser'];
    final distanceKm = rawDistanceToUser is num
        ? rawDistanceToUser.toDouble() / 1000
        : 0.0;

    return Event(
      id: id,
      name: name,
      description: description as String? ?? '',
      address: address as String? ?? '',
      status: status,
      creatorId: creatorId,
      createdAt: createdAt,
      startTime: startTime,
      endTime: endTime,
      maxParticipants: maxParticipants,
      participantsCount: (json['participantsCount'] as num?)?.toInt() ?? 0,
      tags: tags,
      distanceKm: distanceKm,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      userStatus: userStatus,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

}
