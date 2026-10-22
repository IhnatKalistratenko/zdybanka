import 'package:client/src/widgets/primary_tile_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:geolocator/geolocator.dart';

class ChooseLocationPage extends StatefulWidget {
  const ChooseLocationPage({super.key});

  @override
  State<ChooseLocationPage> createState() => _ChooseLocationPageState();
}

class _ChooseLocationPageState extends State<ChooseLocationPage> {
  late final Future<LatLong> _locationFuture;

  @override
  void initState() {
    _locationFuture = _determinePosition();
    super.initState();
  }

  Future<LatLong> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
      return Future.error("Location services are disabled");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition();

    return LatLong(position.latitude, position.longitude);
  }

  void _chooseLocationCallback(PickedData pickedData)
  {
    Navigator.of(context).pop(pickedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Choose event location")),
        body: FutureBuilder(
          future: _locationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Failed to get location: ${snapshot.error}",
                ),
              );
            }

            final initialLocation = snapshot.data!;

            return FlutterLocationPicker.withConfiguration(
              userAgent: "com.zdybanka.app",
              initPosition: initialLocation,
              onPicked: (PickedData pickedData) {
                Navigator.of(context).pop(pickedData);
              },
            );
          },
        ),
    );
  }
}

