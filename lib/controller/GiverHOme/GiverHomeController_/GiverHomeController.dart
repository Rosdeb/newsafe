import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/controller/UserController/userController.dart';
import 'package:saferader/utils/api_service.dart';
import 'package:saferader/utils/logger.dart';
import '../../../utils/app_constant.dart';
import '../../../utils/token_service.dart';
import '../../SeakerLocation/seakerLocationsController.dart';
import '../../SocketService/socket_service.dart';
import 'package:geolocator/geolocator.dart';

class GiverHomeController extends GetxController {
  RxInt emergencyMode = 0.obs;
  RxList<Map<String, dynamic>> pendingHelpRequests = <Map<String, dynamic>>[].obs;
  Rxn<Map<String, dynamic>> acceptedHelpRequest = Rxn<Map<String, dynamic>>();
  final UserController userController = Get.find<UserController>();
  Rxn<Position> seekerPosition = Rxn<Position>();
  SocketService? _socketService;
  SocketService? get socketService => _socketService;
  Position? get currentPosition {
    try {
      final locationController = Get.find<SeakerLocationsController>();
      return locationController.currentPosition.value;
    } catch (e) {
      return null;
    }
  }

  double? get seekerLatitude {
    if (seekerPosition.value != null) {
      return seekerPosition.value!.latitude;
    }


    if (acceptedHelpRequest.value != null) {
      final location = acceptedHelpRequest.value!['location'] as Map<String, dynamic>?;
      final coordinates = location?['coordinates'] as List<dynamic>?;

      if (coordinates != null && coordinates.length >= 2) {

        return (coordinates[1] as num).toDouble();
      }
    }

    return null;
  }

  double? get seekerLongitude {
    if (seekerPosition.value != null) {
      return seekerPosition.value!.longitude;
    }


    if (acceptedHelpRequest.value != null) {
      final location = acceptedHelpRequest.value!['location'] as Map<String, dynamic>?;
      final coordinates = location?['coordinates'] as List<dynamic>?;

      if (coordinates != null && coordinates.length >= 2) {

        return (coordinates[0] as num).toDouble();
      }
    }

    return null;
  }

  LatLng? get seekerLatLng {
    final lat = seekerLatitude;
    final lng = seekerLongitude;

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  String get seekerName {
    final seeker = acceptedHelpRequest.value?['seeker'] as Map<String, dynamic>?;
    return seeker?['name']?.toString() ?? 'Seeker';
  }

  @override
  void onInit() {
    super.onInit();
    _setupLocationListener();
    //initSocket();
  }

  void _setupLocationListener() {
    try {
      final locationController = Get.find<SeakerLocationsController>();


      ever(locationController.currentPosition, (position) {
        if (position != null) {
          _updateDistanceAndEta();
        }
      });

      Logger.log("📍 Location listener setup complete", type: "success");
    } catch (e) {
      Logger.log("❌ Error setting up location listener: $e", type: "error");
    }
  }

  Future<void> initSocket() async {
    try {
      final token = await TokenService().getToken();
      if (token == null || token.isEmpty) {
        Logger.log("❌ No token available for giver socket", type: "error");
        return;
      }

      final String role = 'giver';

      // Check if already initialized
      if (_socketService != null && _socketService!.isConnected.value) {
        Logger.log("✅ Giver socket already connected", type: "info");
        return;
      }

      Logger.log("🔄 Initializing giver socket...", type: "info");

      // Remove old instance if exists
      if (Get.isRegistered<SocketService>()) {
        // await Get.delete<SocketService>(force: true);
      }

      _socketService = await Get.putAsync(() => SocketService().init(token, role: role));

      if (_socketService != null) {
        _removeAllListeners();
        _setupSocketListeners();
        Logger.log("✅ Giver socket connected and ready", type: "success");
        Logger.log("🔍 Socket ID: ${_socketService!.socket.id}", type: "debug");
        Logger.log("🔍 Socket connected: ${_socketService!.isConnected.value}", type: "debug");

        // 🔥 NEW: Log all socket events for debugging
        _socketService!.socket.onAny((event, data) {
          Logger.log("🎯 [GIVER] Socket event received: $event", type: "debug");
          if (event == 'giver_receiveLocationUpdate') {
            Logger.log("   ⚠️⚠️⚠️ This is the location update event!", type: "warning");
          }
        });
      }

    } catch (e) {
      Logger.log("❌ Error initializing giver socket: $e", type: "error");
      Get.snackbar(
        "Connection Error",
        "Failed to connect to server",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _removeAllListeners() {
    socketService?.socket.off('giver_newHelpRequest');
    socketService?.socket.off('helpRequestAccepted');
    socketService?.socket.off('giver_receiveLocationUpdate');
    socketService?.socket.off('giver_helpRequestCancelled');
    socketService?.socket.off('giver_helpRequestCompleted');
    socketService?.socket.off('message');
  }

  void _setupSocketListeners() {
    if (!Get.isRegistered<GiverHomeController>()) return;

    Logger.log("🎧 [GIVER] Setting up socket listeners", type: "info");


    socketService?.socket.on('giver_newHelpRequest', (data) {
      if (!Get.isRegistered<GiverHomeController>()) return;
      Logger.log("🆘 NEW HELP REQUEST RECEIVED: $data", type: "info");
      _handleNewHelpRequest(data);
    });

    socketService?.socket.on('helpRequestAccepted', (data) {
      if (!Get.isRegistered<GiverHomeController>()) return;
      final userRole = userController.userRole.value;
         if (userRole != 'giver' && userRole != 'both') return;
      Logger.log("❤️ HELP REQUEST ACCEPTED RECEIVED: $data", type: "success");
      _handleHelpRequestAccepted(data);
    });


    socketService?.socket.on('giver_receiveLocationUpdate', (data) {
      if (!Get.isRegistered<GiverHomeController>()) return;
      Logger.log("📍📍📍 [GIVER] SEEKER LOCATION UPDATE RECEIVED!", type: "success");
      Logger.log("   Raw data: $data", type: "debug");
      Logger.log("   Data type: ${data.runtimeType}", type: "debug");
      handleSeekerLocationUpdate(data);
    });

    socketService?.socket.on('giver_helpRequestCancelled', (data) {
      if (!Get.isRegistered<GiverHomeController>()) return;
      Logger.log("⛔ HELP REQUEST CANCELLED EVENT FIRED!", type: "warning");
      _handleHelpRequestCancelled(data);
    });

    socketService?.socket.on('giver_helpRequestCompleted', (data) {
      if (!Get.isRegistered<GiverHomeController>()) return;
      Logger.log("✅ HELP REQUEST COMPLETED: $data", type: "success");
      _handleHelpRequestCompleted(data);
    });

    socketService?.socket.on('message', (data) {
      Logger.log("📢 Message: $data", type: "info");
    });
  }

  void handleSeekerLocationUpdate(dynamic data) {
    try {
      Logger.log("🔥 [GIVER] RAW SEEKER LOCATION DATA received", type: "info");
      Logger.log("   Data type: ${data.runtimeType}", type: "debug");
      Logger.log("   Data: $data", type: "debug");

      Map<String, dynamic> locationData;

      // Handle different data formats
      if (data is String) {
        Logger.log("📝 [GIVER] Parsing JSON string...", type: "debug");
        try {
          locationData = jsonDecode(data) as Map<String, dynamic>;
        } catch (e) {
          Logger.log("❌ [GIVER] Failed to parse JSON string: $e", type: "error");
          return;
        }
      } else if (data is Map) {
        locationData = Map<String, dynamic>.from(data);
      } else {
        Logger.log("❌ [GIVER] Unknown data format: ${data.runtimeType}", type: "error");
        Logger.log("   Expected: String or Map, Got: ${data.runtimeType}", type: "error");
        return;
      }

      // Log all keys for debugging
      Logger.log("📊 [GIVER] Location Data Keys: ${locationData.keys.toList()}", type: "debug");

      // Extract latitude/longitude - handle different formats
      dynamic latitudeRaw;
      dynamic longitudeRaw;

      // Try different possible key names
      latitudeRaw = locationData['latitude'] ??
          locationData['lat'] ??
          locationData['Latitude'] ??
          locationData['Lat'];

      longitudeRaw = locationData['longitude'] ??
          locationData['lng'] ??
          locationData['Longitude'] ??
          locationData['Lng'];

      Logger.log("📍 [GIVER] Raw values extracted", type: "debug");
      Logger.log("   Lat: $latitudeRaw (${latitudeRaw.runtimeType})", type: "debug");
      Logger.log("   Lng: $longitudeRaw (${longitudeRaw.runtimeType})", type: "debug");

      // Convert to double safely
      double? latitude = _safeToDouble(latitudeRaw);
      double? longitude = _safeToDouble(longitudeRaw);

      if (latitude == null || longitude == null) {
        Logger.log("❌ [GIVER] Could not parse latitude/longitude", type: "error");
        Logger.log("   Latitude raw: $latitudeRaw", type: "error");
        Logger.log("   Longitude raw: $longitudeRaw", type: "error");
        Logger.log("   Available keys: ${locationData.keys.toList()}", type: "debug");
        return;
      }

      // Validate coordinate ranges
      if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        Logger.log("❌ [GIVER] Invalid coordinate ranges", type: "error");
        Logger.log("   Lat: $latitude (valid: -90 to 90)", type: "error");
        Logger.log("   Lng: $longitude (valid: -180 to 180)", type: "error");
        return;
      }

      Logger.log("✅ [GIVER] Parsed location: ($latitude, $longitude)", type: "success");

      // Update seeker's position
      seekerPosition.value = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      Logger.log("✅ [GIVER] SEEKER POSITION UPDATED: ($latitude, $longitude)", type: "success");

      // Update distance and ETA
      _updateDistanceAndEta();

    } catch (e, stackTrace) {
      Logger.log("❌ [GIVER] ERROR in handleSeekerLocationUpdate: $e", type: "error");
      Logger.log("   Error type: ${e.runtimeType}", type: "error");
      Logger.log("   Stack trace: $stackTrace", type: "error");
      Logger.log("   Data received: $data", type: "debug");
    }
  }

  double? _safeToDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }

    try {
      return double.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  void _updateDistanceAndEta() {
    try {
      final myPos = currentPosition; // Getter ব্যবহার করছি
      final seekerPos = seekerPosition.value;

      if (myPos != null && seekerPos != null && acceptedHelpRequest.value != null) {
        final distance = Geolocator.distanceBetween(
          myPos.latitude,
          myPos.longitude,
          seekerPos.latitude,
          seekerPos.longitude,
        );

        // Update the accepted request with new distance
        final updatedRequest = Map<String, dynamic>.from(acceptedHelpRequest.value!);
        updatedRequest['distance'] = '${(distance / 1000).toStringAsFixed(2)} km';

        // Calculate ETA (assuming average speed of 30 km/h)
        final etaMinutes = (distance / 1000) / 30 * 60;
        updatedRequest['eta'] = '${etaMinutes.toStringAsFixed(0)} min';

        acceptedHelpRequest.value = updatedRequest;

        Logger.log("📊 Distance: ${updatedRequest['distance']}, ETA: ${updatedRequest['eta']}", type: "info");
      }
    } catch (e) {
      Logger.log("❌ Error updating distance/ETA: $e", type: "error");
    }
  }

  Future<void> acceptHelpRequest(String requestId) async {
    try {
      final requestIndex = pendingHelpRequests.indexWhere((req) => req['_id'] == requestId);
      if (requestIndex == -1) {
        Logger.log("[GIVER] Request not found: $requestId", type: "error");
        return;
      }

      final acceptedRequest = pendingHelpRequests[requestIndex];
      acceptedHelpRequest.value = acceptedRequest;
      pendingHelpRequests.removeAt(requestIndex);
      emergencyMode.value = 2;

      Logger.log("📤 [GIVER] Emitting acceptHelpRequest event", type: "info");
      socketService!.socket.emit('acceptHelpRequest', requestId);

      Logger.log("🚪 [GIVER] Joining room: $requestId", type: "info");
      await socketService!.joinRoom(requestId);
      await Future.delayed(const Duration(milliseconds: 500));

      // Get or create location controller
      SeakerLocationsController locationController;
      if (Get.isRegistered<SeakerLocationsController>()) {
        locationController = Get.find<SeakerLocationsController>();
        Logger.log("✅ [GIVER] Using existing location controller", type: "info");
      } else {
        locationController = Get.put(SeakerLocationsController());
        Logger.log("✅ [GIVER] Created new location controller", type: "info");
      }

      // 🔥 STEP 1: Complete cleanup
      Logger.log("🧹 [GIVER] Step 1: Complete cleanup...", type: "info");
      locationController.stopLocationSharing();
      locationController.clearHelpRequestId();

      // 🔥 Wait for cleanup to complete
      await Future.delayed(const Duration(milliseconds: 800));

      // 🔥 STEP 2: Set new request ID
      Logger.log("🆔 [GIVER] Step 2: Setting request ID: $requestId", type: "info");
      locationController.setHelpRequestId(requestId);
      locationController.forceSocketRefresh();

      await Future.delayed(const Duration(milliseconds: 300));

      // 🔥 STEP 3: Reset flag
      Logger.log("🔄 [GIVER] Step 3: Resetting first location flag...", type: "info");
      locationController.resetFirstLocationFlag();

      // 🔥 STEP 4: Start location sharing flag FIRST
      Logger.log("🚀 [GIVER] Step 4: Starting location sharing flag...", type: "info");
      locationController.startLocationSharing();

      await Future.delayed(const Duration(milliseconds: 200));

      // 🔥 STEP 5: Start live location stream
      Logger.log("📍 [GIVER] Step 5: Starting FRESH live location stream...", type: "info");
      await locationController.startLiveLocation();

      // 🔥 Wait for first position
      await Future.delayed(const Duration(milliseconds: 1500));

      // 🔥 STEP 6: Get initial position if needed
      if (locationController.currentPosition.value == null) {
        Logger.log("📍 [GIVER] Step 6: Getting initial position...", type: "info");
        await locationController.getUserLocationOnce();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 🔥 STEP 7: Force immediate share
      if (locationController.currentPosition.value != null) {
        Logger.log("📤 [GIVER] Step 7: Forcing immediate location share...", type: "info");
        locationController.shareCurrentLocation();

        // 🔥 Send one more time after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (locationController.isSharingLocation.value) {
          locationController.shareCurrentLocation();
          Logger.log("📤 [GIVER] Second immediate share sent", type: "info");
        }
      }

      // 🔥 STEP 8: Verification
      await Future.delayed(const Duration(milliseconds: 500));

      Logger.log("=== VERIFICATION ===", type: "info");
      Logger.log("✓ Sharing: ${locationController.isSharingLocation.value}", type: "info");
      Logger.log("✓ Live: ${locationController.liveLocation.value}", type: "info");
      Logger.log("✓ HelpID: ${locationController.currentHelpRequestId.value}", type: "info");
      Logger.log("✓ Position: ${locationController.currentPosition.value != null}", type: "info");
      Logger.log("✓ Socket: ${locationController.getActiveSocket() != null}", type: "info");

      final status = locationController.getLocationSharingStatus();
      Logger.log("✓ Status: $status", type: "info");
      Logger.log("==================", type: "info");

      if (locationController.isSharingLocation.value &&
          locationController.liveLocation.value &&
          locationController.currentPosition.value != null) {
        Logger.log("✅✅✅ [GIVER] Location sharing FULLY ACTIVE!", type: "success");

      } else {
        Logger.log("⚠️ [GIVER] Location sharing partially active", type: "warning");

        // One more recovery attempt
        if (locationController.currentPosition.value != null) {
          Logger.log("🔄 [GIVER] Final recovery attempt...", type: "warning");
          locationController.shareCurrentLocation();
        }

      }

    } catch (e, stackTrace) {
      Logger.log("❌ [GIVER] Error: $e", type: "error");
      Logger.log("Stack: $stackTrace", type: "error");

    }
  }

  void declineHelpRequest(String requestId) {
    try {
      Logger.log("📤 Declining help request: $requestId", type: "info");
      socketService?.declineHelpRequest(requestId);

      // Remove from pending list
      pendingHelpRequests.removeWhere((req) => req['_id'] == requestId);

      if (pendingHelpRequests.isEmpty && acceptedHelpRequest.value == null) {
        emergencyMode.value = 0;
        Logger.log("⚪ Emergency mode reset to 0", type: "info");
      }

      Logger.log("✅ Request declined", type: "success");
    } catch (e) {
      Logger.log("❌ Error declining help request: $e", type: "error");
    }
  }

  void cancelAcceptedRequest(String requestId) {
    try {
      Logger.log("📤 [GIVER] Cancelling accepted request: $requestId", type: "info");

      // 🔥 FIX: Stop location sharing FIRST
      final locationController = Get.find<SeakerLocationsController>();
      locationController.stopLocationSharing();
      locationController.clearHelpRequestId();

      // Then cleanup state
      acceptedHelpRequest.value = null;
      seekerPosition.value = null;
      emergencyMode.value = 0;

      socketService?.leaveRoom(requestId);
      socketService?.socket.emit('cancelAcceptedRequest', requestId);

      Logger.log("✅ [GIVER] Cancelled accepted request", type: "success");
      Get.snackbar("Cancelled", "You've cancelled helping this person");

    } on Exception catch (e, stackTrace) {
      Logger.log("❌ [GIVER] Error cancelling: $e", type: "error");
    }
  }

  void leaveHelpRequestRoom(String helpRequestId) {
    try {
      Logger.log("🚪 [GIVER] Leaving room: $helpRequestId", type: "info");

      // 🔥 FIX: Stop location sharing FIRST
      final locationController = Get.find<SeakerLocationsController>();
      locationController.stopLocationSharing();
      locationController.clearHelpRequestId();

      // Then cleanup state
      acceptedHelpRequest.value = null;
      seekerPosition.value = null;
      emergencyMode.value = 0;

      if (socketService != null && socketService!.isConnected.value) {
        socketService!.socket.emit('leaveHelpRequestRoom', helpRequestId);
      }

      Logger.log("✅ [GIVER] Left room successfully", type: "success");
    } catch (e) {
      Logger.log("❌ [GIVER] Error leaving room: $e", type: "error");
    }
  }

  void markWorkDone(String requestId) {
    try {
      Logger.log("📤 [GIVER] Marking work as done: $requestId", type: "info");

      // 🔥 FIX: Stop location sharing FIRST
      final locationController = Get.find<SeakerLocationsController>();
      locationController.stopLocationSharing();
      locationController.clearHelpRequestId();

      // Then cleanup state
      acceptedHelpRequest.value = null;
      seekerPosition.value = null;
      emergencyMode.value = 0;

      socketService?.leaveRoom(requestId);
      socketService?.socket.emit('completeHelpRequest', requestId);

      if (socketService != null && socketService!.isConnected.value) {
        socketService!.socket.emit('leaveHelpRequestRoom', requestId);
      }

      Logger.log("✅ [GIVER] Work marked as done", type: "success");

    } on Exception catch (e, stackTrace) {
      Logger.log("❌ [GIVER] Error marking work done: $e", type: "error");
    }
  }

  void _handleNewHelpRequest(dynamic data) {
    try {
      Logger.log("🔥 Processing new help request", type: "info");

      final request = data as Map<String, dynamic>;

      // Add to pending requests list
      pendingHelpRequests.add(request);
      emergencyMode.value = 1;
      Logger.log("✅ Help request added. Total pending: ${pendingHelpRequests.length}", type: "success");

      // Optional: Show notification or update UI
      Get.snackbar(
        "New Help Request",
        "${request['seeker']?['name'] ?? 'Someone'} needs help!",
        snackPosition: SnackPosition.TOP,
      );

    } catch (e) {
      Logger.log("❌ Error handling new help request: $e", type: "error");
    }
  }

  void _handleHelpRequestAccepted(dynamic data) {
    try {
      final requestId = data['_id'] ?? data['helpRequestId'];

      // Remove from pending requests if it's there
      pendingHelpRequests.removeWhere((req) => req['_id'] == requestId);

      Logger.log("✅ Request accepted and removed from pending list", type: "success");

    } catch (e) {
      Logger.log("❌ Error handling accepted request: $e", type: "error");
    }
  }

  void _handleHelpRequestCancelled(dynamic data) {
    try {
      final requestId = data['_id'] ?? data['helpRequestId'];

      // Remove from pending requests
      pendingHelpRequests.removeWhere((req) => req['_id'] == requestId);

      // Also check if it's the accepted request
      if (acceptedHelpRequest.value?['_id'] == requestId) {
        acceptedHelpRequest.value = null;
        seekerPosition.value = null;
        emergencyMode.value = 0;
      }

      if (pendingHelpRequests.isEmpty && acceptedHelpRequest.value == null) {
        emergencyMode.value = 0;
      }

      Logger.log("✅ Cancelled request removed from list", type: "success");

    } catch (e) {
      Logger.log("❌ Error handling cancelled request: $e", type: "error");
    }
  }

  void _handleHelpRequestCompleted(dynamic data) {
    try {
      final requestId = data['_id'] ?? data['helpRequestId'];

      // Remove from pending requests
      pendingHelpRequests.removeWhere((req) => req['_id'] == requestId);

      // Also check if it's the accepted request
      if (acceptedHelpRequest.value?['_id'] == requestId) {
        acceptedHelpRequest.value = null;
        seekerPosition.value = null;
        emergencyMode.value = 0;
      }

      Logger.log("✅ Completed request removed from list", type: "success");

    } catch (e) {
      Logger.log("❌ Error handling completed request: $e", type: "error");
    }
  }

  RxBool helperStatus = false.obs;

  Future<void> updateAvailability(bool isAvailable) async {
    try {
      Logger.log("📤 Updating availability → $isAvailable", type: "info");

      final availabilityResponse = await ApiService.put('/api/users/me/availability',
        body: {'isAvailable': isAvailable}
      ).timeout(const Duration(seconds: 10));

      if (availabilityResponse.statusCode != 200) {
        final err = jsonDecode(availabilityResponse.body);
        final message = err["message"] ?? "Failed to update availability";
        Logger.log("❌ Failed: $message", type: "error");
        return;
      }

      helperStatus.value = isAvailable;
      Logger.log("✅ Availability updated", type: "success");

      if (!isAvailable) {
        _stopLocationSharing();
        return;
      }

      final locationController = Get.find<SeakerLocationsController>();

      // 🔥 IMPORTANT: Start live location BEFORE updating server location
      if (!locationController.liveLocation.value) {
        await locationController.startLiveLocation();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final currentPos = locationController.currentPosition.value;

      if (currentPos != null) {
        // Update location on server
        final locationResponse = await ApiService.put('/api/users/me/location',
          body: {
            'latitude': currentPos.latitude,
            'longitude': currentPos.longitude,
          }
        ).timeout(const Duration(seconds: 10));

        if (locationResponse.statusCode == 200) {
          Logger.log("✅ Location updated on server", type: "success");
        }
      }

      // Start location sharing (but don't require socket connection)
      locationController.startLocationSharing();
      Logger.log("📡 Location sharing enabled", type: "success");

    } catch (e) {
      Logger.log("❌ Error updating availability: $e", type: "error");
    }
  }

  void _stopLocationSharing() {
    try {
      final locationController = Get.find<SeakerLocationsController>();
      locationController.stopLocationSharing();
      Logger.log("📍 Stopped location sharing", type: "info");
    } catch (e) {
      Logger.log("❌ Error stopping location: $e", type: "error");
    }
  }

  void removeAllListeners() {
    socketService?.socket.off('giver_newHelpRequest');
    socketService?.socket.off('helpRequestAccepted');
    socketService?.socket.off('giver_receiveLocationUpdate');
    socketService?.socket.off('giver_helpRequestCancelled');
    socketService?.socket.off('giver_helpRequestCompleted');
    socketService?.socket.off('connect');
    socketService?.socket.off('disconnect');
  }

  void debugGiverConnection() {
    Logger.log("=== GIVER CONNECTION DEBUG ===", type: "info");
    Logger.log("📡 Socket Status:", type: "info");
    Logger.log("  - Socket service exists: ${socketService != null}", type: "info");
    Logger.log("  - Socket connected: ${socketService?.isConnected.value ?? false}", type: "info");
    Logger.log("  - Socket ID: ${socketService?.socket.id ?? 'N/A'}", type: "info");
    Logger.log("  - Current room: ${socketService?.currentRoom ?? 'Not in room'}", type: "info");

    Logger.log("📍 Request Status:", type: "info");
    Logger.log("  - Has accepted request: ${acceptedHelpRequest.value != null}", type: "info");
    if (acceptedHelpRequest.value != null) {
      Logger.log("  - Request ID: ${acceptedHelpRequest.value?['_id']}", type: "info");
      Logger.log("  - Seeker name: ${acceptedHelpRequest.value?['seeker']?['name']}", type: "info");
    }

    Logger.log("📊 Location Status:", type: "info");
    Logger.log("  - Has seeker position: ${seekerPosition.value != null}", type: "info");
    if (seekerPosition.value != null) {
      Logger.log("  - Seeker position: (${seekerPosition.value!.latitude}, ${seekerPosition.value!.longitude})", type: "info");
    }

    Logger.log("  - My position: ${currentPosition != null ? '(${currentPosition!.latitude}, ${currentPosition!.longitude})' : 'N/A'}", type: "info");

    Logger.log("🎧 Testing event reception:", type: "info");
    Logger.log("  - Listeners should be active for: giver_receiveLocationUpdate", type: "info");

    Logger.log("=== END DEBUG ===", type: "info");

    // Test if we can emit an event
    if (socketService?.isConnected.value == true) {
      Logger.log("📤 Sending test ping to server...", type: "info");
      socketService!.socket.emit('ping', {'from': 'giver', 'timestamp': DateTime.now().toIso8601String()});
    }
  }

  @override
  void onClose() {
    if (socketService?.isConnected.value == true) {
      socketService!.socket.disconnect();
      Logger.log("🔌 [GIVER] Socket disconnected", type: "info");
    }
    removeAllListeners();
    seekerPosition.value = null;
    super.onClose();
  }

  void refreshSocketOnResume() {
    // This method can be called when the app resumes
    // to ensure the socket is properly connected and in the right room
    if (socketService != null) {
      final helpRequestId = acceptedHelpRequest.value?['_id']?.toString();
      if (helpRequestId != null && helpRequestId.isNotEmpty) {
        if (!socketService!.isConnected.value) {
          // Reconnect the socket if needed
          initSocket();
        } else {
          // Ensure we're in the right room
          socketService!.joinRoom(helpRequestId);
        }
      }
    }
  }

}