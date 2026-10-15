import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:latlong2/latlong.dart';

final _httpClient = RetryClient(Client());

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final int _showErrorBarDurationSeconds = 3;
  DateTime? _lastShownTileLoadError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          // crs: Epsg4326(),
          minZoom: 12,
        ),
        children: [
          TileLayer(
            userAgentPackageName: "com.zdybanka.app",
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            tileProvider: NetworkTileProvider(
              httpClient: _httpClient,
              cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
                maxCacheSize: 1_000_000_000
              )
            ),
            minZoom: 12,
            errorTileCallback: (tile, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if(_lastShownTileLoadError != null) {
                  return;
                }

                _lastShownTileLoadError = DateTime.now();

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  duration: Duration(seconds: _showErrorBarDurationSeconds),
                  content: Text(
                    "Failed to load map",
                    style: const TextStyle(color: Colors.black),
                  ),
                  backgroundColor: Colors.redAccent,
                ));
              });
            },
          ),
          MarkerLayer(

              markers: [
            Marker(point: LatLng(30, 40), child: Icon(Icons.control_point))
          ]),
          SimpleAttributionWidget(
            source: Text("OpenStreetMap contributors"),
          ),
        ],
      ),
    );
  }
}
