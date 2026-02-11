import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferader/views/screen/help_seaker/locations/map.dart';

import '../../../../controller/SeakerLocation/seakerLocationsController.dart';

class MapScreensssss extends StatefulWidget {
  @override
  State<MapScreensssss> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreensssss> {
  final mapController = Get.put(MapControllerAll());
  final SeakerLocationsController controller = Get.find();
  String mapTheme = "";

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Tracking Map")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location, color: Colors.red),
        onPressed: () {
          // Check currentLatLng specifically since that is what you are passing
          if (mapController.currentLatLng != null) {
            print("Moving camera to: ${mapController.currentLatLng}");
            mapController.animateCameraTo(mapController.currentLatLng!);
          } else {
            print("Location data not ready yet");
          }
        },
      ),
      body: Obx(() {
        // 1. Safety Check: If location isn't loaded yet, show a spinner
        if (!mapController.isLocationLoaded.value || mapController.currentPosition.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final pos = mapController.currentPosition.value!;

        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 15,
          ),
          onMapCreated: (googleMapController) {
            mapController.setMapController(googleMapController);
            // 2. This starts the stream that calls animateCameraTo() automatically
            mapController.startLiveLocation();
          },
          myLocationEnabled: true,
          // The .toSet() inside Obx ensures markers move on screen in real-time
          //markers: mapController.markers.toSet(),
          polylines: mapController.polylines.toSet(),
          circles: mapController.circles.toSet(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );
      }),
    );
  }

}