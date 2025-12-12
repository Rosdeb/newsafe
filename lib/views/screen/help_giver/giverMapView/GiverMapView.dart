// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:saferader/controller/SeakerLocation/seakerLocationsController.dart';
// import 'package:get/get.dart';
// import 'package:saferader/utils/app_constant.dart';
// import 'package:saferader/utils/logger.dart';
// import '../../../../controller/GiverHOme/GiverHomeController /GiverHomeController.dart';
//
//
// class GiverMapView extends StatefulWidget {
//   @override
//   _GiverMapViewState createState() => _GiverMapViewState();
// }
//
// class _GiverMapViewState extends State<GiverMapView> {
//   GoogleMapController? mapController;
//   final locationsController = Get.find<SeakerLocationsController>();
//   final giverController = Get.find<GiverHomeController>();
//
//   final RxSet<Marker> markers = <Marker>{}.obs;
//   final RxList<LatLng> polyPoints = <LatLng>[].obs;
//   final RxBool isLoadingRoute = false.obs;
//
//   final PolylinePoints polylinePoints = PolylinePoints(apiKey: AppConstants.Secret_key);
//   DateTime? lastPolylineUpdate;
//   static const Duration polylineUpdateInterval = Duration(seconds: 10);
//
//   @override
//   void initState() {
//     super.initState();
//     _setupListeners();
//     _initializeMap();
//   }
//
//   void _setupListeners() {
//     // ✅ যখন seeker move করবে
//     ever(giverController.seekerPosition, (position) {
//       if (position != null) {
//         Logger.log("🗺️ Seeker moved!", type: "info");
//         _updateMarkers();      // Markers update করো
//         _updateRouteIfNeeded(); // Route update করো
//         _moveCameraToShowBoth(); // Camera adjust করো
//       }
//     });
//
//     // ✅ যখন giver move করবে
//     ever(locationsController.currentPosition, (pos) {
//       if (pos != null) {
//         _updateMarkers();
//         _updateRouteIfNeeded();
//         _moveCameraToShowBoth();
//       }
//     });
//   }
//
//   void _initializeMap() {
//     if (giverController.acceptedHelpRequest.value != null) {
//       _updateMarkers();
//       Future.delayed(Duration(milliseconds: 500), () {
//         getRoutePolyline();
//       });
//     }
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//     _updateMarkers();
//
//     if (giverController.seekerPosition.value != null) {
//       getRoutePolyline();
//     }
//
//     _moveCameraToShowBoth();
//   }
//
//   Future<void> getRoutePolyline() async {
//     final myPos = locationsController.currentPosition.value;
//     final seekerPos = giverController.seekerPosition.value;
//
//     if (myPos == null || seekerPos == null) return;
//
//     // ✅ Origin এবং Destination set করো
//     final origin = PointLatLng(myPos.latitude, myPos.longitude);
//     final dest = PointLatLng(seekerPos.latitude, seekerPos.longitude);
//
//     // ✅ Google Directions API call করো
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       request: PolylineRequest(
//         origin: origin,
//         destination: dest,
//         mode: TravelMode.driving,
//       ),
//     );
//
//     if (result.points.isNotEmpty) {
//       // ✅ Route points save করো
//       polyPoints.value = result.points
//           .map((p) => LatLng(p.latitude, p.longitude))
//           .toList();
//     }
//   }
//
//   void _updateMarkers() {
//     // ✅ Giver এর position নাও
//     final myPos = locationsController.currentPosition.value;
//
//     // ✅ Seeker এর position নাও
//     final seekerPos = giverController.seekerPosition.value;
//
//     Set<Marker> newMarkers = {};
//
//     // ✅ Giver এর marker (সবুজ)
//     if (myPos != null) {
//       newMarkers.add(
//         Marker(
//           markerId: MarkerId("giver_location"),
//           position: LatLng(myPos.latitude, myPos.longitude),
//           infoWindow: InfoWindow(title: "You (Helper)"),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueGreen // 🟢 সবুজ marker
//           ),
//         ),
//       );
//     }
//
//     // ✅ Seeker এর marker (লাল)
//     if (seekerPos != null) {
//       newMarkers.add(
//         Marker(
//           markerId: MarkerId("seeker_location"),
//           position: LatLng(seekerPos.latitude, seekerPos.longitude),
//           infoWindow: InfoWindow(title: "${giverController.seekerName} (Seeker)"),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueRed // 🔴 লাল marker
//           ),
//         ),
//       );
//     }
//
//     // ✅ Markers set করো
//     markers.value = newMarkers;
//   }
//
//   void _updateRouteIfNeeded() {
//     final now = DateTime.now();
//     if (lastPolylineUpdate == null ||
//         now.difference(lastPolylineUpdate!) > polylineUpdateInterval) {
//       getRoutePolyline();
//       lastPolylineUpdate = now;
//     }
//   }
//
//   void _moveCameraToShowBoth() async {
//     final myPos = locationsController.currentPosition.value;
//     final seekerPos = giverController.seekerPosition.value;
//
//     if (mapController == null) return;
//
//     if (myPos != null && seekerPos != null) {
//       LatLngBounds bounds;
//
//       try {
//         bounds = LatLngBounds(
//           southwest: LatLng(
//             myPos.latitude < seekerPos.latitude ? myPos.latitude : seekerPos.latitude,
//             myPos.longitude < seekerPos.longitude ? myPos.longitude : seekerPos.longitude,
//           ),
//           northeast: LatLng(
//             myPos.latitude > seekerPos.latitude ? myPos.latitude : seekerPos.latitude,
//             myPos.longitude > seekerPos.longitude ? myPos.longitude : seekerPos.longitude,
//           ),
//         );
//       } catch (e) {
//         double lat = myPos.latitude;
//         double lng = myPos.longitude;
//         bounds = LatLngBounds(
//           southwest: LatLng(lat - 0.001, lng - 0.001),
//           northeast: LatLng(lat + 0.001, lng + 0.001),
//         );
//       }
//
//       await Future.delayed(Duration(milliseconds: 200));
//
//       mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 100),
//       );
//     } else if (myPos != null) {
//       mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(myPos.latitude, myPos.longitude),
//           16,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Tracking ${giverController.seekerName}"),
//         backgroundColor: Colors.green,
//         actions: [
//           Obx(() {
//             if (isLoadingRoute.value) {
//               return const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 ),
//               );
//             }
//
//             if (giverController.seekerPosition.value != null) {
//               return const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Icon(Icons.navigation, color: Colors.white),
//               );
//             }
//
//             return const SizedBox.shrink();
//           }),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Obx(() {
//             return GoogleMap(
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: CameraPosition(
//                 target: LatLng(
//                   locationsController.currentPosition.value?.latitude ?? 23.8103,
//                   locationsController.currentPosition.value?.longitude ?? 90.4125,
//                 ),
//                 zoom: 15,
//               ),
//               markers: markers.toSet(),
//               myLocationEnabled: true,
//               myLocationButtonEnabled: true,
//               trafficEnabled: true,
//               polylines: giverController.seekerPosition.value != null
//                   ? {
//                 Polyline(
//                   polylineId: PolylineId("route_to_seeker"),
//                   points: polyPoints,
//                   width: 5,
//                   color: Colors.blue,
//                   patterns: [
//                     PatternItem.dash(30),
//                     PatternItem.gap(10),
//                   ],
//                 )
//               }
//                   : {},
//             );
//           }),
//
//           // Info card
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Obx(() {
//               if (giverController.acceptedHelpRequest.value == null) {
//                 return const SizedBox.shrink();
//               }
//
//               final request = giverController.acceptedHelpRequest.value!;
//               final seeker = request['seeker'] as Map<String, dynamic>?;
//               final seekerName = seeker?['name'] ?? 'Seeker';
//               final seekerImage = seeker?['profileImage'] ?? '';
//               final distance = request['distance']?.toString() ?? 'Calculating...';
//               final eta = request['eta']?.toString() ?? 'Calculating...';
//
//               return Card(
//                 elevation: 8,
//                 margin: EdgeInsets.zero,
//                 shape: RoundedRectangleBorder(
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
//                           CircleAvatar(
//                             backgroundImage: NetworkImage(seekerImage),
//                             radius: 25,
//                             onBackgroundImageError: (_, __) {},
//                             child: seekerImage.isEmpty
//                                 ? Icon(Icons.person)
//                                 : null,
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "$seekerName needs help",
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 Obx(() {
//                                   final isSharing = locationsController.isSharingLocation.value;
//                                   return Text(
//                                     isSharing ? "Sharing location with seeker" : "Not sharing location",
//                                     style: TextStyle(
//                                       color: isSharing ? Colors.green : Colors.grey[600],
//                                       fontSize: 12,
//                                     ),
//                                   );
//                                 }),
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
//                                 distance,
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
//                                 eta,
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
//                           Obx(() {
//                             final seekerLastUpdate = giverController.seekerPosition.value?.timestamp;
//                             String statusText = "Waiting...";
//                             Color statusColor = Colors.grey;
//
//                             if (seekerLastUpdate != null) {
//                               final diff = DateTime.now().difference(seekerLastUpdate);
//                               if (diff.inSeconds < 10) {
//                                 statusText = "Live";
//                                 statusColor = Colors.green;
//                               } else if (diff.inSeconds < 30) {
//                                 statusText = "${diff.inSeconds}s ago";
//                                 statusColor = Colors.orange;
//                               } else {
//                                 statusText = "Offline";
//                                 statusColor = Colors.red;
//                               }
//                             }
//
//                             return Column(
//                               children: [
//                                 Icon(Icons.wifi, color: statusColor),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   statusText,
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: statusColor,
//                                   ),
//                                 ),
//                                 Text(
//                                   "Status",
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             );
//                           }),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.green,
//         shape: const CircleBorder(),
//         onPressed: () {
//           _moveCameraToShowBoth();
//         },
//         child: Icon(Icons.my_location, color: Colors.white),
//         tooltip: "Center on route",
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     mapController?.dispose();
//     super.dispose();
//   }
// }