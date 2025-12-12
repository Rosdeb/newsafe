import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferader/views/screen/help_seaker/locations/map.dart';

class MapScreensssss extends StatefulWidget {
  @override
  State<MapScreensssss> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreensssss> {
  final mapController = Get.put(MapControllerAll());
  String mapTheme = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:const  Text("Live Tracking Map")),
      floatingActionButton: FloatingActionButton(
        child:const Icon(Icons.my_location, color: Colors.red),
        onPressed: () {
          if (mapController.currentLatLng != null) {
            mapController.animateCameraTo(mapController.currentLatLng!);
          }
        },
      ),
      body: Obx(() {
        // Show loading indicator while getting location
        if (!mapController.isLocationLoaded.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Getting your location..."),
              ],
            ),
          );
        }

        // Show map once location is loaded
        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: mapController.initialPosition.value ?? LatLng(23.8103, 90.4125),
            zoom: 15,
          ),
          onMapCreated: (controller) {
            mapController.setMapController(controller);
            controller.setMapStyle(mapTheme);
            mapController.startLiveLocation();
          },
          myLocationEnabled: true,
          markers: mapController.markers.toSet(),
          polylines: mapController.polylines.toSet(),
          circles: mapController.circles.toSet(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );
      }),
    );
  }
}