class Event {
  final String id;
  final String name;
  final String description;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final int participantsCount;
  final List<String> tags;
  final double distanceKm;

  const Event({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.participantsCount,
    required this.tags,
    required this.distanceKm,
  });
}