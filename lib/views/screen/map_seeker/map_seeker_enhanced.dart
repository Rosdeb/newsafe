// // 🔥 ENHANCED VERSION WITH:
// // 1. Proper marker movement with location updates
// // 2. Socket disconnection handling
// // 3. Visual connection status indicators
// // 4. Location sharing status display
// // 5. AppLifecycle handling for socket reconnection
//
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
// import 'package:get/get.dart';
// import 'package:saferader/utils/app_constant.dart';
// import 'package:saferader/utils/logger.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import '../../../controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
// import '../../../controller/SeakerHome/seakerHomeController.dart';
//
// class UniversalMapViewEnhanced extends StatefulWidget {
//   const UniversalMapViewEnhanced({Key? key}) : super(key: key);
//
//   @override
//   _UniversalMapViewEnhancedState createState() => _UniversalMapViewEnhancedState();
// }
//
// class _UniversalMapViewEnhancedState extends State<UniversalMapViewEnhanced> with WidgetsBindingObserver {
//
//   GoogleMapController? mapController;
//   final locationsController = Get.find<SeakerLocationsController>();
//
//   SeakerHomeController? _seekerController;
//   GiverHomeController? _giverController;
//
//   Set<Marker> _markers = {};
//   List<LatLng> _polyPoints = [];
//   bool _isLoadingRoute = false;
//
//   ValueNotifier<LatLng?> _otherPersonLocation = ValueNotifier(null);
//   ValueNotifier<LatLng?> _myLocation = ValueNotifier(null);
//
//   LatLng? _previousOtherLocation;
//
//   final PolylinePoints polylinePoints = PolylinePoints(apiKey: AppConstants.Secret_key);
//   DateTime? _lastPolylineUpdate;
//   static const Duration _polylineUpdateInterval = Duration(seconds: 15);
//
//   String _currentMode = 'none';
//
//   // 🔥 NEW: Connection status tracking
//   RxBool isSocketConnected = false.obs;
//   RxBool isLocationSharing = false.obs;
//   Timer? _connectionMonitor;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//
//     // Add the lifecycle observer
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     // Remove the lifecycle observer
//     WidgetsBinding.instance.removeObserver(this);
//
//     _connectionMonitor?.cancel();
//     _otherPersonLocation.dispose();
//     _myLocation.dispose();
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     switch (state) {
//       case AppLifecycleState.resumed:
//       // App is back in foreground, refresh socket connection
//         _handleAppResume();
//         break;
//       case AppLifecycleState.paused:
//       // App is in background, keep socket alive
//         _handleAppPause();
//         break;
//       case AppLifecycleState.inactive:
//       // App is inactive
//         break;
//       case AppLifecycleState.detached:
//       // App is detached
//         break;
//       case AppLifecycleState.hidden:
//       // App is hidden (iOS specific)
//         break;
//     }
//   }
//
//   void _handleAppResume() {
//     Logger.log("📱 App resumed - refreshing socket connection", type: "info");
//
//     // Refresh socket connection and rejoin room if needed
//     if (mounted) {
//       _refreshSocketConnection();
//     }
//   }
//
//   void _handleAppPause() {
//     Logger.log("📱 App paused - keeping socket connection alive", type: "info");
//   }
//
//   Future<void> _refreshSocketConnection() async {
//     try {
//       // Refresh the socket connection
//       await locationsController.refreshAfterMapReturn();
//
//       // Update connection status
//       final socketService = locationsController.getActiveSocket();
//       if (socketService != null) {
//         isSocketConnected.value = socketService.isConnected.value;
//       }
//
//       Logger.log("🔄 Socket connection refreshed after app resume", type: "success");
//     } catch (e) {
//       Logger.log("❌ Error refreshing socket connection: $e", type: "error");
//     }
//   }
//
//   void _initializeApp() {
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _initializeControllers();
//       _setupListeners();
//       _initializeMap();
//     });
//   }
//
//   void _initializeMap() {
//     final pos = locationsController.currentPosition.value;
//     if (pos != null) {
//       _myLocation.value = LatLng(pos.latitude, pos.longitude);
//       _updateMarkers();
//     }
//
//     if (pos != null) {
//       if (_hasActiveRequest()) {
//         _updateOtherPersonLocation();
//         _startLocationSharingIfNeeded();
//       }
//     }
//   }
//
//   // void _startLocationSharingIfNeeded() {
//   //   if (!locationsController.isSharingLocation.value) {
//   //     Logger.log("📍 Auto-starting location sharing...", type: "info");
//   //
//   //     String requestId = locationsController.currentHelpRequestId.value;
//   //
//   //     if (requestId.isEmpty) {
//   //       if (_currentMode == 'seeker' && _seekerController != null) {
//   //         requestId = _seekerController!.currentHelpRequestId.value;
//   //       } else if (_currentMode == 'giver' && _giverController != null) {
//   //         final request = _giverController!.acceptedHelpRequest.value;
//   //         requestId = request?['_id']?.toString() ?? '';
//   //       }
//   //     }
//   //
//   //     if (requestId.isNotEmpty) {
//   //       locationsController.setHelpRequestId(requestId);
//   //
//   //       // 🔥 1. প্রথমে ফ্ল্যাগ রিসেট করুন
//   //       locationsController.resetFirstLocationFlag();
//   //
//   //       // 🔥 2. আগে startLocationSharing() কল করুন
//   //       locationsController.startLocationSharing();
//   //
//   //       // 🔥 3. পরে startLiveLocation() কল করুন
//   //       locationsController.startLiveLocation();
//   //     } else {
//   //       Logger.log("⚠️ Cannot auto-start: No valid help request ID", type: "warning");
//   //     }
//   //   }
//   // }
//
//   void _startLocationSharingIfNeeded() {
//     if (_hasActiveRequest()) {
//       String requestId = locationsController.currentHelpRequestId.value;
//
//       if (requestId.isEmpty) {
//         if (_currentMode == 'seeker' && _seekerController != null) {
//           requestId = _seekerController!.currentHelpRequestId.value;
//         } else if (_currentMode == 'giver' && _giverController != null) {
//           final request = _giverController!.acceptedHelpRequest.value;
//           requestId = request?['_id']?.toString() ?? '';
//         }
//       }
//
//       if (requestId.isNotEmpty) {
//         locationsController.setHelpRequestId(requestId);
//
//         // 🔥 শুধুমাত্র যদি location sharing শুরু না হয়ে থাকে
//         if (!locationsController.isSharingLocation.value) {
//           locationsController.startLocationSharing();
//         }
//
//         // 🔥 শুধুমাত্র যদি live location চলছে না
//         if (!locationsController.liveLocation.value) {
//           Logger.log("📍 [MAP] Starting live location stream (map opened)...", type: "info");
//           locationsController.resetFirstLocationFlag();
//           locationsController.startLiveLocation();
//         }
//       }
//     }
//   }
//
//
//   void _openExternalMapsNavigation() async {
//     final myLoc = _myLocation.value;
//     final otherLoc = _otherPersonLocation.value;
//
//     if (myLoc == null || otherLoc == null) {
//       Get.snackbar("Navigation", "Location data not available", snackPosition: SnackPosition.BOTTOM);
//       return;
//     }
//
//     try {
//       // Store the current state before navigating away
//       Logger.log("📱 Preparing to navigate to external maps", type: "info");
//       Logger.log("📍 My location: (${myLoc.latitude}, ${myLoc.longitude})", type: "info");
//       Logger.log("📍 Other person location: (${otherLoc.latitude}, ${otherLoc.longitude})", type: "info");
//
//       if (Platform.isIOS) {
//         await _openAppleMaps(
//           myLoc.latitude,
//           myLoc.longitude,
//           otherLoc.latitude,
//           otherLoc.longitude,
//         );
//       } else if (Platform.isAndroid) {
//         await _openGoogleMapsNavigation(
//           myLoc.latitude,
//           myLoc.longitude,
//           otherLoc.latitude,
//           otherLoc.longitude,
//         );
//       }
//     }on Exception catch (e) {
//       Get.snackbar("Navigation Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
//     }
//   }
//
//   Future<void> _openGoogleMapsNavigation(double startLat, double startLng, double endLat, double endLng) async {
//     // Using the Google Maps URL scheme that automatically starts navigation
//     final url = Uri.parse(
//       'google.navigation:q=$endLat,$endLng&from=$startLat,$startLng',
//     );
//
//     // Fallback URL for web version
//     final webUrl = Uri.parse(
//       'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving',
//     );
//
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url);
//     } else if (await canLaunchUrl(webUrl)) {
//       await launchUrl(webUrl);
//     } else {
//       throw 'Could not launch Google Maps';
//     }
//   }
//
//   Future<void> _openAppleMaps(double startLat, double startLng, double endLat, double endLng) async {
//     final url = Uri.parse(
//       'http://maps.apple.com/?saddr=$startLat,$startLng&daddr=$endLat,$endLng&dirflg=d',
//     );
//
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url);
//     } else {
//       throw 'Could not launch Apple Maps';
//     }
//   }
//
//   Future<void> _initializeControllers() async {
//     try {
//       if (Get.isRegistered<SeakerHomeController>()) {
//         _seekerController = Get.find<SeakerHomeController>();
//       }
//
//       if (Get.isRegistered<GiverHomeController>()) {
//         _giverController = Get.find<GiverHomeController>();
//       }
//
//       _updateCurrentMode();
//     } on Exception catch (e) {
//       Logger.log("❌ Error initializing controllers: $e", type: "error");
//     }
//   }
//
//   void _updateCurrentMode() {
//     if (_isSeekerMode()) {
//       _currentMode = 'seeker';
//     } else if (_isGiverMode()) {
//       _currentMode = 'giver';
//     } else {
//       _currentMode = 'none';
//     }
//     Logger.log("📱 Current mode: $_currentMode", type: "info");
//   }
//
//   bool _isSeekerMode() {
//     if (Get.isRegistered<SeakerHomeController>()) {
//       final controller = Get.find<SeakerHomeController>();
//       // Unified role: seeker mode = not currently available as helper
//       return !controller.helperStatus.value;
//     }
//     return false;
//   }
//
//   bool _isGiverMode() {
//     if (Get.isRegistered<GiverHomeController>()) {
//       return Get.find<GiverHomeController>().emergencyMode.value == 2;
//     }
//     return false;
//   }
//
//   bool _hasActiveRequest() {
//     // ✅ Check SeakerHomeController FIRST for active request
//     if (Get.isRegistered<SeakerHomeController>()) {
//       final seekerCtrl = Get.find<SeakerHomeController>();
//       if (seekerCtrl.hasActiveHelpRequest) {
//         _currentMode = 'seeker';
//         _seekerController = seekerCtrl;
//         return true;
//       }
//     }
//
//     // ✅ Then check GiverHomeController
//     if (Get.isRegistered<GiverHomeController>()) {
//       final giverCtrl = Get.find<GiverHomeController>();
//       if (giverCtrl.acceptedHelpRequest.value != null) {
//         _currentMode = 'giver';
//         _giverController = giverCtrl;
//         return true;
//       }
//     }
//
//     return false;
//   }
//
//   // bool _hasActiveRequest() {
//   //   if (_currentMode == 'seeker' && _seekerController != null) {
//   //     return _seekerController!.hasActiveHelpRequest;
//   //   } else if (_currentMode == 'giver' && _giverController != null) {
//   //     return _giverController!.acceptedHelpRequest.value != null;
//   //   }
//   //   return false;
//   // }
//
//   String get _otherPersonName {
//     if (_currentMode == 'seeker' && _seekerController != null) {
//       return _seekerController!.otherPersonName;
//     } else if (_currentMode == 'giver' && _giverController != null) {
//       return _giverController!.seekerName;
//     }
//     return "Other Person";
//   }
//
//   String get _distanceText {
//     if (_currentMode == 'seeker' && _seekerController != null) {
//       return _seekerController!.distance.value;
//     } else if (_currentMode == 'giver' && _giverController != null) {
//       final request = _giverController!.acceptedHelpRequest.value;
//       return request?['distance']?.toString() ?? 'Calculating...';
//     }
//     return 'Calculating...';
//   }
//
//   String get _etaText {
//     if (_currentMode == 'seeker' && _seekerController != null) {
//       return _seekerController!.eta.value;
//     } else if (_currentMode == 'giver' && _giverController != null) {
//       final request = _giverController!.acceptedHelpRequest.value;
//       return request?['eta']?.toString() ?? 'Calculating...';
//     }
//     return 'Calculating...';
//   }
//
//   // void _setupListeners() {
//   //   // 🔥 NEW: Monitor socket connection and location sharing status
//   //   _setupConnectionStatusMonitoring();
//   //   _myLocation.addListener(() {
//   //     final myLocation = _myLocation.value;
//   //     if (myLocation != null) {
//   //       _updateMarkers();
//   //       _updateRouteIfNeeded();
//   //     }
//   //   });
//   //
//   //   if (_seekerController != null) {
//   //     ever(_seekerController!.emergencyMode, (mode) {
//   //       _updateCurrentMode();
//   //       if (_hasActiveRequest()) {
//   //         _updateOtherPersonLocation();
//   //       }
//   //     });
//   //
//   //     ever(_seekerController!.giverPosition, (position) {
//   //       if (position != null) {
//   //         Logger.log("🗺️ [SEEKER] Giver position from socket: (${position.latitude}, ${position.longitude})",
//   //             type: "success");
//   //         _handleOtherPersonLocationUpdate(
//   //             position.latitude,
//   //             position.longitude,
//   //             source: "socket"
//   //         );
//   //       }
//   //     });
//   //
//   //     ever(_seekerController!.activeHelpRequest, (request) {
//   //       if (request != null) {
//   //         Logger.log("🗺️ [SEEKER] Active request updated", type: "info");
//   //         _updateCurrentMode();
//   //         _updateOtherPersonLocation();
//   //       }
//   //     });
//   //   }
//   //
//   //   if (_giverController != null) {
//   //     ever(_giverController!.emergencyMode, (mode) {
//   //       _updateCurrentMode();
//   //       if (_hasActiveRequest()) {
//   //         _updateOtherPersonLocation();
//   //       }
//   //     });
//   //
//   //     ever(_giverController!.seekerPosition, (position) {
//   //       if (position != null) {
//   //         Logger.log("🗺️ [GIVER] Seeker position from socket: (${position.latitude}, ${position.longitude})",
//   //             type: "success");
//   //         _handleOtherPersonLocationUpdate(
//   //             position.latitude,
//   //             position.longitude,
//   //             source: "socket"
//   //         );
//   //       }
//   //     });
//   //
//   //     ever(_giverController!.acceptedHelpRequest, (request) {
//   //       if (request != null) {
//   //         Logger.log("🗺️ [GIVER] Accepted request updated", type: "info");
//   //         _updateCurrentMode();
//   //         _updateOtherPersonLocation();
//   //       }
//   //     });
//   //   }
//   //
//   //   // 🔥 CRITICAL: Listen to location updates and update markers immediately
//   //   ever(locationsController.currentPosition, (pos) {
//   //     if (pos != null) {
//   //       final newLocation = LatLng(pos.latitude, pos.longitude);
//   //       Logger.log("🗺️ My location updated: (${pos.latitude}, ${pos.longitude})", type: "debug");
//   //
//   //       // ✅ Update my location immediately
//   //       _myLocation.value = newLocation;
//   //       // 🔥 REMOVED _updateMarkers() and _updateRouteIfNeeded()
//   //       // → They will be triggered by the new listener below
//   //     }
//   //   });
//   //
//   //
//   //   // 🔥 NEW: Monitor location sharing status
//   //   ever(locationsController.isSharingLocation, (isSharing) {
//   //     isLocationSharing.value = isSharing;
//   //     Logger.log("🗺️ Location sharing status: $isSharing", type: "info");
//   //   });
//   // }
//
//   void _setupListeners() {
//     // 🔥 NEW: Monitor socket connection and location sharing status
//     _setupConnectionStatusMonitoring();
//
//     // ✅ CORRECT: Add ValueNotifier listeners
//     _myLocation.addListener(() {
//       final myLocation = _myLocation.value;
//       if (myLocation != null) {
//         Logger.log("📍 [MARKER] My location updated: (${myLocation.latitude}, ${myLocation.longitude})", type: "debug");
//
//         _updateMarkers(); // ✅ এটি মার্কার আপডেট করে
//         _updateRouteIfNeeded();
//
//         // ✅ MOVE CAMERA to new location
//         if (mapController != null) {
//           mapController?.animateCamera(
//             CameraUpdate.newLatLng(
//               LatLng(myLocation.latitude, myLocation.longitude),
//             ),
//           );
//           Logger.log("🗺️ Camera moved to new location: (${myLocation.latitude}, ${myLocation.longitude})", type: "debug");
//         }
//       }
//     });
//
//
//     _otherPersonLocation.addListener(() {
//       final otherLocation = _otherPersonLocation.value;
//       if (otherLocation != null) {
//         _updateMarkers();
//         _updateRouteIfNeeded();
//       }
//     });
//
//     if (_seekerController != null) {
//       ever(_seekerController!.emergencyMode, (mode) {
//         _updateCurrentMode();
//         if (_hasActiveRequest()) {
//           _updateOtherPersonLocation();
//
//         }
//       });
//
//       ever(_seekerController!.giverPosition, (position) {
//         if (position != null) {
//           Logger.log("🗺️ [SEEKER] Giver position from socket: (${position.latitude}, ${position.longitude})",
//               type: "success");
//           _handleOtherPersonLocationUpdate(
//               position.latitude,
//               position.longitude,
//               source: "socket"
//           );
//         }
//       });
//
//       ever(_seekerController!.activeHelpRequest, (request) {
//         if (request != null) {
//           Logger.log("🗺️ [SEEKER] Active request updated", type: "info");
//           _updateCurrentMode();
//           _updateOtherPersonLocation();
//           _startLocationSharingIfNeeded();
//         }
//       });
//     }
//
//     if (_giverController != null) {
//       ever(_giverController!.emergencyMode, (mode) {
//         _updateCurrentMode();
//         if (_hasActiveRequest()) {
//           _updateOtherPersonLocation();
//         }
//       });
//
//       ever(_giverController!.seekerPosition, (Position? position) {
//         if (position != null) {
//           Logger.log("🗺️ [GIVER] Seeker position from socket: (${position.latitude}, ${position.longitude})",
//               type: "success");
//           _handleOtherPersonLocationUpdate(
//               position.latitude,
//               position.longitude,
//               source: "socket"
//           );
//         }
//       });
//
//       ever(_giverController!.acceptedHelpRequest, (request) {
//         if (request != null) {
//           Logger.log("🗺️ [GIVER] Accepted request updated", type: "info");
//           _updateCurrentMode();
//           _updateOtherPersonLocation();
//           _startLocationSharingIfNeeded();
//         }
//       });
//     }
//
//     // ✅ FIXED: Only update ValueNotifier, not markers directly
//     ever(locationsController.currentPosition, (pos) {
//       if (pos != null) {
//         final newLocation = LatLng(pos.latitude, pos.longitude);
//         Logger.log("🗺️ My location updated: (${pos.latitude}, ${pos.longitude})", type: "debug");
//         _myLocation.value = newLocation; // Only update ValueNotifier
//       }
//     });
//
//     // 🔥 NEW: Monitor location sharing status
//     ever(locationsController.isSharingLocation, (isSharing) {
//       isLocationSharing.value = isSharing;
//       Logger.log("🗺️ Location sharing status: $isSharing", type: "info");
//     });
//   }
//
//   void _setupConnectionStatusMonitoring() {
//     _connectionMonitor?.cancel();
//     _connectionMonitor = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }
//
//       bool connected = false;
//
//       // Check seeker socket
//       if (_seekerController?.socketService != null) {
//         connected = _seekerController!.socketService!.isConnected.value;
//       }
//
//       // Check giver socket
//       if (!connected && _giverController?.socketService != null) {
//         connected = _giverController!.socketService!.isConnected.value;
//       }
//
//       if (isSocketConnected.value != connected) {
//         isSocketConnected.value = connected;
//         Logger.log("🗺️ Socket connection status changed: $connected", type: connected ? "success" : "warning");
//
//         // Show snackbar on connection status change
//         if (_hasActiveRequest()) {
//           Get.snackbar(
//             connected ? "Connected" : "Disconnected",
//             connected ? "Location sharing resumed" : "Reconnecting...",
//             snackPosition: SnackPosition.BOTTOM,
//             duration: const Duration(seconds: 2),
//             backgroundColor: connected ? Colors.green : Colors.orange,
//             colorText: Colors.white,
//           );
//         }
//       }
//     });
//   }
//
//   void _updateOtherPersonLocation() {
//     try {
//       Logger.log("=== UPDATE OTHER PERSON LOCATION ===", type: "debug");
//       Logger.log("Mode: $_currentMode", type: "debug");
//
//       double? lat;
//       double? lng;
//       String source = "Unknown";
//
//       if (_currentMode == 'seeker' && _seekerController != null) {
//         final giverPos = _seekerController!.giverPosition.value;
//         if (giverPos != null) {
//           lat = giverPos.latitude;
//           lng = giverPos.longitude;
//           source = "Real-time Socket (giverPosition)";
//           Logger.log("✅ Using real-time giver position", type: "success");
//         } else if (_seekerController!.otherPersonLatitude != null &&
//             _seekerController!.otherPersonLongitude != null) {
//           lat = _seekerController!.otherPersonLatitude;
//           lng = _seekerController!.otherPersonLongitude;
//           source = "OtherPerson Getter";
//         }
//       } else if (_currentMode == 'giver' && _giverController != null) {
//         final seekerPos = _giverController!.seekerPosition.value;
//         if (seekerPos != null) {
//           lat = seekerPos.latitude;
//           lng = seekerPos.longitude;
//           source = "Real-time Socket (seekerPosition)";
//           Logger.log("✅ Using real-time seeker position", type: "success");
//         } else if (_giverController!.seekerLatitude != null &&
//             _giverController!.seekerLongitude != null) {
//           lat = _giverController!.seekerLatitude;
//           lng = _giverController!.seekerLongitude;
//           source = "Seeker Getters";
//         }
//       }
//
//       if (lat != null && lng != null) {
//         _handleOtherPersonLocationUpdate(lat, lng, source: source);
//       } else {
//         Logger.log("❌ No location data for other person", type: "warning");
//       }
//     } catch (e) {
//       Logger.log("❌ Error in _updateOtherPersonLocation: $e", type: "error");
//     }
//   }
//
//   void _handleOtherPersonLocationUpdate(double lat, double lng, {required String source}) {
//     if (!mounted) return;
//     final newLocation = LatLng(lat, lng);
//     final oldLocation = _otherPersonLocation.value;
//
//     final hasChanged = oldLocation == null ||
//         _hasSignificantChangeDistance(oldLocation, newLocation, thresholdMeters: 3.0);
//
//     if (hasChanged) {
//       Logger.log("🎯 Location UPDATED from $source: ($lat, $lng)", type: "success");
//       _otherPersonLocation.value = newLocation;
//       _previousOtherLocation = newLocation;
//
//       _updateMarkers();
//
//       if (oldLocation == null || _hasSignificantChangeDistance(oldLocation, newLocation, thresholdMeters: 20.0)) {
//         Future.delayed(const Duration(milliseconds: 200), () {
//           _getRoutePolyline();
//           _moveCameraToShowBoth();
//         });
//       }
//     }
//   }
//
//   bool _hasSignificantChangeDistance(LatLng oldLoc, LatLng newLoc, {double thresholdMeters = 5.0}) {
//     final distance = Geolocator.distanceBetween(
//       oldLoc.latitude,
//       oldLoc.longitude,
//       newLoc.latitude,
//       newLoc.longitude,
//     );
//     return distance >= thresholdMeters;
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//     _updateMarkers();
//     if (_otherPersonLocation.value != null) {
//       _getRoutePolyline();
//     }
//     _moveCameraToShowBoth();
//   }
//
//   Future<void> _getRoutePolyline() async {
//     try {
//       final myLoc = _myLocation.value;
//       final otherPerson = _otherPersonLocation.value;
//
//       if (myLoc == null || otherPerson == null) {
//         Logger.log("🗺 Missing positions for route", type: "warning");
//         return;
//       }
//
//       setState(() {
//         _isLoadingRoute = true;
//       });
//
//       final origin = PointLatLng(myLoc.latitude, myLoc.longitude);
//       final dest = PointLatLng(otherPerson.latitude, otherPerson.longitude);
//
//       Logger.log("🗺 Fetching route...", type: "info");
//
//       final  PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//         request: PolylineRequest(
//           origin: origin,
//           destination: dest,
//           mode: TravelMode.driving,
//         ),
//       );
//
//       if (result.points.isNotEmpty) {
//         setState(() {
//           _polyPoints = result.points
//               .map((p) => LatLng(p.latitude, p.longitude))
//               .toList();
//         });
//         Logger.log("🗺 Route updated with ${_polyPoints.length} points", type: "success");
//         _lastPolylineUpdate = DateTime.now();
//       } else {
//         Logger.log("⚠ No route points. Error: ${result.errorMessage}", type: "warning");
//       }
//     } on Exception catch (e) {
//       Logger.log("❌ Route error: $e", type: "error");
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingRoute = false;
//         });
//       }
//     }
//   }
//
//   void _updateMarkers() {
//     final myLoc = _myLocation.value;
//     final otherPerson = _otherPersonLocation.value;
//
//     Logger.log("🗺 Updating markers - My: ${myLoc != null}, Other: ${otherPerson != null}", type: "debug");
//
//     final Set<Marker> newMarkers = {};
//
//     String myLabel = "";
//     String otherLabel = "";
//     BitmapDescriptor myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
//     BitmapDescriptor otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
//
//     if (_currentMode == 'seeker') {
//       myLabel = "You (Seeker)";
//       otherLabel = "$_otherPersonName (Helper)";
//       myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
//       otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
//     } else if (_currentMode == 'giver') {
//       myLabel = "You (Helper)";
//       otherLabel = "$_otherPersonName (Seeker)";
//       myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
//       otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
//     }
//
//     // Add my marker
//     if (myLoc != null) {
//       newMarkers.add(
//         Marker(
//           markerId: const MarkerId("my_location"),
//           position: myLoc,
//           infoWindow: InfoWindow(
//             title: myLabel,
//             snippet: "Current location",
//           ),
//           icon: myColor,
//           anchor: const Offset(0.5, 0.5),
//           // ✅ ADD: Make marker draggable or not
//           draggable: false,
//           // ✅ ADD: Flat marker (if needed)
//           flat: true,
//         ),
//       );
//
//       // ✅ CRITICAL FIX: Move camera to your new location
//       if (mapController != null) {
//         // Smooth animation to new location
//         mapController?.animateCamera(
//           CameraUpdate.newLatLng(
//             LatLng(myLoc.latitude, myLoc.longitude),
//           ),
//         );
//       }
//     }
//
//     // Add other person's marker
//     if (otherPerson != null) {
//       newMarkers.add(
//         Marker(
//           markerId: const MarkerId("other_person_location"),
//           position: otherPerson,
//           infoWindow: InfoWindow(
//             title: otherLabel,
//             snippet: "Distance: $_distanceText • ETA: $_etaText",
//           ),
//           icon: otherColor,
//           anchor: const Offset(0.5, 0.5),
//           draggable: false,
//           flat: true,
//         ),
//       );
//     }
//
//     if (mounted) {
//       setState(() {
//         _markers = newMarkers;
//       });
//       Logger.log("✅ Markers updated: ${newMarkers.length} markers", type: "success");
//     }
//   }
//
//   // void _updateMarkers() {
//   //   final myLoc = _myLocation.value;
//   //   final otherPerson = _otherPersonLocation.value;
//   //
//   //   Logger.log("🗺 Updating markers - My: ${myLoc != null}, Other: ${otherPerson != null}", type: "debug");
//   //
//   //   final Set<Marker> newMarkers = {};
//   //
//   //   String myLabel = "";
//   //   String otherLabel = "";
//   //   BitmapDescriptor myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
//   //   BitmapDescriptor otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
//   //
//   //   if (_currentMode == 'seeker') {
//   //     myLabel = "You (Seeker)";
//   //     otherLabel = "$_otherPersonName (Helper)";
//   //     myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
//   //     otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
//   //   } else if (_currentMode == 'giver') {
//   //     myLabel = "You (Helper)";
//   //     otherLabel = "$_otherPersonName (Seeker)";
//   //     myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
//   //     otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
//   //   }
//   //
//   //   // Add my marker
//   //   if (myLoc != null) {
//   //     newMarkers.add(
//   //       Marker(
//   //         markerId: const MarkerId("my_location"),
//   //         position: myLoc,
//   //         infoWindow: InfoWindow(
//   //           title: myLabel,
//   //           snippet: "Current location",
//   //         ),
//   //         icon: myColor,
//   //         anchor: const Offset(0.5, 0.5),
//   //       ),
//   //     );
//   //   }
//   //
//   //   // Add other person's marker
//   //   if (otherPerson != null) {
//   //     newMarkers.add(
//   //       Marker(
//   //         markerId: const MarkerId("other_person_location"),
//   //         position: otherPerson,
//   //         infoWindow: InfoWindow(
//   //           title: otherLabel,
//   //           snippet: "Distance: $_distanceText • ETA: $_etaText",
//   //         ),
//   //         icon: otherColor,
//   //         anchor: const Offset(0.5, 0.5),
//   //       ),
//   //     );
//   //   }
//   //
//   //   if (mounted) {
//   //     setState(() {
//   //       _markers = newMarkers;
//   //     });
//   //     Logger.log("✅ Markers updated: ${newMarkers.length} markers", type: "success");
//   //   }
//   // }
//
//   void _updateRouteIfNeeded() {
//     final now = DateTime.now();
//     if (_lastPolylineUpdate == null ||
//         now.difference(_lastPolylineUpdate!) > _polylineUpdateInterval) {
//       if (_otherPersonLocation.value != null && _myLocation.value != null) {
//         _getRoutePolyline();
//       }
//     }
//   }
//
//   Future<void> _moveCameraToShowBoth() async {
//     final myLoc = _myLocation.value;
//     final otherPos = _otherPersonLocation.value;
//
//     if (mapController == null || myLoc == null) return;
//
//     if (otherPos != null) {
//       final bounds = LatLngBounds(
//         southwest: LatLng(
//           myLoc.latitude < otherPos.latitude ? myLoc.latitude : otherPos.latitude,
//           myLoc.longitude < otherPos.longitude ? myLoc.longitude : otherPos.longitude,
//         ),
//         northeast: LatLng(
//           myLoc.latitude > otherPos.latitude ? myLoc.latitude : otherPos.latitude,
//           myLoc.longitude > otherPos.longitude ? myLoc.longitude : otherPos.longitude,
//         ),
//       );
//
//       await Future.delayed(const Duration(milliseconds: 200));
//
//       mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 100),
//       );
//     } else {
//       mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(myLoc, 16),
//       );
//     }
//   }
//
//   // Future<bool> _waitForSocketConnection(RxBool isConnected, String controllerName) async {
//   //   if (isConnected.value) {
//   //     Logger.log("✅ $controllerName socket already connected.", type: "info");
//   //     return true;
//   //   }
//   //
//   //   Logger.log("⏳ Waiting for $controllerName socket to connect...", type: "info");
//   //   final completer = Completer<bool>();
//   //   StreamSubscription? subscription;
//   //   Timer? timeoutTimer;
//   //
//   //   void disposeAndComplete(bool result) {
//   //     subscription?.cancel();
//   //     timeoutTimer?.cancel();
//   //     if (!completer.isCompleted) {
//   //       completer.complete(result);
//   //     }
//   //   }
//   //
//   //   subscription = isConnected.listen((connected) {
//   //     if (connected) {
//   //       Logger.log("✅ $controllerName socket connected!", type: "success");
//   //       disposeAndComplete(true);
//   //     }
//   //   });
//   //
//   //   timeoutTimer = Timer(const Duration(seconds: 5), () {
//   //     if (!isConnected.value) {
//   //       Logger.log("❌ $controllerName socket connection timed out.", type: "error");
//   //       disposeAndComplete(false);
//   //     }
//   //   });
//   //
//   //   return completer.future;
//   // }
//   //
//   // @override
//   // void didChangeAppLifecycleState(AppLifecycleState state) {
//   //   super.didChangeAppLifecycleState(state);
//   //
//   //   if (state == AppLifecycleState.resumed) {
//   //     Logger.log("📱 App resumed – attempting socket reconnection...", type: "info");
//   //
//   //     _updateCurrentMode(); // Ensure mode is up to date early
//   //
//   //     // Initiate connection attempts for relevant controllers
//   //     if (_currentMode == 'seeker' && _seekerController?.socketService != null) {
//   //       final socket = _seekerController!.socketService!;
//   //       if (!socket.isConnected.value) {
//   //         Logger.log("🔁 Reconnecting seeker socket...", type: "info");
//   //         socket.connect(); // Initiate connection
//   //       }
//   //     } else if (_currentMode == 'giver' && _giverController?.socketService != null) {
//   //       final socket = _giverController!.socketService!;
//   //       if (!socket.isConnected.value) {
//   //         Logger.log("🔁 Reconnecting giver socket...", type: "info");
//   //         socket.connect(); // Initiate connection
//   //       }
//   //     }
//   //
//   //     // Now, wait for the relevant socket to connect before proceeding
//   //     Future.microtask(() async {
//   //       if (!mounted) return;
//   //
//   //       bool socketConnected = false;
//   //       if (_currentMode == 'seeker' && _seekerController?.socketService != null) {
//   //         socketConnected = await _waitForSocketConnection(
//   //             _seekerController!.socketService!.isConnected, 'Seeker');
//   //       } else if (_currentMode == 'giver' && _giverController?.socketService != null) {
//   //         socketConnected = await _waitForSocketConnection(
//   //             _giverController!.socketService!.isConnected, 'Giver');
//   //       }
//   //
//   //       if (!mounted) return; // Check mounted again after await
//   //
//   //       if (socketConnected && _hasActiveRequest()) {
//   //         Logger.log("✅ Socket ready – restarting location sharing", type: "success");
//   //         _startLocationSharingIfNeeded();
//   //       } else {
//   //         Logger.log("⚠️ Socket not ready for location sharing or no active request.", type: "warning");
//   //       }
//   //     });
//   //   }
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           _currentMode == 'seeker' ? "Tracking Helper"
//               : _currentMode == 'giver' ? "Tracking Seeker"
//               : "Map",
//         ),
//         actions: [
//           // 🔥 NEW: Connection status indicators
//           if (_hasActiveRequest())
//             Obx(() => Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Socket connection indicator
//                   Tooltip(
//                     message: isSocketConnected.value ? "Connected" : "Disconnected",
//                     child: Container(
//                       width: 12,
//                       height: 12,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: isSocketConnected.value ? Colors.green : Colors.red,
//                         boxShadow: [
//                           BoxShadow(
//                             color: (isSocketConnected.value ? Colors.green : Colors.red).withOpacity(0.5),
//                             blurRadius: 4,
//                             spreadRadius: 1,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   // Location sharing indicator
//                   Tooltip(
//                     message: isLocationSharing.value ? "Sharing location" : "Not sharing",
//                     child: Icon(
//                       isLocationSharing.value ? Icons.my_location : Icons.location_disabled,
//                       color: isLocationSharing.value ? Colors.blue : Colors.grey,
//                       size: 22,
//                     ),
//                   ),
//                 ],
//               ),
//             ))
//           else if (_isLoadingRoute)
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: CameraPosition(
//               target: _myLocation.value ?? const LatLng(23.8103, 90.4125),
//               zoom: 15,
//             ),
//             markers: _markers,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//             trafficEnabled: true,
//             polylines: {
//               if (_polyPoints.isNotEmpty && _otherPersonLocation.value != null)
//                 Polyline(
//                   polylineId: const PolylineId("route"),
//                   points: _polyPoints,
//                   width: 5,
//                   color: Colors.blue,
//                   patterns: [
//                     PatternItem.dash(30),
//                     PatternItem.gap(10),
//                   ],
//                 )
//             },
//           ),
//
//           // Info card
//           if (_hasActiveRequest())
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Card(
//                 elevation: 8,
//                 margin: EdgeInsets.zero,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Row(
//                         children: [
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   _otherPersonName,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 Obx(() => Text(
//                                   isSocketConnected.value
//                                       ? (isLocationSharing.value ? "Live location sharing" : "Connected")
//                                       : "Reconnecting...",
//                                   style: TextStyle(
//                                     color: isSocketConnected.value ? Colors.green[600] : Colors.orange[600],
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 )),
//                               ],
//                             ),
//                           ),
//                           IconButton(
//                             onPressed: _openExternalMapsNavigation,
//                             icon: const Icon(Icons.directions, color: Colors.blue),
//                             tooltip: "Navigate",
//                           ),
//
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       const Divider(),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           Column(
//                             children: [
//                               const Icon(Icons.social_distance, color: Colors.blue),
//                               const SizedBox(height: 4),
//                               Text(
//                                 _distanceText,
//                                 style: const TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               Text(
//                                 "Distance",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Column(
//                             children: [
//                               const Icon(Icons.access_time, color: Colors.orange),
//                               const SizedBox(height: 4),
//                               Text(
//                                 _etaText,
//                                 style: const TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               Text(
//                                 "ETA",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.white,
//         shape: const CircleBorder(),
//         onPressed: (){
//           _moveCameraToShowBoth();
//           // final controller = Get.find<SeakerLocationsController>();
//           // controller.startLocationSharing();
//           // controller.startLiveLocation();
//         },
//         child: const Icon(Icons.my_location),
//         tooltip: "Center on route",
//       ),
//     );
//   }
//
//   Future<bool> _waitForSocketConnection(RxBool isConnected, String controllerName) async {
//     if (isConnected.value) {
//       Logger.log("✅ $controllerName socket already connected.", type: "info");
//       return true;
//     }
//
//     Logger.log("⏳ Waiting for $controllerName socket to connect...", type: "info");
//     final completer = Completer<bool>();
//     StreamSubscription? subscription;
//     Timer? timeoutTimer;
//
//     void disposeAndComplete(bool result) {
//       subscription?.cancel();
//       timeoutTimer?.cancel();
//       if (!completer.isCompleted) {
//         completer.complete(result);
//       }
//     }
//
//     subscription = isConnected.listen((connected) {
//       if (connected) {
//         Logger.log("✅ $controllerName socket connected!", type: "success");
//         disposeAndComplete(true);
//       }
//     });
//
//     timeoutTimer = Timer(const Duration(seconds: 5), () {
//       if (!isConnected.value) {
//         Logger.log("❌ $controllerName socket connection timed out.", type: "error");
//         disposeAndComplete(false);
//       }
//     });
//
//     return completer.future;
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controller/UnifiedHelpController.dart';

class UniversalMapViewEnhanced extends StatefulWidget {
  const UniversalMapViewEnhanced({Key? key}) : super(key: key);

  @override
  _UniversalMapViewEnhancedState createState() =>
      _UniversalMapViewEnhancedState();
}

class _UniversalMapViewEnhancedState extends State<UniversalMapViewEnhanced>
    with WidgetsBindingObserver {
  GoogleMapController? mapController;

  final SeakerLocationsController _locCtrl =
  Get.find<SeakerLocationsController>();
  UnifiedHelpController? _ctrl;

  Set<Marker> _markers = {};
  List<LatLng> _polyPoints = [];
  bool _isLoadingRoute = false;

  final ValueNotifier<LatLng?> _otherPersonLocation = ValueNotifier(null);
  final ValueNotifier<LatLng?> _myLocation = ValueNotifier(null);

  final PolylinePoints _polylinePoints =
  PolylinePoints(apiKey: AppConstants.Secret_key);
  DateTime? _lastPolylineUpdate;
  static const Duration _polylineUpdateInterval = Duration(seconds: 15);

  RxBool isSocketConnected = false.obs;
  RxBool isLocationSharing = false.obs;
  Timer? _connectionMonitor;

  // Which side of the help are we on right now?
  HelpScreenMode get _mode =>
      _ctrl?.screenMode.value ?? HelpScreenMode.idle;

  bool get _isSeeker =>
      _mode == HelpScreenMode.seekerWaiting;

  bool get _isGiver =>
      _mode == HelpScreenMode.giverHelping;

  bool get _hasActiveRequest => _isSeeker || _isGiver;

  // ─────────────────────────────────────────────────────────────────────────
  // Derived UI strings — from UnifiedHelpController only
  // ─────────────────────────────────────────────────────────────────────────
  String get _otherPersonName {
    if (_ctrl == null) return 'Other Person';
    if (_isSeeker) return _ctrl!.incomingHelperName.value;
    if (_isGiver) {
      return _ctrl!.acceptedRequest.value?['seekerName']?.toString() ?? 'Seeker';
    }
    return 'Other Person';
  }

  String get _distanceText {
    if (_ctrl == null) return 'Calculating...';
    if (_isSeeker) return _ctrl!.seekerToHelperDistance.value;
    if (_isGiver) {
      return _ctrl!.acceptedRequest.value?['distance']?.toString() ??
          'Calculating...';
    }
    return 'Calculating...';
  }

  String get _etaText {
    if (_ctrl == null) return 'Calculating...';
    if (_isSeeker) return _ctrl!.seekerToHelperEta.value;
    if (_isGiver) {
      return _ctrl!.acceptedRequest.value?['eta']?.toString() ??
          'Calculating...';
    }
    return 'Calculating...';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initControllers();
      _setupListeners();
      _initializeMap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionMonitor?.cancel();
    _otherPersonLocation.dispose();
    _myLocation.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  void _handleAppResume() {
    if (!mounted) return;
    Logger.log("📱 App resumed — refreshing socket", type: "info");
    _locCtrl.refreshAfterMapReturn();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────────────────
  void _initControllers() {
    if (Get.isRegistered<UnifiedHelpController>()) {
      _ctrl = Get.find<UnifiedHelpController>();
    }
    Logger.log("📱 Map mode: $_mode", type: "info");
  }

  void _initializeMap() {
    final pos = _locCtrl.currentPosition.value;
    if (pos != null) {
      _myLocation.value = LatLng(pos.latitude, pos.longitude);
      _updateMarkers();
    }
    if (_hasActiveRequest) {
      _updateOtherPersonLocation();
      _startLocationSharingIfNeeded();
    }
  }

  void _startLocationSharingIfNeeded() {
    if (_ctrl == null) return;

    String requestId = _locCtrl.currentHelpRequestId.value;

    if (requestId.isEmpty) {
      if (_isGiver) {
        requestId = _ctrl!.acceptedRequest.value?['_id']?.toString() ?? '';
      } else if (_isSeeker) {
        requestId = _ctrl!.seekerHelpRequestId.value;
      }
    }

    if (requestId.isNotEmpty) {
      _locCtrl.setHelpRequestId(requestId);
      if (!_locCtrl.isSharingLocation.value) {
        _locCtrl.startLocationSharing();
      }
      if (!_locCtrl.liveLocation.value) {
        _locCtrl.resetFirstLocationFlag();
        _locCtrl.startLiveLocation();
      }
    } else {
      Logger.log("⚠️ [MAP] Cannot start sharing — no request ID", type: "warning");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LISTENERS
  // ─────────────────────────────────────────────────────────────────────────
  void _setupListeners() {
    _setupConnectionMonitor();

    // My position updates
    _myLocation.addListener(() {
      final loc = _myLocation.value;
      if (loc != null) {
        _updateMarkers();
        _updateRouteIfNeeded();
        mapController?.animateCamera(CameraUpdate.newLatLng(loc));
      }
    });

    // Other person location updates
    _otherPersonLocation.addListener(() {
      if (_otherPersonLocation.value != null) {
        _updateMarkers();
        _updateRouteIfNeeded();
      }
    });

    // Listen to live GPS stream
    ever(_locCtrl.currentPosition, (Position? pos) {
      if (pos != null) {
        _myLocation.value = LatLng(pos.latitude, pos.longitude);
      }
    });

    // Location sharing flag
    ever(_locCtrl.isSharingLocation, (bool isSharing) {
      isLocationSharing.value = isSharing;
    });

    if (_ctrl == null) return;

    // Screen mode changes → re-evaluate context
    ever(_ctrl!.screenMode, (HelpScreenMode mode) {
      Logger.log("🗺️ [MAP] Screen mode changed: $mode", type: "info");
      if (_hasActiveRequest) {
        _updateOtherPersonLocation();
        _startLocationSharingIfNeeded();
      }
    });

    // Helper's live position (seeker sees helper coming)
    ever(_ctrl!.incomingHelperPosition, (Position? pos) {
      if (pos != null && _isSeeker) {
        Logger.log(
            "🗺️ [MAP-SEEKER] Helper pos: (${pos.latitude}, ${pos.longitude})",
            type: "success");
        _handleOtherPersonUpdate(pos.latitude, pos.longitude);
      }
    });

    // Seeker's live position (giver sees seeker)
    ever(_ctrl!.seekerLivePosition, (Position? pos) {
      if (pos != null && _isGiver) {
        Logger.log(
            "🗺️ [MAP-GIVER] Seeker pos: (${pos.latitude}, ${pos.longitude})",
            type: "success");
        _handleOtherPersonUpdate(pos.latitude, pos.longitude);
      }
    });

    // Accepted request changes (giver accepted a new one)
    ever(_ctrl!.acceptedRequest, (Map<String, dynamic>? req) {
      if (req != null) {
        _updateOtherPersonLocation();
        _startLocationSharingIfNeeded();
      }
    });
  }

  void _setupConnectionMonitor() {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      final socket = _locCtrl.getActiveSocket();
      final connected = socket?.isConnected.value ?? false;
      if (isSocketConnected.value != connected) {
        isSocketConnected.value = connected;
        if (_hasActiveRequest) {
          Get.snackbar(
            connected ? "Connected" : "Disconnected",
            connected ? "Location sharing resumed" : "Reconnecting...",
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: connected ? Colors.green : Colors.orange,
            colorText: Colors.white,
          );
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTHER PERSON LOCATION
  // ─────────────────────────────────────────────────────────────────────────
  void _updateOtherPersonLocation() {
    if (_ctrl == null) return;

    double? lat;
    double? lng;

    if (_isSeeker) {
      final pos = _ctrl!.incomingHelperPosition.value;
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } else if (_isGiver) {
      final pos = _ctrl!.seekerLivePosition.value;
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    }

    if (lat != null && lng != null) {
      _handleOtherPersonUpdate(lat, lng);
    }
  }

  void _handleOtherPersonUpdate(double lat, double lng) {
    if (!mounted) return;
    final newLoc = LatLng(lat, lng);
    final old = _otherPersonLocation.value;

    final changed = old == null ||
        Geolocator.distanceBetween(
            old.latitude, old.longitude, lat, lng) >= 3.0;

    if (changed) {
      _otherPersonLocation.value = newLoc;
      _updateMarkers();
      if (old == null ||
          Geolocator.distanceBetween(
              old.latitude, old.longitude, lat, lng) >= 20.0) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _getRoutePolyline();
          _moveCameraToShowBoth();
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MARKERS
  // ─────────────────────────────────────────────────────────────────────────
  void _updateMarkers() {
    final myLoc = _myLocation.value;
    final other = _otherPersonLocation.value;
    final Set<Marker> newMarkers = {};

    if (myLoc != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId("my_location"),
        position: myLoc,
        infoWindow: InfoWindow(
          title: _isSeeker ? "You (Seeker)" : "You (Helper)",
          snippet: "Current location",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _isSeeker ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
        ),
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    if (other != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId("other_person"),
        position: other,
        infoWindow: InfoWindow(
          title: _otherPersonName,
          snippet: "Distance: $_distanceText • ETA: $_etaText",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _isSeeker ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    if (mounted) {
      setState(() => _markers = newMarkers);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POLYLINE
  // ─────────────────────────────────────────────────────────────────────────
  void _updateRouteIfNeeded() {
    final now = DateTime.now();
    if (_lastPolylineUpdate == null ||
        now.difference(_lastPolylineUpdate!) > _polylineUpdateInterval) {
      if (_otherPersonLocation.value != null && _myLocation.value != null) {
        _getRoutePolyline();
      }
    }
  }

  Future<void> _getRoutePolyline() async {
    final myLoc = _myLocation.value;
    final other = _otherPersonLocation.value;
    if (myLoc == null || other == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(myLoc.latitude, myLoc.longitude),
          destination: PointLatLng(other.latitude, other.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        setState(() {
          _polyPoints = result.points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
        });
        _lastPolylineUpdate = DateTime.now();
      }
    } catch (e) {
      Logger.log("❌ Route error: $e", type: "error");
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _moveCameraToShowBoth() async {
    final myLoc = _myLocation.value;
    final other = _otherPersonLocation.value;
    if (mapController == null || myLoc == null) return;

    if (other != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          myLoc.latitude < other.latitude ? myLoc.latitude : other.latitude,
          myLoc.longitude < other.longitude ? myLoc.longitude : other.longitude,
        ),
        northeast: LatLng(
          myLoc.latitude > other.latitude ? myLoc.latitude : other.latitude,
          myLoc.longitude > other.longitude ? myLoc.longitude : other.longitude,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 200));
      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } else {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(myLoc, 16));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXTERNAL NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _openExternalMaps() async {
    final my = _myLocation.value;
    final other = _otherPersonLocation.value;
    if (my == null || other == null) {
      Get.snackbar("Navigation", "Location data not available",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      if (Platform.isIOS) {
        final url = Uri.parse(
            'http://maps.apple.com/?saddr=${my.latitude},${my.longitude}&daddr=${other.latitude},${other.longitude}&dirflg=d');
        if (await canLaunchUrl(url)) await launchUrl(url);
      } else {
        final url = Uri.parse(
            'google.navigation:q=${other.latitude},${other.longitude}&from=${my.latitude},${my.longitude}');
        final fallback = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&origin=${my.latitude},${my.longitude}&destination=${other.latitude},${other.longitude}&travelmode=driving');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else if (await canLaunchUrl(fallback)) {
          await launchUrl(fallback);
        }
      }
    } catch (e) {
      Get.snackbar("Navigation Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSeeker
              ? "Tracking Helper"
              : _isGiver
              ? "Tracking Seeker"
              : "Map",
        ),
        actions: [
          if (_hasActiveRequest)
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: isSocketConnected.value
                        ? "Connected"
                        : "Disconnected",
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSocketConnected.value
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isLocationSharing.value
                        ? Icons.my_location
                        : Icons.location_disabled,
                    color: isLocationSharing.value
                        ? Colors.blue
                        : Colors.grey,
                    size: 22,
                  ),
                ],
              ),
            ))
          else if (_isLoadingRoute)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              mapController = c;
              _updateMarkers();
              if (_otherPersonLocation.value != null) _getRoutePolyline();
              _moveCameraToShowBoth();
            },
            initialCameraPosition: CameraPosition(
              target: _myLocation.value ?? const LatLng(23.8103, 90.4125),
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            trafficEnabled: true,
            polylines: {
              if (_polyPoints.isNotEmpty && _otherPersonLocation.value != null)
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: _polyPoints,
                  width: 5,
                  color: Colors.blue,
                  patterns: [
                    PatternItem.dash(30),
                    PatternItem.gap(10),
                  ],
                ),
            },
          ),
          if (_hasActiveRequest)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                elevation: 8,
                margin: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _otherPersonName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Obx(() => Text(
                                  isSocketConnected.value
                                      ? (isLocationSharing.value
                                      ? "Live location sharing"
                                      : "Connected")
                                      : "Reconnecting...",
                                  style: TextStyle(
                                    color: isSocketConnected.value
                                        ? Colors.green[600]
                                        : Colors.orange[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _openExternalMaps,
                            icon: const Icon(Icons.directions,
                                color: Colors.blue),
                            tooltip: "Navigate",
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [
                            const Icon(Icons.social_distance,
                                color: Colors.blue),
                            const SizedBox(height: 4),
                            Text(_distanceText,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("Distance",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600])),
                          ]),
                          Column(children: [
                            const Icon(Icons.access_time,
                                color: Colors.orange),
                            const SizedBox(height: 4),
                            Text(_etaText,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("ETA",
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600])),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: _moveCameraToShowBoth,
        tooltip: "Center on route",
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
