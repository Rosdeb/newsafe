import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../controller/SeakerLocation/seakerLocationsController.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final SeakerLocationsController locationsController = Get.find();
  GoogleMapController? mapController;

  final RxSet<Marker> markers = <Marker>{}.obs;
  AnimationController? _animationController;
  Animation<double>? _animation;
  LatLng? _oldLatLng;
  LatLng? _newLatLng;
  double currentBearing = 0;

  LatLng? _lastAnimatedPosition;
  // ✅ Match with controller's filter (10m)
  static const double _minDistanceForAnimation = 10.0;

  final RxSet<Circle> circles = <Circle>{}.obs;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    // Start live location if not already running
    if (!locationsController.liveLocation.value) {
      await locationsController.startLiveLocation();
    }

    // Set initial marker
    final pos = locationsController.currentPosition.value;
    if (pos != null) {
      final initialPos = LatLng(pos.latitude, pos.longitude);
      _oldLatLng = initialPos;
      _lastAnimatedPosition = initialPos;
      _updateMarkerAndCircle(initialPos, pos.accuracy);

      // Center camera on initial position
      await Future.delayed(const Duration(milliseconds: 400));
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: initialPos, zoom: 18),
        ),
      );
    }

    // Listen to location updates
    _listenToLocationUpdates();
  }

  void _listenToLocationUpdates() {
    ever(locationsController.currentPosition, (position) {
      if (position != null) {
        _handleLocationUpdate(
          LatLng(position.latitude, position.longitude),
          position.accuracy,
        );
      }
    });
  }

  void _handleLocationUpdate(LatLng newLatLng, double accuracy) {
    print("📍 Location update received: ${newLatLng.latitude}, ${newLatLng.longitude}");
    print("📊 Accuracy: ${accuracy.toStringAsFixed(1)}m");

    // ✅ RELAXED FILTER: Only block very poor accuracy
    if (accuracy > 50) {
      print("⚠️ Very poor accuracy (${accuracy.toStringAsFixed(1)}m) - ignoring");
      return;
    }

    // Check distance from last animated position
    if (_lastAnimatedPosition != null) {
      final distance = _calculateDistance(_lastAnimatedPosition!, newLatLng);
      print("📏 Distance: ${distance.toStringAsFixed(2)}m");

      // ✅ SIMPLE CHECK: Just use minimum distance
      if (distance < _minDistanceForAnimation) {
        print("⏭️ Skipping - distance < ${_minDistanceForAnimation}m");
        // Still update camera smoothly
        mapController?.animateCamera(
          CameraUpdate.newLatLng(newLatLng),
        );
        return;
      }

      print("✅ Animating marker (distance: ${distance.toStringAsFixed(1)}m)");
    }

    // Update camera
    mapController?.animateCamera(
      CameraUpdate.newLatLng(newLatLng),
    );

    // Handle first update
    if (_oldLatLng == null) {
      print("🎯 First position set");
      _oldLatLng = newLatLng;
      _lastAnimatedPosition = newLatLng;
      _updateMarkerAndCircle(newLatLng, accuracy);
      return;
    }

    // Animate marker
    _animateMarker(newLatLng, accuracy);
  }

  void _animateMarker(LatLng newLatLng, double accuracy) {
    _newLatLng = newLatLng;

    // Calculate bearing
    currentBearing = _calculateBearing(
      _oldLatLng!.latitude,
      _oldLatLng!.longitude,
      newLatLng.latitude,
      newLatLng.longitude,
    );

    print("🧭 Bearing: ${currentBearing.toStringAsFixed(1)}°");

    // Cancel ongoing animation
    _animationController?.dispose();

    // Create animation (500ms for smooth movement)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _animationController!.addListener(() {
      final pos = _interpolateLatLng(_oldLatLng!, _newLatLng!, _animation!.value);
      _updateMarkerAndCircle(pos, accuracy, rotation: currentBearing);
    });

    _animationController!.forward().then((_) {
      _oldLatLng = _newLatLng;
      _lastAnimatedPosition = _newLatLng;
      print("✅ Animation completed");
    });
  }

  void _updateMarkerAndCircle(LatLng position, double accuracy, {double rotation = 0}) {
    markers.assignAll({
      Marker(
        markerId: const MarkerId("user_marker"),
        position: position,
        rotation: rotation,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    });

    circles.assignAll({
      Circle(
        circleId: const CircleId("accuracy_circle"),
        center: position,
        radius: accuracy,
        fillColor: Colors.blue.withOpacity(0.15),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      ),
    });

    markers.refresh();
    circles.refresh();
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000;

    final latDiff = (to.latitude - from.latitude) * pi / 180;
    final lngDiff = (to.longitude - from.longitude) * pi / 180;

    final a = sin(latDiff / 2) * sin(latDiff / 2) +
        cos(from.latitude * pi / 180) *
            cos(to.latitude * pi / 180) *
            sin(lngDiff / 2) *
            sin(lngDiff / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    double dLon = (endLng - startLng) * pi / 180;
    double y = sin(dLon) * cos(endLat * pi / 180);
    double x = cos(startLat * pi / 180) * sin(endLat * pi / 180) -
        sin(startLat * pi / 180) * cos(endLat * pi / 180) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  LatLng _interpolateLatLng(LatLng start, LatLng end, double t) {
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * t,
      start.longitude + (end.longitude - start.longitude) * t,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Tracking Map".tr),
        actions: [
          Obx(() {
            if (locationsController.isSharingLocation.value) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  locationsController.isSocketConnected.value
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: locationsController.isSocketConnected.value
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: () {
          final pos = locationsController.currentPosition.value;
          if (pos != null) {
            mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(pos.latitude, pos.longitude),
                  zoom: 17,
                ),
              ),
            );
          }
        },
      ),
      body: Obx(() {
        final pos = locationsController.currentPosition.value;

        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              pos?.latitude ?? 23.8103,
              pos?.longitude ?? 90.4125,
            ),
            zoom: 16,
          ),
          onMapCreated: (controller) {
            mapController = controller;
          },
          myLocationEnabled: true,
          markers: markers.value,
          circles: circles.value,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
        );
      }),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    mapController?.dispose();
    super.dispose();
  }
}