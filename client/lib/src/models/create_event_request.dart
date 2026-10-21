
class CreateEventRequest {
  final String name;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String address;
  final double latitude;
  final double longitude;
  final int maxParticipants;
  final List<String> tagIds;

  const CreateEventRequest({
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.maxParticipants,
    required this.tagIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'maxParticipants': maxParticipants,
      'tagIds': tagIds,
    };
  }
}
