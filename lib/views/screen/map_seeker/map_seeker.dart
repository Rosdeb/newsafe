// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
// import 'package:get/get.dart';
// import 'package:saferader/utils/app_constant.dart';
// import 'package:saferader/utils/logger.dart';
// import 'package:geolocator/geolocator.dart';
//
// import '../../../controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
// import '../../../controller/SeakerHome/seakerHomeController.dart';
//
// class UniversalMapView extends StatefulWidget {
//   @override
//   _UniversalMapViewState createState() => _UniversalMapViewState();
// }
//
// class _UniversalMapViewState extends State<UniversalMapView> {
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
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
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
//     }on Exception catch (e) {
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
//       final userRole = controller.userController.userRole.value;
//       return userRole == "seeker" || (userRole == "both" && !controller.helperStatus.value);
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
//     if (_currentMode == 'seeker' && _seekerController != null) {
//       return _seekerController!.hasActiveHelpRequest;
//     } else if (_currentMode == 'giver' && _giverController != null) {
//       return _giverController!.acceptedHelpRequest.value != null;
//     }
//     return false;
//   }
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
//   String get _otherPersonImage {
//     if (_currentMode == 'seeker' && _seekerController != null) {
//       return _seekerController!.helperImage;
//     } else if (_currentMode == 'giver' && _giverController != null) {
//       final request = _giverController!.acceptedHelpRequest.value;
//       final seeker = request?['seeker'] as Map<String, dynamic>?;
//       return seeker?['profileImage']?.toString() ?? '';
//     }
//     return '';
//   }
//
//   void _setupListeners() {
//     // Listen for mode changes
//     if (_seekerController != null) {
//       ever(_seekerController!.emergencyMode, (mode) {
//         _updateCurrentMode();
//         if (_hasActiveRequest()) {
//           _updateOtherPersonLocation();
//         }
//       });
//
//       // Listen for giver position updates (REAL-TIME SOCKET)
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
//       // Listen for help request updates
//       ever(_seekerController!.activeHelpRequest, (request) {
//         if (request != null) {
//           Logger.log("🗺️ [SEEKER] Active request updated", type: "info");
//           _updateCurrentMode();
//           _updateOtherPersonLocation();
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
//       // Listen for seeker position updates (REAL-TIME SOCKET)
//       ever(_giverController!.seekerPosition, (position) {
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
//       // Listen for accepted request updates
//       ever(_giverController!.acceptedHelpRequest, (request) {
//         if (request != null) {
//           Logger.log("🗺️ [GIVER] Accepted request updated", type: "info");
//           _updateCurrentMode();
//           _updateOtherPersonLocation();
//         }
//       });
//     }
//
//     // 🔥 FIXED: Listen to my location updates - ALWAYS UPDATE, NO THRESHOLD
//     ever(locationsController.currentPosition, (pos) {
//       if (pos != null) {
//         final newLocation = LatLng(pos.latitude, pos.longitude);
//
//         Logger.log("🗺️ My location updated: (${pos.latitude}, ${pos.longitude})", type: "debug");
//
//         // Always update my location - no threshold check
//         _myLocation.value = newLocation;
//
//         // Update markers immediately on every location change
//         _updateMarkers();
//
//         // Update route if needed (has its own throttling)
//         _updateRouteIfNeeded();
//       }
//     });
//   }
//
//   void _initializeMap() {
//     if (_hasActiveRequest()) {
//       _updateOtherPersonLocation();
//     }
//
//     // Initial camera position based on my location
//     final pos = locationsController.currentPosition.value;
//     if (pos != null) {
//       _myLocation.value = LatLng(pos.latitude, pos.longitude);
//       _updateMarkers();
//     }
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
//         // 🔥 PRIORITY 1: Check real-time socket position FIRST
//         final giverPos = _seekerController!.giverPosition.value;
//         if (giverPos != null) {
//           lat = giverPos.latitude;
//           lng = giverPos.longitude;
//           source = "Real-time Socket (giverPosition)";
//           Logger.log("✅ Using real-time giver position", type: "success");
//         }
//         // PRIORITY 2: Check getters
//         else if (_seekerController!.otherPersonLatitude != null &&
//             _seekerController!.otherPersonLongitude != null) {
//           lat = _seekerController!.otherPersonLatitude;
//           lng = _seekerController!.otherPersonLongitude;
//           source = "OtherPerson Getter";
//         }
//         // PRIORITY 3: Check active request
//         else if (_seekerController!.activeHelpRequest.value != null) {
//           final activeRequest = _seekerController!.activeHelpRequest.value!;
//
//           // Try from giverLocation first
//           final giverLocation = activeRequest['giverLocation'] as Map<String, dynamic>?;
//           if (giverLocation != null) {
//             lat = giverLocation['latitude']?.toDouble();
//             lng = giverLocation['longitude']?.toDouble();
//             source = "GiverLocation from Request";
//           }
//
//           // Try from helper object
//           if (lat == null || lng == null) {
//             final helper = activeRequest['helper'] as Map<String, dynamic>?;
//             if (helper != null) {
//               final location = helper['location'] as Map<String, dynamic>?;
//               if (location != null) {
//                 final coordinates = location['coordinates'] as List<dynamic>?;
//                 if (coordinates != null && coordinates.length >= 2) {
//                   lat = (coordinates[1] as num).toDouble();
//                   lng = (coordinates[0] as num).toDouble();
//                   source = "Helper Coordinates";
//                 }
//               }
//             }
//           }
//         }
//
//       } else if (_currentMode == 'giver' && _giverController != null) {
//         // 🔥 PRIORITY 1: Check real-time socket position FIRST
//         final seekerPos = _giverController!.seekerPosition.value;
//         if (seekerPos != null) {
//           lat = seekerPos.latitude;
//           lng = seekerPos.longitude;
//           source = "Real-time Socket (seekerPosition)";
//           Logger.log("✅ Using real-time seeker position", type: "success");
//         }
//         // PRIORITY 2: Check getters
//         else if (_giverController!.seekerLatitude != null &&
//             _giverController!.seekerLongitude != null) {
//           lat = _giverController!.seekerLatitude;
//           lng = _giverController!.seekerLongitude;
//           source = "Seeker Getters";
//         }
//         // PRIORITY 3: Check accepted request
//         else if (_giverController!.acceptedHelpRequest.value != null) {
//           final acceptedRequest = _giverController!.acceptedHelpRequest.value!;
//
//           // Try from request location
//           final location = acceptedRequest['location'] as Map<String, dynamic>?;
//           if (location != null) {
//             final coordinates = location['coordinates'] as List<dynamic>?;
//             if (coordinates != null && coordinates.length >= 2) {
//               lat = (coordinates[1] as num).toDouble();
//               lng = (coordinates[0] as num).toDouble();
//               source = "Request Coordinates";
//             }
//           }
//         }
//       }
//
//       if (lat != null && lng != null) {
//         _handleOtherPersonLocationUpdate(lat, lng, source: source);
//       } else {
//         Logger.log("❌ No location data for other person", type: "warning");
//         _debugCurrentState();
//       }
//
//     } catch (e, stackTrace) {
//       Logger.log("❌ Error in _updateOtherPersonLocation: $e", type: "error");
//       Logger.log("Stack trace: $stackTrace", type: "error");
//     }
//   }
//
//   void _handleOtherPersonLocationUpdate(double lat, double lng, {required String source}) {
//     final newLocation = LatLng(lat, lng);
//     final oldLocation = _otherPersonLocation.value;
//
//     // Check if location actually changed (with small tolerance for OTHER person to avoid jitter)
//     final hasChanged = oldLocation == null ||
//         _hasSignificantChangeDistance(oldLocation, newLocation, thresholdMeters: 3.0);
//
//     if (hasChanged) {
//       Logger.log("🎯 Location UPDATED from $source: ($lat, $lng)", type: "success");
//
//       _otherPersonLocation.value = newLocation;
//       _previousOtherLocation = newLocation;
//
//       // 🔥 Update markers immediately
//       _updateMarkers();
//
//       // Update route only if significant change (saves API calls)
//       if (oldLocation == null || _hasSignificantChangeDistance(oldLocation, newLocation, thresholdMeters: 20.0)) {
//         Future.delayed(const Duration(milliseconds: 200), () {
//           _getRoutePolyline();
//           _moveCameraToShowBoth();
//         });
//       }
//     } else {
//       Logger.log("⚪ Other person location unchanged (within 3m threshold)", type: "debug");
//     }
//   }
//
//   // 🔥 Distance-based change detection using Geolocator
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
//
//     // Initial camera position
//     final pos = locationsController.currentPosition.value;
//     if (pos != null) {
//       _updateMarkers();
//       if (_otherPersonLocation.value != null) {
//         _getRoutePolyline();
//       }
//       _moveCameraToShowBoth();
//     }
//   }
//
//   Future<void> _getRoutePolyline() async {
//     try {
//       final currentPos = locationsController.currentPosition.value;
//       final otherPerson = _otherPersonLocation.value;
//
//       if (currentPos == null || otherPerson == null) {
//         Logger.log("🗺 Missing positions for route", type: "warning");
//         return;
//       }
//
//       setState(() {
//         _isLoadingRoute = true;
//       });
//
//       final origin = PointLatLng(currentPos.latitude, currentPos.longitude);
//       final dest = PointLatLng(otherPerson.latitude, otherPerson.longitude);
//
//       Logger.log("🗺 Fetching route...", type: "info");
//
//       PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
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
//     }on Exception catch (e) {
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
//     final currentPos = _myLocation.value;
//     final otherPerson = _otherPersonLocation.value;
//
//     Logger.log("🗺 Updating markers - My: ${currentPos != null}, Other: ${otherPerson != null}", type: "debug");
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
//     // Add my marker - ALWAYS UPDATE with latest position
//     if (currentPos != null) {
//       newMarkers.add(
//         Marker(
//           markerId: const MarkerId("my_location"),
//           position: LatLng(currentPos.latitude, currentPos.longitude),
//           infoWindow: InfoWindow(
//             title: myLabel,
//             snippet: "Current location",
//           ),
//           icon: myColor,
//           anchor: const Offset(0.5, 0.5),
//         ),
//       );
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
//         ),
//       );
//     }
//
//     if (mounted) {
//       setState(() {
//         _markers = newMarkers;
//       });
//     }
//
//     Logger.log("✅ Markers updated: ${newMarkers.length} markers", type: "success");
//   }
//
//   void _updateRouteIfNeeded() {
//     final now = DateTime.now();
//     if (_lastPolylineUpdate == null ||
//         now.difference(_lastPolylineUpdate!) > _polylineUpdateInterval) {
//       if (_otherPersonLocation.value != null) {
//         _getRoutePolyline();
//       }
//     }
//   }
//
//   void _moveCameraToShowBoth() async {
//     final currentPos = locationsController.currentPosition.value;
//     final otherPos = _otherPersonLocation.value;
//
//     if (mapController == null || currentPos == null) return;
//
//     if (otherPos != null) {
//       final bounds = LatLngBounds(
//         southwest: LatLng(
//           currentPos.latitude < otherPos.latitude ? currentPos.latitude : otherPos.latitude,
//           currentPos.longitude < otherPos.longitude ? currentPos.longitude : otherPos.longitude,
//         ),
//         northeast: LatLng(
//           currentPos.latitude > otherPos.latitude ? currentPos.latitude : otherPos.latitude,
//           currentPos.longitude > otherPos.longitude ? currentPos.longitude : otherPos.longitude,
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
//         CameraUpdate.newLatLngZoom(
//           LatLng(currentPos.latitude, currentPos.longitude),
//           16,
//         ),
//       );
//     }
//   }
//
//   void _debugCurrentState() {
//     Logger.log("=== DEBUG STATE ===", type: "info");
//     Logger.log("Mode: $_currentMode", type: "info");
//     Logger.log("Has Active Request: ${_hasActiveRequest()}", type: "info");
//     Logger.log("Markers count: ${_markers.length}", type: "info");
//
//     if (_currentMode == 'seeker' && _seekerController != null) {
//       Logger.log("Seeker Controller:", type: "info");
//       Logger.log("- giverPosition: ${_seekerController!.giverPosition.value}", type: "info");
//       Logger.log("- otherPersonLatitude: ${_seekerController!.otherPersonLatitude}", type: "info");
//       Logger.log("- otherPersonLongitude: ${_seekerController!.otherPersonLongitude}", type: "info");
//       Logger.log("- hasActiveHelpRequest: ${_seekerController!.hasActiveHelpRequest}", type: "info");
//     }
//
//     if (_currentMode == 'giver' && _giverController != null) {
//       Logger.log("Giver Controller:", type: "info");
//       Logger.log("- seekerPosition: ${_giverController!.seekerPosition.value}", type: "info");
//       Logger.log("- seekerLatitude: ${_giverController!.seekerLatitude}", type: "info");
//       Logger.log("- seekerLongitude: ${_giverController!.seekerLongitude}", type: "info");
//     }
//
//     Logger.log("=== END DEBUG ===", type: "info");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           _currentMode == 'seeker' ? "Tracking Helper" :
//           _currentMode == 'giver' ? "Tracking Seeker" : "Map",
//         ),
//         actions: [
//           if (_isLoadingRoute)
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
//             )
//           else if (_hasActiveRequest())
//             const Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Icon(Icons.navigation, color: Colors.green),
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: CameraPosition(
//               target: LatLng(
//                 locationsController.currentPosition.value?.latitude ?? 23.8103,
//                 locationsController.currentPosition.value?.longitude ?? 90.4125,
//               ),
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
//               bottom: -5,
//               left: -5,
//               right: -5,
//               child: Card(
//                 elevation: 8,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
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
//                                 Text(
//                                   locationsController.sharingStatus,
//                                   style: TextStyle(
//                                     color: Colors.grey[600],
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
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
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           const SizedBox(height: 10),
//           FloatingActionButton.small(
//             backgroundColor: Colors.red,
//             onPressed: _debugCurrentState,
//             child: const Icon(Icons.bug_report),
//             tooltip: "Debug Info",
//           ),
//           const SizedBox(height: 10),
//           FloatingActionButton(
//             backgroundColor: Colors.white,
//             shape: const CircleBorder(),
//             onPressed: _moveCameraToShowBoth,
//             child: const Icon(Icons.my_location),
//             tooltip: "Center on route",
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _otherPersonLocation.dispose();
//     _myLocation.dispose();
//     mapController?.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import 'package:geolocator/geolocator.dart';

import '../../../controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../../../controller/SeakerHome/seakerHomeController.dart';

class UniversalMapView extends StatefulWidget {
  @override
  _UniversalMapViewState createState() => _UniversalMapViewState();
}

class _UniversalMapViewState extends State<UniversalMapView> {

  GoogleMapController? mapController;
  final locationsController = Get.find<SeakerLocationsController>();

  SeakerHomeController? _seekerController;
  GiverHomeController? _giverController;

  Set<Marker> _markers = {};
  List<LatLng> _polyPoints = [];
  bool _isLoadingRoute = false;

  ValueNotifier<LatLng?> _otherPersonLocation = ValueNotifier(null);
  ValueNotifier<LatLng?> _myLocation = ValueNotifier(null);

  LatLng? _previousOtherLocation;

  final PolylinePoints polylinePoints = PolylinePoints(apiKey: AppConstants.Secret_key);
  DateTime? _lastPolylineUpdate;
  static const Duration _polylineUpdateInterval = Duration(seconds: 15);

  String _currentMode = 'none';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeControllers();
      _setupListeners();
      _initializeMap();
    });
  }

  Future<void> _initializeControllers() async {
    try {
      if (Get.isRegistered<SeakerHomeController>()) {
        _seekerController = Get.find<SeakerHomeController>();
      }

      if (Get.isRegistered<GiverHomeController>()) {
        _giverController = Get.find<GiverHomeController>();
      }

      _updateCurrentMode();
    } on Exception catch (e) {
      Logger.log("❌ Error initializing controllers: $e", type: "error");
    }
  }

  void _updateCurrentMode() {
    if (_isSeekerMode()) {
      _currentMode = 'seeker';
    } else if (_isGiverMode()) {
      _currentMode = 'giver';
    } else {
      _currentMode = 'none';
    }
    Logger.log("📱 Current mode: $_currentMode", type: "info");
  }

  bool _isSeekerMode() {
    if (Get.isRegistered<SeakerHomeController>()) {
      final controller = Get.find<SeakerHomeController>();
      final userRole = controller.userController.userRole.value;
      return userRole == "seeker" || (userRole == "both" && !controller.helperStatus.value);
    }
    return false;
  }

  bool _isGiverMode() {
    if (Get.isRegistered<GiverHomeController>()) {
      return Get.find<GiverHomeController>().emergencyMode.value == 2;
    }
    return false;
  }

  bool _hasActiveRequest() {
    if (_currentMode == 'seeker' && _seekerController != null) {
      return _seekerController!.hasActiveHelpRequest;
    } else if (_currentMode == 'giver' && _giverController != null) {
      return _giverController!.acceptedHelpRequest.value != null;
    }
    return false;
  }

  String get _otherPersonName {
    if (_currentMode == 'seeker' && _seekerController != null) {
      return _seekerController!.otherPersonName;
    } else if (_currentMode == 'giver' && _giverController != null) {
      return _giverController!.seekerName;
    }
    return "Other Person";
  }

  String get _distanceText {
    if (_currentMode == 'seeker' && _seekerController != null) {
      return _seekerController!.distance.value;
    } else if (_currentMode == 'giver' && _giverController != null) {
      final request = _giverController!.acceptedHelpRequest.value;
      return request?['distance']?.toString() ?? 'Calculating...';
    }
    return 'Calculating...';
  }

  String get _etaText {
    if (_currentMode == 'seeker' && _seekerController != null) {
      return _seekerController!.eta.value;
    } else if (_currentMode == 'giver' && _giverController != null) {
      final request = _giverController!.acceptedHelpRequest.value;
      return request?['eta']?.toString() ?? 'Calculating...';
    }
    return 'Calculating...';
  }

  String get _otherPersonImage {
    if (_currentMode == 'seeker' && _seekerController != null) {
      return _seekerController!.helperImage;
    } else if (_currentMode == 'giver' && _giverController != null) {
      final request = _giverController!.acceptedHelpRequest.value;
      final seeker = request?['seeker'] as Map<String, dynamic>?;
      return seeker?['profileImage']?.toString() ?? '';
    }
    return '';
  }

  void _setupListeners() {
    if (_seekerController != null) {
      ever(_seekerController!.emergencyMode, (mode) {
        _updateCurrentMode();
        if (_hasActiveRequest()) {
          _updateOtherPersonLocation();
        }
      });

      ever(_seekerController!.giverPosition, (position) {
        if (position != null) {
          Logger.log("🗺️ [SEEKER] Giver position from socket: (${position.latitude}, ${position.longitude})",
              type: "success");
          _handleOtherPersonLocationUpdate(
              position.latitude,
              position.longitude,
              source: "socket"
          );
        }
      });

      ever(_seekerController!.activeHelpRequest, (request) {
        if (request != null) {
          Logger.log("🗺️ [SEEKER] Active request updated", type: "info");
          _updateCurrentMode();
          _updateOtherPersonLocation();
        }
      });
    }

    if (_giverController != null) {
      ever(_giverController!.emergencyMode, (mode) {
        _updateCurrentMode();
        if (_hasActiveRequest()) {
          _updateOtherPersonLocation();
        }
      });

      ever(_giverController!.seekerPosition, (Position? position) {
        if (position != null) {
          Logger.log("🗺️ [GIVER] Seeker position from socket: (${position.latitude}, ${position.longitude})",
              type: "success");
          _handleOtherPersonLocationUpdate(
              position.latitude,
              position.longitude,
              source: "socket"
          );
        }
      });

      ever(_giverController!.acceptedHelpRequest, (request) {
        if (request != null) {
          Logger.log("🗺️ [GIVER] Accepted request updated", type: "info");
          _updateCurrentMode();
          _updateOtherPersonLocation();
        }
      });
    }

    // 🔥 ALWAYS update _myLocation on every position change
    ever(locationsController.currentPosition, (pos) {
      if (pos != null) {
        final newLocation = LatLng(pos.latitude, pos.longitude);
        Logger.log("🗺️ My location updated: (${pos.latitude}, ${pos.longitude})", type: "debug");

        // ✅ Update the source of truth for "my location"
        _myLocation.value = newLocation;

        // ✅ Trigger immediate marker & route updates
        _updateMarkers();
        _updateRouteIfNeeded();
      }
    });
  }

  void _initializeMap() {
    if (_hasActiveRequest()) {
      _updateOtherPersonLocation();
    }

    final pos = locationsController.currentPosition.value;
    if (pos != null) {
      _myLocation.value = LatLng(pos.latitude, pos.longitude);
      _updateMarkers();
    }
  }

  void _updateOtherPersonLocation() {
    try {
      Logger.log("=== UPDATE OTHER PERSON LOCATION ===", type: "debug");
      Logger.log("Mode: $_currentMode", type: "debug");

      double? lat;
      double? lng;
      String source = "Unknown";

      if (_currentMode == 'seeker' && _seekerController != null) {
        final giverPos = _seekerController!.giverPosition.value;
        if (giverPos != null) {
          lat = giverPos.latitude;
          lng = giverPos.longitude;
          source = "Real-time Socket (giverPosition)";
          Logger.log("✅ Using real-time giver position", type: "success");
        } else if (_seekerController!.otherPersonLatitude != null &&
            _seekerController!.otherPersonLongitude != null) {
          lat = _seekerController!.otherPersonLatitude;
          lng = _seekerController!.otherPersonLongitude;
          source = "OtherPerson Getter";
        } else if (_seekerController!.activeHelpRequest.value != null) {
          final activeRequest = _seekerController!.activeHelpRequest.value!;

          final giverLocation = activeRequest['giverLocation'] as Map<String, dynamic>?;
          if (giverLocation != null) {
            lat = giverLocation['latitude']?.toDouble();
            lng = giverLocation['longitude']?.toDouble();
            source = "GiverLocation from Request";
          }

          if (lat == null || lng == null) {
            final helper = activeRequest['helper'] as Map<String, dynamic>?;
            if (helper != null) {
              final location = helper['location'] as Map<String, dynamic>?;
              if (location != null) {
                final coordinates = location['coordinates'] as List<dynamic>?;
                if (coordinates != null && coordinates.length >= 2) {
                  lat = (coordinates[1] as num).toDouble();
                  lng = (coordinates[0] as num).toDouble();
                  source = "Helper Coordinates";
                }
              }
            }
          }
        }
      } else if (_currentMode == 'giver' && _giverController != null) {
        final seekerPos = _giverController!.seekerPosition.value;
        if (seekerPos != null) {
          lat = seekerPos.latitude;
          lng = seekerPos.longitude;
          source = "Real-time Socket (seekerPosition)";
          Logger.log("✅ Using real-time seeker position", type: "success");
        } else if (_giverController!.seekerLatitude != null &&
            _giverController!.seekerLongitude != null) {
          lat = _giverController!.seekerLatitude;
          lng = _giverController!.seekerLongitude;
          source = "Seeker Getters";
        } else if (_giverController!.acceptedHelpRequest.value != null) {
          final acceptedRequest = _giverController!.acceptedHelpRequest.value!;
          final location = acceptedRequest['location'] as Map<String, dynamic>?;
          if (location != null) {
            final coordinates = location['coordinates'] as List<dynamic>?;
            if (coordinates != null && coordinates.length >= 2) {
              lat = (coordinates[1] as num).toDouble();
              lng = (coordinates[0] as num).toDouble();
              source = "Request Coordinates";
            }
          }
        }
      }

      if (lat != null && lng != null) {
        _handleOtherPersonLocationUpdate(lat, lng, source: source);
      } else {
        Logger.log("❌ No location data for other person", type: "warning");
        _debugCurrentState();
      }
    } catch (e, stackTrace) {
      Logger.log("❌ Error in _updateOtherPersonLocation: $e", type: "error");
      Logger.log("Stack trace: $stackTrace", type: "error");
    }
  }

  void _handleOtherPersonLocationUpdate(double lat, double lng, {required String source}) {
    final newLocation = LatLng(lat, lng);
    final oldLocation = _otherPersonLocation.value;

    final hasChanged = oldLocation == null ||
        _hasSignificantChangeDistance(oldLocation, newLocation, thresholdMeters: 3.0);

    if (hasChanged) {
      Logger.log("🎯 Location UPDATED from $source: ($lat, $lng)", type: "success");
      _otherPersonLocation.value = newLocation;
      _previousOtherLocation = newLocation;

      _updateMarkers();

      if (oldLocation == null || _hasSignificantChangeDistance(oldLocation, newLocation, thresholdMeters: 20.0)) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _getRoutePolyline();
          _moveCameraToShowBoth();
        });
      }
    } else {
      Logger.log("⚪ Other person location unchanged (within 3m threshold)", type: "debug");
    }
  }

  bool _hasSignificantChangeDistance(LatLng oldLoc, LatLng newLoc, {double thresholdMeters = 5.0}) {
    final distance = Geolocator.distanceBetween(
      oldLoc.latitude,
      oldLoc.longitude,
      newLoc.latitude,
      newLoc.longitude,
    );
    return distance >= thresholdMeters;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _updateMarkers();
    if (_otherPersonLocation.value != null) {
      _getRoutePolyline();
    }
    _moveCameraToShowBoth();
  }

  Future<void> _getRoutePolyline() async {
    try {
      final myLoc = _myLocation.value;
      final otherPerson = _otherPersonLocation.value;

      if (myLoc == null || otherPerson == null) {
        Logger.log("🗺 Missing positions for route", type: "warning");
        return;
      }

      setState(() {
        _isLoadingRoute = true;
      });

      final origin = PointLatLng(myLoc.latitude, myLoc.longitude);
      final dest = PointLatLng(otherPerson.latitude, otherPerson.longitude);

      Logger.log("🗺 Fetching route...", type: "info");

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: origin,
          destination: dest,
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        setState(() {
          _polyPoints = result.points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
        });
        Logger.log("🗺 Route updated with ${_polyPoints.length} points", type: "success");
        _lastPolylineUpdate = DateTime.now();
      } else {
        Logger.log("⚠ No route points. Error: ${result.errorMessage}", type: "warning");
      }
    } on Exception catch (e) {
      Logger.log("❌ Route error: $e", type: "error");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _updateMarkers() {
    final myLoc = _myLocation.value;
    final otherPerson = _otherPersonLocation.value;

    Logger.log("🗺 Updating markers - My: ${myLoc != null}, Other: ${otherPerson != null}", type: "debug");

    final Set<Marker> newMarkers = {};

    String myLabel = "";
    String otherLabel = "";
    BitmapDescriptor myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    BitmapDescriptor otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    if (_currentMode == 'seeker') {
      myLabel = "You (Seeker)";
      otherLabel = "$_otherPersonName (Helper)";
      myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (_currentMode == 'giver') {
      myLabel = "You (Helper)";
      otherLabel = "$_otherPersonName (Seeker)";
      myColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      otherColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    // ✅ Use _myLocation.value — guaranteed fresh
    if (myLoc != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("my_location"),
          position: myLoc,
          infoWindow: InfoWindow(
            title: myLabel,
            snippet: "Current location",
          ),
          icon: myColor,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    if (otherPerson != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("other_person_location"),
          position: otherPerson,
          infoWindow: InfoWindow(
            title: otherLabel,
            snippet: "Distance: $_distanceText • ETA: $_etaText",
          ),
          icon: otherColor,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
      Logger.log("✅ Markers updated: ${newMarkers.length} markers", type: "success");
    }
  }

  void _updateRouteIfNeeded() {
    final now = DateTime.now();
    if (_lastPolylineUpdate == null ||
        now.difference(_lastPolylineUpdate!) > _polylineUpdateInterval) {
      if (_otherPersonLocation.value != null && _myLocation.value != null) {
        _getRoutePolyline();
      }
    }
  }

  Future<void> _moveCameraToShowBoth() async {
    final myLoc = _myLocation.value;
    final otherPos = _otherPersonLocation.value;

    if (mapController == null || myLoc == null) return;

    if (otherPos != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          myLoc.latitude < otherPos.latitude ? myLoc.latitude : otherPos.latitude,
          myLoc.longitude < otherPos.longitude ? myLoc.longitude : otherPos.longitude,
        ),
        northeast: LatLng(
          myLoc.latitude > otherPos.latitude ? myLoc.latitude : otherPos.latitude,
          myLoc.longitude > otherPos.longitude ? myLoc.longitude : otherPos.longitude,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 200));

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } else {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(myLoc, 16),
      );
    }
  }

  void _debugCurrentState() {
    Logger.log("=== DEBUG STATE ===", type: "info");
    Logger.log("Mode: $_currentMode", type: "info");
    Logger.log("Has Active Request: ${_hasActiveRequest()}", type: "info");
    Logger.log("Markers count: ${_markers.length}", type: "info");

    if (_currentMode == 'seeker' && _seekerController != null) {
      Logger.log("Seeker Controller:", type: "info");
      Logger.log("- giverPosition: ${_seekerController!.giverPosition.value}", type: "info");
      Logger.log("- otherPersonLatitude: ${_seekerController!.otherPersonLatitude}", type: "info");
      Logger.log("- otherPersonLongitude: ${_seekerController!.otherPersonLongitude}", type: "info");
      Logger.log("- hasActiveHelpRequest: ${_seekerController!.hasActiveHelpRequest}", type: "info");
    }

    if (_currentMode == 'giver' && _giverController != null) {
      Logger.log("Giver Controller:", type: "info");
      Logger.log("- seekerPosition: ${_giverController!.seekerPosition.value}", type: "info");
      Logger.log("- seekerLatitude: ${_giverController!.seekerLatitude}", type: "info");
      Logger.log("- seekerLongitude: ${_giverController!.seekerLongitude}", type: "info");
    }

    Logger.log("=== END DEBUG ===", type: "info");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentMode == 'seeker' ? "Tracking Helper"
              : _currentMode == 'giver' ? "Tracking Seeker"
              : "Map",
        ),
        actions: [
          if (_isLoadingRoute)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else if (_hasActiveRequest())
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.navigation, color: Colors.green),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _myLocation.value ?? const LatLng(23.8103, 90.4125),
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: false, // ✅ Disable blue dot to avoid confusion (optional)
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
                )
            },
          ),

          if (_hasActiveRequest())
            Positioned(
              bottom: -5,
              left: -5,
              right: -5,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _otherPersonName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  locationsController.sharingStatus,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.social_distance, color: Colors.blue),
                              const SizedBox(height: 4),
                              Text(
                                _distanceText,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Distance",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.access_time, color: Colors.orange),
                              const SizedBox(height: 4),
                              Text(
                                _etaText,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "ETA",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton.small(
            backgroundColor: Colors.red,
            onPressed: _debugCurrentState,
            child: const Icon(Icons.bug_report),
            tooltip: "Debug Info",
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: _moveCameraToShowBoth,
            child: const Icon(Icons.my_location),
            tooltip: "Center on route",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _otherPersonLocation.dispose();
    _myLocation.dispose();
    mapController?.dispose();
    super.dispose();
  }
}