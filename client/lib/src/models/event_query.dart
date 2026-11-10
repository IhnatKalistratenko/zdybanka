class EventQuery {
  final String? status;
  final String? creatorId;
  final DateTime? startFrom;
  final DateTime? endTo;
  final double? userLongitude;
  final double? userLatitude;
  final double radiusMeters;
  final int? page;
  final int? pageSize;
  final Set<String> tags;
  final String? orderMethod;
  final String? userStatus;

  const EventQuery({
    this.status,
    this.creatorId,
    this.startFrom,
    this.endTo,
    this.userLongitude,
    this.userLatitude,
    this.userStatus,
    required this.orderMethod,
    this.tags = const {},
    this.radiusMeters = 0,
    this.page = 0,
    this.pageSize = 0,
  });
}
