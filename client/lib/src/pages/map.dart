import 'dart:async';

import 'package:client/src/models/event_boundary_request.dart';
import 'package:client/src/services/event_service.dart';
import 'package:client/src/tools.dart';
import 'package:client/src/widgets/event_details_widget.dart';
import 'package:client/src/widgets/primary_tile_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

import '../models/event_marker.dart';

final _httpClient = RetryClient(Client());

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final EventService _eventService = EventService();

  late AlignOnUpdate _alignOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;
  final MapController _mapController = MapController();
  late Future<LatLong> futureUserPosition;

  Timer? _debounceTimer;

  LatLng? _lastRequestedCenter;
  double? _lastRequestedZoom;

  Future<List<EventMarker>> futureMarkers =
  Future.value([]);

  @override
  void initState() {
    super.initState();
    _alignOnUpdate = AlignOnUpdate.always;
    _alignPositionStreamController = StreamController<double?>();
    futureUserPosition = determinePosition();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _debounceTimer?.cancel();
    _alignPositionStreamController.close();
    super.dispose();
  }

  void _turnOffCameraFix(bool hasGesture) {
    if(hasGesture && _alignOnUpdate != AlignOnUpdate.never) {
      setState(() {
        _alignOnUpdate = AlignOnUpdate.never;
      });
    }
  }

  bool _shouldFetchEvents(MapCamera camera) {
    if (_lastRequestedCenter == null || _lastRequestedZoom == null) {
      return true;
    }

    final bounds = camera.visibleBounds;

    final thresholdLat = (bounds.north - bounds.south) * 0.25;
    final thresholdLng = (bounds.east - bounds.west) * 0.25;

    final currentCenter = camera.center;
    final previousCenter = _lastRequestedCenter!;

    final centerChanged =
        (currentCenter.latitude - previousCenter.latitude).abs() >= thresholdLat ||
            (currentCenter.longitude - previousCenter.longitude).abs() >= thresholdLng;

    final zoomChanged = (camera.zoom - _lastRequestedZoom!).abs() >= 0.5;

    return centerChanged || zoomChanged;
  }

  void _scheduleFetch(MapCamera camera) {
    if (!_shouldFetchEvents(camera)) return;

    _debounceTimer?.cancel();

    _debounceTimer = Timer(
      const Duration(milliseconds: 400),
          () {
        if (!mounted) return;

        final currentCamera = _mapController.camera;

        _lastRequestedCenter = currentCamera.center;
        _lastRequestedZoom = currentCamera.zoom;

        fetchMarkers(currentCamera.visibleBounds);
      },
    );
  }

  void fetchMarkers(LatLngBounds bounds) {
    final topLeft = bounds.northWest;
    final bottomRight = bounds.southEast;

    final params = EventBoundaryRequest(
      topLeftCornerLatitude: topLeft.latitude,
      topLeftCornerLongitude: topLeft.longitude,
      bottomRightCornerLatitude: bottomRight.latitude,
      bottomRightCornerLongitude: bottomRight.longitude,
    );

    setState(() {
      futureMarkers = _eventService.getEventsPosition(params);
    });
  }

  void _refreshVisibleMarkers() {
    if (!mounted) return;
    fetchMarkers(_mapController.camera.visibleBounds);
  }

  void _handleMarkerClick(EventMarker event) async {
    switch(event.userStatus) {
      case "Created":
      await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => OwnedEventDetailsWidget(
      eventId: event.id,
      onDeleteCallback: _refreshVisibleMarkers,
    ),);
        return;
      case "Available":
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => JoinableEventDetailsWidget(
            eventId: event.id,
            onJoinCallback: _refreshVisibleMarkers,
          ),);
        return;
      case "Joined":
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => JoinedEventDetailsWidget(
            eventId: event.id,
            onLeaveCallback: _refreshVisibleMarkers,
          ),);
        return;
        default:
          return;
    }
  }

  MaterialColor _getMarkerColor(String userStatus)
  {
    if(userStatus == "Created") {
        return Colors.amber;
    }
    if(userStatus == "Joined") {
      return Colors.blue;
    }
    if(userStatus == "Past") {
      return Colors.grey;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
          future: futureUserPosition,
          builder: (context, snapshot) {
            if(snapshot.hasError) {
                return Text("${snapshot.error}");
            } else if(snapshot.hasData) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: snapshot.data != null ? LatLng(snapshot.data!.latitude, snapshot.data!.longitude) : LatLng(0, 0),
                  initialZoom: 16,
                  minZoom: 12,
                  onMapReady: () {
                    _scheduleFetch(_mapController.camera);
                  },
                  onPositionChanged: (MapCamera camera, bool hasGesture) {
                    _turnOffCameraFix(hasGesture);
                    _scheduleFetch(camera);
                  }
                ),
                children: [
                  PrimaryTileLayer(),
                  CurrentLocationLayer(
                    alignPositionOnUpdate: _alignOnUpdate,
                    alignPositionStream: _alignPositionStreamController.stream,
                  ),
                  Align(
                    alignment: Alignment(0.9, 0.9),
                    child: FloatingActionButton(onPressed: () {
                      setState(() {
                        _alignOnUpdate = AlignOnUpdate.always;
                      });
                      _alignPositionStreamController.add(16);
                    },
                      child: Icon(Icons.my_location, color: Colors.blueAccent,),
                    ),
                  ),
                  FutureBuilder(future: futureMarkers,
                      builder: (context, snapshot) {
                        if(snapshot.hasData && snapshot.data != null)
                          {
                            return MarkerLayer(
                                markers: snapshot.data!.map<Marker>((e) =>
                                    Marker(
                                        point: LatLng(e.latitude, e.longitude),
                                        child: GestureDetector(
                                          onTap: () => _handleMarkerClick(e),
                                          child: Icon(Icons.location_on, color: _getMarkerColor(e.userStatus), size: 27,),
                                        )
                                    )
                                ).toList(),
                            );
                          }
                        return MarkerLayer(markers: []);
                      }),
                  SimpleAttributionWidget(
                    source: Text("OpenStreetMap contributors"),
                  ),
                ],
              );
            }
            return CircularProgressIndicator();
          })
    );
  }


}
