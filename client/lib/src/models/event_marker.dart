class EventMarker {
  final String id;
  final double longitude;
  final double latitude;
  final String userStatus;

  EventMarker({
    required this.id,
    required this.longitude,
    required this.latitude,
    this.userStatus = 'available',
  });

  factory EventMarker.fromJson(Map<String, dynamic> json) {
    final id = json["id"];
    final longitude = json["longitude"];
    final latitude = json["latitude"];
    final userStatus = json["userStatus"];

    if (id is! String || longitude is! num || latitude is! num || userStatus is! String) {
      throw const FormatException('Failed to load marker');
    }

    return EventMarker(
      id: id,
      longitude: longitude.toDouble(),
      latitude: latitude.toDouble(),
      userStatus: userStatus,
    );
  }

}
