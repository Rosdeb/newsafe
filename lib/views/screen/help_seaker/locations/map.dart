import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapControllerAll extends GetxController {
  GoogleMapController? _mapController;

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;

  LatLng? currentLatLng;
  Stream<Position>? _positionStream;
  LatLng? lastUpdatedLatLng;
  RxString currentAddress = "Getting location...".obs;
  RxString currentAreaName = "".obs;

  // Observable for initial position
  Rx<LatLng?> initialPosition = Rx<LatLng?>(null);
  RxBool isLocationLoaded = false.obs;

  BitmapDescriptor? carIcon;
  BitmapDescriptor? userIcon;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation(); // Get location on init
  }

  // Get current location for initial camera position
  Future<void> getCurrentLocation() async {
    try {
      var permission = await Permission.location.request();
      if (!permission.isGranted) {
        // Set default location if permission denied
        initialPosition.value = LatLng(23.8103, 90.4125);
        isLocationLoaded.value = true;
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentPos = LatLng(position.latitude, position.longitude);
      initialPosition.value = currentPos;
      currentLatLng = currentPos;

      // Create initial marker
      updateUserMarker(currentPos, position.accuracy);

      isLocationLoaded.value = true;

      // Get address for current location
      await getAddressFromLatLng(currentPos);

      print("📍 Initial Location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("❌ Error getting current location: $e");
      // Fallback to default location
      initialPosition.value = LatLng(23.8103, 90.4125);
      isLocationLoaded.value = true;
    }
  }

  Future<void> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        currentAddress.value =
        "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";

        currentAreaName.value = place.locality ?? place.subLocality ?? "Unknown";

        print("📍 Address: ${currentAddress.value}");
      }
    } catch (e) {
      print("❌ Error getting address: $e");
      currentAddress.value = "Unable to get address";
      currentAreaName.value = "Unknown location";
    }
  }

  setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> startLiveLocation() async {
    var permission = await Permission.location.request();
    if (!permission.isGranted) return;

    LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings);

    _positionStream!.listen((Position position) {
      LatLng liveLatLng = LatLng(position.latitude, position.longitude);

      if (lastUpdatedLatLng != null) {
        double distance = Geolocator.distanceBetween(
          lastUpdatedLatLng!.latitude,
          lastUpdatedLatLng!.longitude,
          liveLatLng.latitude,
          liveLatLng.longitude,
        );

        if (distance < 10) {
          return;
        }
      }

      lastUpdatedLatLng = liveLatLng;
      currentLatLng = liveLatLng;
      updateUserMarker(liveLatLng, position.accuracy);
      animateCameraTo(liveLatLng);

      markers.refresh();
      circles.refresh();
      polylines.refresh();
    });
  }

  void updateUserMarker(LatLng pos, double accuracy) {
    markers.removeWhere((m) => m.markerId.value == "user_marker");

    markers.add(
      Marker(
        markerId: MarkerId("user_marker"),
        icon: BitmapDescriptor.defaultMarkerWithHue(240), // Blue color
        position: pos,
      ),
    );

    circles.removeWhere((c) => c.circleId.value == "user_circle");

    circles.add(
      Circle(
        circleId: CircleId("user_circle"),
        center: pos,
        radius: accuracy,
        fillColor: Colors.blue.withOpacity(0.15),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      ),
    );
  }

  void animateCameraTo(LatLng latLng, {double zoom = 14}) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }
}