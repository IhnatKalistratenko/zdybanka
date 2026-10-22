import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class PrimaryTileLayer extends StatefulWidget {
  const PrimaryTileLayer({super.key});

  @override
  State<PrimaryTileLayer> createState() => _PrimaryTileLayerState();
}

class _PrimaryTileLayerState extends State<PrimaryTileLayer> {
  final int _showErrorBarDurationSeconds = 3;
  DateTime? _lastShownTileLoadError;
  @override
  Widget build(BuildContext context) {
    return TileLayer(
      userAgentPackageName: "com.zdybanka.app",
      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
      tileProvider: NetworkTileProvider(
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
    );
  }
}
