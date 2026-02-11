import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saferader/utils/logger.dart';

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
  RxBool isLocationLoaded = false.obs;
  Rx<Position?> currentPosition = Rx<Position?>(null);
  String get latString => currentPosition.value?.latitude.toString() ?? "";
  String get lngString => currentPosition.value?.longitude.toString() ?? "";
  BitmapDescriptor? carIcon;
  BitmapDescriptor? userIcon;

  @override
  void onInit() {
    super.onInit();
    getUserLocationOnce();
  }

  Future<bool> handlePermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Logger.log("📍 Location services disabled", type: "warning");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Logger.log("📍 Location permission denied", type: "warning");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Logger.log("📍 Location permission permanently denied", type: "error");
      return false;
    }

    return true;
  }

  Future<void> getUserLocationOnce() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return;

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = pos;
      currentLatLng = LatLng(pos.latitude, pos.longitude);
      updateUserMarker(currentLatLng!, pos.accuracy);
      isLocationLoaded.value = true;
      Logger.log("📍 One-time location: Lat ${pos.latitude}, Lng ${pos.longitude}", type: "info",);
    } catch (e) {
      Logger.log("❌ Error getting location: $e", type: "error");
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

        currentAreaName.value =
            place.locality ?? place.subLocality ?? "Unknown";

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

  // Future<void> startLiveLocation() async {
  //   var permission = await Permission.location.request();
  //   if (!permission.isGranted) return;
  //
  //   LocationSettings settings = LocationSettings(
  //     accuracy: LocationAccuracy.high,
  //     distanceFilter: 5,
  //   );
  //
  //   _positionStream = Geolocator.getPositionStream(locationSettings: settings);
  //
  //   _positionStream!.listen((Position position) {
  //     LatLng liveLatLng = LatLng(position.latitude, position.longitude);
  //
  //     if (lastUpdatedLatLng != null) {
  //       double distance = Geolocator.distanceBetween(
  //         lastUpdatedLatLng!.latitude,
  //         lastUpdatedLatLng!.longitude,
  //         liveLatLng.latitude,
  //         liveLatLng.longitude,
  //       );
  //
  //       if (distance < 10) {
  //         return;
  //       }
  //     }
  //
  //     lastUpdatedLatLng = liveLatLng;
  //     currentLatLng = liveLatLng;
  //     updateUserMarker(liveLatLng, position.accuracy);
  //     animateCameraTo(liveLatLng);
  //
  //     markers.refresh();
  //     circles.refresh();
  //     polylines.refresh();
  //   });
  // }

  Future<void> startLiveLocation() async {
    var permission = await Permission.location.request();
    if (!permission.isGranted) return;

    LocationSettings settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Reduced to 2 meters for smoother tracking
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings);

    _positionStream!.listen((Position position) {
      LatLng liveLatLng = LatLng(position.latitude, position.longitude);

      // Update the variables
      currentLatLng = liveLatLng;
      currentPosition.value = position;

      // 1. Update the marker position on the map
      updateUserMarker(liveLatLng, position.accuracy);

      // 2. 🔥 AUTO-MOVE: This line makes the map follow the user automatically
      animateCameraTo(liveLatLng);

      // Refresh UI sets
      markers.refresh();
      circles.refresh();
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

  void animateCameraTo(LatLng latLng, {double zoom = 18}) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            zoom: zoom,
          ),
        ),
      );
    }
  }

}
