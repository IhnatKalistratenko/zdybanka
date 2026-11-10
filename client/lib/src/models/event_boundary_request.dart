class EventBoundaryRequest {
  double topLeftCornerLongitude;
  double topLeftCornerLatitude;
  double bottomRightCornerLongitude;
  double bottomRightCornerLatitude;

  EventBoundaryRequest({required this.topLeftCornerLatitude, required this.topLeftCornerLongitude, required this.bottomRightCornerLatitude, required this.bottomRightCornerLongitude});
}