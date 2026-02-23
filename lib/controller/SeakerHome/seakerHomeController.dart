import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/api_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:vibration/vibration.dart';
import '../../../Models/HelpRequestResponse.dart';
import '../../../controller/SeakerLocation/seakerLocationsController.dart';
import '../../../controller/SocketService/socket_service.dart';
import '../../../controller/UserController/userController.dart';
import '../../../controller/networkService/networkService.dart';
import '../../../utils/app_constant.dart';
import '../../utils/auth_service.dart';
import '../notifications/notifications_controller.dart';

class SeakerHomeController extends GetxController {
  final userController = Get.find<UserController>();
  RxBool isSearching = false.obs;
  RxBool isLoading1 = false.obs;

  SocketService? socketService;
  RxBool isSocketInitialized = false.obs;
  RxInt emergencyMode = 0.obs;
  Rx<NearbyStats> nearbyStats = NearbyStats(km1: 0, km2: 0).obs;
  Rxn<Position> giverPosition = Rxn<Position>();

  RxBool helperStatus = false.obs;
  RxBool isSharingLocation = false.obs;
  RxString distance = 'Calculating...'.obs;
  RxString eta = 'Calculating...'.obs;

  Rxn<Map<String, dynamic>> activeHelpRequest = Rxn<Map<String, dynamic>>();
  RxList<Map<String, dynamic>> incomingHelpRequests = <Map<String, dynamic>>[].obs;
  RxString currentHelpRequestId = ''.obs;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  RxBool isReconnecting = false.obs;

  RxString userName1 = ''.obs;
  RxString userEmail1 = ''.obs;
  RxString userPhone1 = ''.obs;
  RxString userId1 = ''.obs;
  RxString userRole1 = ''.obs;
  RxString emails1 = ''.obs;
  RxString genders1 = ''.obs;
  RxString phones1 = ''.obs;
  RxString dateOfBirth1 = ''.obs;
  RxString profileImage11 = ''.obs;
  RxString firstName1 = ''.obs;
  RxString lastName1 = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setupLocationListener();
    initSocket();
    loadUserData();
    fetchUserProfile();
    fetchProfileImage();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading1.value = true;
      Logger.log("🌐 Fetching profile image from API...", type: "info");

      final response = await ApiService.get('/api/users/me');

      Logger.log("📥 Status: ${response.statusCode}", type: "info");

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;

        // API wraps user inside "data"
        final user = (body['data'] ?? body) as Map<String, dynamic>;

        final imageUrl = user['profileImage']?.toString() ?? '';
        if (imageUrl.isNotEmpty) {
          profileImage11.value = imageUrl;
          Logger.log(
            "✅ Profile image loaded from API: $imageUrl",
            type: "info",
          );
        }
      } else {
        Logger.log(
          "⚠ Failed to fetch profile: ${response.statusCode}",
          type: "warning",
        );
      }
    } catch (e) {
      Logger.log(" Error fetching profile image: $e", type: "error");
    } finally {
      isLoading1.value = false;
    }
  }

  RxString profileImage1111 = ''.obs;

  Future<void> fetchProfileImage() async {
    try {
      final response = await ApiService.get('/api/users/me');
      Logger.log("📥 Status: ${response.statusCode}", type: "info");
      Logger.log("📥 Body: ${response.body}", type: "info");

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final user = (body['data'] ?? body) as Map<String, dynamic>;
        Logger.log("👤 User keys: ${user.keys.toList()}", type: "info");
        Logger.log(
          " profileImage value: ${user['profileImage']}",
          type: "info",
        );

        final imageUrl = user['profileImage']?.toString() ?? '';
        if (imageUrl.isNotEmpty) {
          profileImage11.value = imageUrl;
          Logger.log("profileImage11 set to: $imageUrl", type: "info");
        } else {
          Logger.log(" profileImage is empty or null", type: "warning");
        }
      }
    } catch (e) {
      Logger.log("Error fetching profile image: $e", type: "error");
    }
  }

  void _setupLocationListener() {
    try {
      final locationController = Get.find<SeakerLocationsController>();

      // When seeker's location updates, recalculate distance/ETA
      ever(locationController.currentPosition, (position) {
        if (position != null && giverPosition.value != null) {
          _updateDistanceAndEta();
        }
      });

      Logger.log("📍 Seeker location listener setup complete", type: "success");
    } catch (e) {
      Logger.log("❌ Error setting up location listener: $e", type: "error");
    }
  }

  void _updateDistanceAndEta() {
    try {
      final locationController = Get.find<SeakerLocationsController>();
      final myPos = locationController.currentPosition.value;
      final helperPos = giverPosition.value;

      if (myPos != null && helperPos != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          myPos.latitude,
          myPos.longitude,
          helperPos.latitude,
          helperPos.longitude,
        );

        // Update distance
        distance.value = '${(distanceInMeters / 1000).toStringAsFixed(2)} km';

        // Calculate ETA (assuming average speed of 30 km/h)
        final etaMinutes = (distanceInMeters / 1000) / 30 * 60;
        eta.value = '${etaMinutes.toStringAsFixed(0)} min';

        Logger.log("📊 Distance: $distance, ETA: $eta", type: "info");
      }
    } catch (e) {
      Logger.log("❌ Error updating distance/ETA: $e", type: "error");
    }
  }

  Future<void> _attemptReconnect() async {
    if (isReconnecting.value || _reconnectAttempts >= _maxReconnectAttempts) {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        Logger.log(" Max reconnection attempts reached", type: "error");
        Get.snackbar(
          "Connection Error",
          "Unable to connect to server. Please restart the app.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
      return;
    }

    isReconnecting.value = true;
    _reconnectAttempts++;

    Logger.log(
      "🔄 Reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts",
      type: "warning",
    );

    try {
      final networkController = Get.find<NetworkController>();
      if (!networkController.isOnline.value) {
        Logger.log("📵 No internet connection", type: "error");
        isReconnecting.value = false;
        _scheduleReconnect();
        return;
      }

      await initSocket();

      if (socketService?.isConnected.value == true) {
        Logger.log(
          "✅ Reconnection successful (socket connected)",
          type: "success",
        );
        _reconnectAttempts = 0;
        isReconnecting.value = false;
      } else {
        Logger.log("❌ Reconnection failed, scheduling retry", type: "warning");
        isReconnecting.value = false;
        _scheduleReconnect();
      }
    } catch (e) {
      Logger.log(" Reconnection error: $e", type: "error");
      isReconnecting.value = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _attemptReconnect();
    });
  }

  void refreshSocketOnResume() {
    // This method can be called when the app resumes
    // to ensure the socket is properly connected and in the right room
    if (socketService != null && currentHelpRequestId.value.isNotEmpty) {
      if (!socketService!.isConnected.value) {
        // Reconnect the socket if needed
        _attemptReconnect();
      } else {
        // Ensure we're in the right room
        socketService!.joinRoom(currentHelpRequestId.value);
      }
    }
  }

  Future<void> initSocket() async {
    try {
      final token = await TokenService().getToken();
      if (token == null || token.isEmpty) return;

      final String role = userController.userRole.value;


      if (Get.isRegistered<SocketService>()) {
        final existing = Get.find<SocketService>();
        if (existing.isConnected.value) {
          socketService = existing;
          existing.updateRole(role);
          _setupSocketListeners();
          isSocketInitialized.value = true;
          return;
        }
      }

      // Initialize socket
      Logger.log("🔄 Initializing socket for role: $role", type: "info");
      socketService = await Get.putAsync(
        () => SocketService().init(token, role: role),
        permanent: true
      );
      if (socketService != null) {
        _setupSocketListeners();
        isSocketInitialized.value = true;

        socketService!.socket.onDisconnect((_) {
          Logger.log("⚡ [SEEKER] Socket disconnected! Reconnecting...", type: "warning");
          Future.delayed(const Duration(seconds: 3), () {
            if (Get.isRegistered<SeakerHomeController>()) {
              _attemptReconnect();
            }
          });
        });

        socketService!.socket.onConnect((_) {
          Logger.log("✅ [SEEKER] Socket reconnected!", type: "success");
          _rejoinRoomAfterReconnect();
        });

        Logger.log("✅ Socket initialized successfully", type: "success");
      }
    } catch (e) {
      Logger.log(" Error initializing socket: $e", type: "error");
      isSocketInitialized.value = false;
    }
  }

  void _rejoinRoomAfterReconnect() {
    final requestId = currentHelpRequestId.value;
    if (requestId.isNotEmpty) {
      Logger.log("🚪 [SEEKER] Rejoining room after reconnect: $requestId", type: "info");
      Future.delayed(const Duration(milliseconds: 500), () {
        socketService?.joinRoom(requestId);
        // ✅ Use Get.find instead of top-level getter
        try {
          final locCtrl = Get.find<SeakerLocationsController>();
          if (!locCtrl.isSharingLocation.value) {
            _startAutoLocationSharing();
          }
        } catch (e) {
          Logger.log("❌ Error resuming location: $e", type: "error");
        }
      });
    }
  }

  void removeAllListeners() {
    socketService?.socket.off('newHelpRequest');
    socketService?.socket.off('helpRequestAccepted');
    socketService?.socket.off('receiveLocationUpdate');
    socketService?.socket.off('helpRequestCancelled');
    socketService?.socket.off('helpRequestCompleted');
    socketService?.socket.off('connect');
    socketService?.socket.off('disconnect');
  }

  void _setupSocketListeners() {
    if (socketService == null) return;

    socketService!.socket.on('connect', (_) {
      Logger.log("✅ [SEEKER] Socket reconnected", type: "success");
      if (currentHelpRequestId.value.isNotEmpty) {
        socketService!.joinRoom(currentHelpRequestId.value);
        Logger.log("🚪 Rejoined room after reconnect: ${currentHelpRequestId.value}", type: "info",);
        _startAutoLocationSharing();
      }
    });

    socketService!.socket.on('helpRequestAccepted', (data) async {
      if (!Get.isRegistered<SeakerHomeController>()) return;
      Logger.log("❤️ [SEEKER] HELP REQUEST ACCEPTED: $data", type: "success");

      // Ensure socket is connected
      if (socketService?.isConnected.value != true) {
        Logger.log("⚠ [SEEKER] Socket not connected, waiting...", type: "warning",);
        await Future.delayed(const Duration(seconds: 1));
      }
      final currentRole = userController.userRole.value;
      if (currentRole != 'seeker' && currentRole != 'both') return;

      await _handleHelpRequestAccepted(data);
    });

    socketService!.socket.on('receiveLocationUpdate', (data) {
      if (!Get.isRegistered<SeakerHomeController>()) return;
      Logger.log("📍 LOCATION UPDATE: $data", type: "info");
      _handleLocationUpdate(data);
    });

    socketService!.socket.on('helpRequestCancelled', (data) {
      if (!Get.isRegistered<SeakerHomeController>()) return;
      Logger.log("⛔ REQUEST CANCELLED: $data", type: "warning");
      handleHelpRequestCancelled(data);
    });

    socketService!.socket.on('helpRequestCompleted', (data) {
      if (!Get.isRegistered<SeakerHomeController>()) return;
      Logger.log(" REQUEST COMPLETED: $data", type: "success");
      _resetHelpRequestState();
    });

    // Handle newHelpRequest only for giver mode
    socketService!.socket.on('newHelpRequest', (data) {
      if (!Get.isRegistered<SeakerHomeController>()) return;

      final userRole = userController.userRole.value;
      final bool isInGiverMode = userRole == "giver" || (userRole == "both" && helperStatus.value);

      if (isInGiverMode) {
        try {
          final requestData = data as Map<String, dynamic>;
          incomingHelpRequests.add(requestData);
          incomingHelpRequests.refresh();
          emergencyMode.value = 1;

          Logger.log("✅ Added request. Total: ${incomingHelpRequests.length}", type: "success");
        }on Exception catch (e) {
          Logger.log(" Error processing request: $e", type: "error");
        }
      }
    });

    // For 'both' role — server sends giver_newHelpRequest
    socketService!.socket.on('giver_newHelpRequest', (data) {
      if (!Get.isRegistered<SeakerHomeController>()) return;

      final userRole = userController.userRole.value;
      final bool isInGiverMode = userRole == "giver" || userRole == "both";

      if (isInGiverMode) {
        try {
          final requestData = data as Map<String, dynamic>;
          incomingHelpRequests.add(requestData);
          incomingHelpRequests.refresh();
          emergencyMode.value = 1;
          emergencyVibration();
          Logger.log("✅ [BOTH] giver_newHelpRequest received", type: "success");
        } catch (e) {
          Logger.log("❌ Error: $e", type: "error");
        }
      }
    });

    socketService!.socket.on('disconnect', (_) {
      Logger.log("⚠ [SEEKER] Socket disconnected", type: "warning");

      // Only show snackbar if we have an active request
      if (currentHelpRequestId.value.isNotEmpty || helperStatus.value) {
        Logger.log("🔄 Connection attempt in progress", type: "info");
      }

      socketService!.socket.on('connect_error', (error) {
        Logger.log(" [SEEKER] Connection error: $error", type: "error");
        _scheduleReconnect();
      });

      // Start reconnection attempts
      _scheduleReconnect();
    });
  }

  Future<void> _handleHelpRequestAccepted(dynamic data) async {
    try {
      stopVibration();
      Logger.log("🔥 [SEEKER] Processing help request accepted", type: "info");
      final requestData = data as Map<String, dynamic>;
      final helpRequest = requestData['helpRequest'] as Map<String, dynamic>?;
      final giverLocation = requestData['giverLocation'] as Map<String, dynamic>?;

      if (helpRequest == null) {
        Logger.log(" [SEEKER] No helpRequest in data", type: "error");
        return;
      }

      final helpRequestId = helpRequest['_id']?.toString() ?? '';
      if (helpRequestId.isEmpty) {
        Logger.log(" [SEEKER] Empty help request ID", type: "error");
        return;
      }

      // Update UI state
      currentHelpRequestId.value = helpRequestId;
      activeHelpRequest.value = requestData;
      helperStatus.value = true;
      emergencyMode.value = 2;
      update();

      Logger.log("🎯🎯🎯 UI MODE CHANGED TO 2! 🎯🎯🎯", type: "success");

      // Set request ID in location controller
      final locationController = Get.find<SeakerLocationsController>();
      locationController.setHelpRequestId(helpRequestId);
      Logger.log(" [SEEKER] Request ID set: $helpRequestId", type: "success");

      // Join room ONLY after acceptance
      if (socketService != null && socketService!.isConnected.value) {
        Logger.log("🚪 [SEEKER] Joining room: $helpRequestId", type: "info");
        await socketService!.joinRoom(helpRequestId);
        Logger.log("[SEEKER] Successfully joined room: $helpRequestId", type: "success",);
      }

      // Initialize giver position if provided
      if (giverLocation != null) {
        final lat = giverLocation['latitude'] as double?;
        final lng = giverLocation['longitude'] as double?;

        if (lat != null && lng != null) {
          giverPosition.value = Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          Logger.log("📍 [SEEKER] Giver position set: ($lat, $lng)", type: "success",);
          _updateDistanceAndEta();
        }
      }

      // Start location sharing (handles liveLocation + socket emission)
      await _startAutoLocationSharing();

      Logger.log("✅ [SEEKER] Help request fully processed", type: "success");
    } catch (e, stack) {
      Logger.log(" [SEEKER] Error in _handleHelpRequestAccepted: $e\nStack: $stack", type: "error",);
    }
  }

  Future<void> helpCompleted(String id) async {
    try {
      Logger.log("📤 [SEEKER] Marking help as completed: $id", type: "info");

      final locationController = Get.find<SeakerLocationsController>();
      locationController.stopLocationSharing();
      locationController.clearHelpRequestId();

      if (locationController.liveLocation.value) {
        locationController.liveLocation.value = false;
        //await locationController._positionStreamSubscription?.cancel();
        //locationController._positionStreamSubscription = null;
      }

      if (socketService != null) {
        socketService!.leaveRoom(id);
        socketService!.socket.emit('completeHelpRequest', id);
        socketService!.socket.emit('leaveHelpRequestRoom', id);
      }

      helperStatus.value = false;
      emergencyMode.value = 0;
      isSearching.value = false;
      activeHelpRequest.value = null;
      giverPosition.value = null;
      currentHelpRequestId.value = '';
      isSharingLocation.value = false;
      Logger.log("[SEEKER] Help request marked as completed", type: "success",);
    } on Exception catch (e, stackTrace) {
      Logger.log(" [SEEKER] Error: $e", type: "error");
      Logger.log("Stack: $stackTrace", type: "error");
    }
  }

  Future<void> _startAutoLocationSharing() async {
    final locationController = Get.find<SeakerLocationsController>();

    // Guard: ইতিমধ্যে sharing চলছে কিনা চেক করুন
    if (locationController.isSharingLocation.value &&
        locationController.liveLocation.value &&
        locationController.currentHelpRequestId.value ==
            currentHelpRequestId.value) {
      Logger.log("ℹ [SEEKER] Location sharing already active — skipping restart", type: "info",);
      return;
    }

    try {
      Logger.log("📍 [SEEKER] Starting auto location sharing", type: "info");

      if (locationController.currentHelpRequestId.value.isEmpty &&
          currentHelpRequestId.value.isNotEmpty) {
        locationController.setHelpRequestId(currentHelpRequestId.value);
      }

      if (locationController.currentHelpRequestId.value.isEmpty) {
        Logger.log("[SEEKER] No help request ID for location sharing", type: "error",);
        return;
      }

      if (!locationController.liveLocation.value) {
        await locationController.startLiveLocation();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      locationController.startLocationSharing();
      isSharingLocation.value = true;

      if (socketService?.isConnected.value != true) {
        Logger.log("⚠[SEEKER] Socket not connected - location updates may not work", type: "warning",);
      }

      Logger.log("[SEEKER] Location sharing started for request: ${locationController.currentHelpRequestId.value}", type: "success",);
    } catch (e) {
      Logger.log(
        " [SEEKER] Error starting location sharing: $e",
        type: "error",
      );
    }
  }

  void _handleLocationUpdate(dynamic data) {
    try {
      Logger.log("🔥 [SEEKER] RAW location update received from server", type: "info",);
      Logger.log("   Data type: ${data.runtimeType}", type: "debug");
      Logger.log("   Data: $data", type: "debug");

      Map<String, dynamic> locationData;

      if (data is String) {
        try {
          locationData = jsonDecode(data) as Map<String, dynamic>;
        } catch (e) {
          Logger.log(" [SEEKER] Failed to parse JSON string: $e", type: "error",);
          return;
        }
      } else if (data is Map) {
        locationData = Map<String, dynamic>.from(data);
      } else {
        Logger.log(" [SEEKER] Unknown data format: ${data.runtimeType}", type: "error",);
        return;
      }

      // FIXED: Removed 'userId' from helpRequestId extraction
      final helpRequestId =
          locationData['helpRequestId']?.toString() ??
          locationData['requestId']?.toString() ??
          locationData['room_id']?.toString() ?? '';

      Logger.log("📍 [SEEKER] Parsed location data", type: "info");
      Logger.log("   HelpRequestId: $helpRequestId", type: "debug");
      Logger.log("  Current RequestID: ${currentHelpRequestId.value}", type: "debug",);

      // Check if this is for our current request
      if (helpRequestId.isNotEmpty &&
          helpRequestId != currentHelpRequestId.value) {
        Logger.log("[SEEKER] Ignoring - different request ID", type: "warning",);
        Logger.log("   Received: $helpRequestId, Expected: ${currentHelpRequestId.value}", type: "warning",);
        return;
      }

      // Extract latitude/longitude
      dynamic latitudeRaw =
          locationData['latitude'] ??
          locationData['lat'] ??
          locationData['Latitude'] ??
          locationData['Lat'];

      dynamic longitudeRaw =
          locationData['longitude'] ??
          locationData['lng'] ??
          locationData['Longitude'] ??
          locationData['Lng'];

      Logger.log(
        "   Lat raw: $latitudeRaw, Lng raw: $longitudeRaw",
        type: "debug",
      );

      double? latitude = _safeToDouble(latitudeRaw);
      double? longitude = _safeToDouble(longitudeRaw);

      if (latitude == null || longitude == null) {
        Logger.log(
          " [SEEKER] Could not parse latitude/longitude",
          type: "error",
        );
        return;
      }

      // Validate coordinates
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        Logger.log(" [SEEKER] Invalid coordinate ranges", type: "error");
        return;
      }

      // Update giver position
      giverPosition.value = Position(
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

      Logger.log("✅ [SEEKER] GIVER POSITION UPDATED: ($latitude, $longitude)", type: "success",);

      // Update distance and ETA
      _updateDistanceAndEta();

      // Update UI
      update();
    } catch (e, stackTrace) {
      Logger.log(" [SEEKER] ERROR in _handleLocationUpdate: $e", type: "error");
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

  double? get otherPersonLatitude {
    // First check real-time position
    if (giverPosition.value != null) {
      return giverPosition.value!.latitude;
    }

    // Fallback to location from active request
    if (activeHelpRequest.value != null) {
      final helper =
          activeHelpRequest.value!['helper'] as Map<String, dynamic>?;
      final location = helper?['location'] as Map<String, dynamic>?;
      final coordinates = location?['coordinates'] as List<dynamic>?;

      if (coordinates != null && coordinates.length >= 2) {
        return (coordinates[1] as num).toDouble(); // latitude is second
      }
    }

    return null;
  }

  double? get otherPersonLongitude {
    // First check real-time position
    if (giverPosition.value != null) {
      return giverPosition.value!.longitude;
    }

    // Fallback to location from active request
    if (activeHelpRequest.value != null) {
      final helper =
          activeHelpRequest.value!['helper'] as Map<String, dynamic>?;
      final location = helper?['location'] as Map<String, dynamic>?;
      final coordinates = location?['coordinates'] as List<dynamic>?;

      if (coordinates != null && coordinates.length >= 2) {
        return (coordinates[0] as num).toDouble(); // longitude is first
      }
    }

    return null;
  }

  bool get isLocationAvailable {
    return giverPosition.value != null ||
        (activeHelpRequest.value != null &&
            (otherPersonLatitude != null && otherPersonLongitude != null));
  }

  double? get seekerLatitude {
    final seekerLocation =
        activeHelpRequest.value?['seekerLocation'] as Map<String, dynamic>?;
    return seekerLocation?['latitude']?.toDouble();
  }

  double? get seekerLongitude {
    final seekerLocation =
        activeHelpRequest.value?['seekerLocation'] as Map<String, dynamic>?;
    return seekerLocation?['longitude']?.toDouble();
  }

  double? get helperLatitude {
    final giverLocation =
        activeHelpRequest.value?['giverLocation'] as Map<String, dynamic>?;
    return giverLocation?['latitude']?.toDouble();
  }

  double? get helperLongitude {
    final giverLocation =
        activeHelpRequest.value?['giverLocation'] as Map<String, dynamic>?;
    return giverLocation?['longitude']?.toDouble();
  }

  String get otherPersonName {
    final helper = activeHelpRequest.value?['helper'] as Map<String, dynamic>?;
    return helper?['name']?.toString() ?? 'Helper';
  }

  String get helperImage {
    final helper = activeHelpRequest.value?['helper'] as Map<String, dynamic>?;
    return helper?['profileImage']?.toString() ?? '';
  }

  String get seekerName {
    final seekerLocation =
        activeHelpRequest.value?['seekerLocation'] as Map<String, dynamic>?;
    final user = seekerLocation?['user'] as Map<String, dynamic>?;
    return user?['name']?.toString() ?? 'Seeker';
  }

  String getSeekerName(Map<String, dynamic> request) {
    final seeker = request['seeker'] as Map<String, dynamic>?;
    return seeker?['name']?.toString() ?? 'Someone';
  }

  String getSeekerImage(Map<String, dynamic> request) {
    final seeker = request['seeker'] as Map<String, dynamic>?;
    return seeker?['profileImage']?.toString() ?? '';
  }

  String getRequestDistance(Map<String, dynamic> request) {
    return request['distance']?.toString() ?? 'Unknown';
  }

  Map<String, double> getRequestCoordinates(Map<String, dynamic> request) {
    final location = request['location'] as Map<String, dynamic>?;
    final coordinates = location?['coordinates'] as List?;

    return {
      'latitude': coordinates?[1]?.toDouble() ?? 0.0,
      'longitude': coordinates?[0]?.toDouble() ?? 0.0,
    };
  }

  void _stopLocationSharing() {
    try {
      final locationController = Get.find<SeakerLocationsController>();
      locationController.stopLocationSharing();
      Logger.log("📍 Stopped location sharing", type: "info");
    } on Exception catch (e) {
      Logger.log(" Error stopping location: $e", type: "error");
    }
  }

  void handleHelpRequestCancelled(dynamic data) {
    stopVibration();
    try {
      final cancelledRequestId =
          data['_id']?.toString() ?? data['id']?.toString() ?? '';

      if (cancelledRequestId.isNotEmpty &&
          currentHelpRequestId.value.isNotEmpty) {
        if (cancelledRequestId == currentHelpRequestId.value) {
          Logger.log("✅ Cancellation for our request", type: "success");
          _resetHelpRequestState();
        }
      } else {
        _resetHelpRequestState();
      }
    } on Exception catch (e) {
      Logger.log(" Error handling cancellation: $e", type: "error");
      _resetHelpRequestState();
    }
  }

  Future<void> acceptHelpRequest(String helpRequestId) async {
    if (socketService == null || !isSocketInitialized.value) {
      Logger.log(" [SEEKER] Socket not initialized", type: "error");
      return;
    }

    if (socketService?.isConnected.value != true) {
      Logger.log(" [SEEKER] Socket not connected", type: "error");
      return;
    }

    try {
      Logger.log("📤 [SEEKER] Accepting help request: $helpRequestId", type: "info",);

      //️ CRITICAL: According to backend spec, emit just the helpRequestId string, NOT an object
      socketService!.socket.emit('acceptHelpRequest', helpRequestId);
      Logger.log("📤 [SEEKER] Emitted acceptHelpRequest event", type: "info");

      currentHelpRequestId.value = helpRequestId;

      final locationController = Get.find<SeakerLocationsController>();
      locationController.setHelpRequestId(helpRequestId);
      Logger.log("✅ [SEEKER] Help request ID set in location controller", type: "success",);

      Logger.log("🚪 [SEEKER] Joining room: $helpRequestId", type: "info");
      socketService!.joinRoom(helpRequestId);
      await Future.delayed(const Duration(milliseconds: 500));
      Logger.log("✅ [SEEKER] Room join completed (with delay)", type: "success",);

      helperStatus.value = true;
      emergencyMode.value = 2;

      locationController.startLocationSharing();
      isSharingLocation.value = true;

      incomingHelpRequests.removeWhere((req) => req['_id'] == helpRequestId);
      incomingHelpRequests.refresh();

      Logger.log("✅ [SEEKER] Help request accepted", type: "success");
    } on Exception catch (e) {
      Logger.log(" [SEEKER] Error accepting: $e", type: "error");
    }
  }

  void _resetHelpRequestState() {
    stopVibration();
    Logger.log("🔄 [SEEKER] Resetting help request state", type: "info");

    // Get help request ID before clearing it
    final helpRequestId = currentHelpRequestId.value;

    helperStatus.value = false;
    emergencyMode.value = 0;
    isSearching.value = false;
    activeHelpRequest.value = null;
    giverPosition.value = null;
    currentHelpRequestId.value = '';
    isSharingLocation.value = false;

    // Stop location sharing
    final locationController = Get.find<SeakerLocationsController>();
    locationController.clearHelpRequestId();
    _stopLocationSharing();

    // Leave socket room if we were in one
    if (socketService != null && helpRequestId.isNotEmpty) {
      try {
        socketService!.leaveRoom(helpRequestId);
        Logger.log("[SEEKER] Left socket room: $helpRequestId", type: "info",);
      } catch (e) {
        Logger.log("Error leaving socket room: $e", type: "warning");
      }
    }
  }

  bool _isVibrating = false;
  AudioPlayer? _audioPlayer;

  Future<void> emergencyVibration() async {
    _isVibrating = true;

    final notificationsController = Get.find<NotificationsController>();
    final soundEnabled = notificationsController.isSoundEnabled.value;
    final notificationsEnabled =
        notificationsController.isNotificationsEnabled.value;

    // Play audio only if sound is enabled
    if (soundEnabled && notificationsEnabled) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.play(AssetSource('mp3/preview.mp3'));
    }

    if (Platform.isAndroid) {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator && notificationsEnabled) {
        await Vibration.vibrate(
          pattern: [0, 200, 100, 200, 100, 200, 100, 200],
          intensities: [255, 255, 255, 255],
          repeat: 0,
        );
      }
    } else if (Platform.isIOS) {
      while (_isVibrating) {
        if (!notificationsEnabled) break;

        await HapticFeedback.heavyImpact();
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 80));
        if (!_isVibrating) break;

        await Vibration.vibrate(duration: 100);
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        if (!_isVibrating) break;

        await HapticFeedback.heavyImpact();
        await Vibration.vibrate(duration: 100);
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  void stopVibration() {
    _isVibrating = false;
    Vibration.cancel();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }

  Future<void> helpRequest(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    // Initialize socket service if null
    if (socketService == null) {
      Logger.log(" Socket service is null, initializing...", type: "warning");
      await initSocket();
    }

    // Ensure the socket service is initialized
    if (socketService == null) {
      Logger.log(" Unable to initialize socket service", type: "error");
      return;
    }

    // Wait for socket to connect with enhanced retry logic
    int waitAttempts = 0;
    const maxAttempts = 20; // Increased attempts to give more time
    const delayMs = 500;

    // First check if already connected
    if (socketService!.isConnected.value) {
      Logger.log("✅ Socket already connected", type: "success");
    } else {
      Logger.log("⏳ Waiting for socket connection (max $maxAttempts attempts)...", type: "info",);

      while (socketService!.isConnected.value != true &&
          waitAttempts < maxAttempts) {
        Logger.log("⏳ Socket connection attempt ${waitAttempts + 1}/$maxAttempts...", type: "info",);

        // Check again in case connection happened while waiting
        if (socketService!.isConnected.value) {
          Logger.log("✅ Socket connected on attempt ${waitAttempts + 1}", type: "success",);
          break;
        }

        await Future.delayed(const Duration(milliseconds: delayMs));
        waitAttempts++;
      }
    }

    if (socketService!.isConnected.value != true) {
      Logger.log(" Socket still not connected after $maxAttempts attempts", type: "error",);

      // Try one more time to initialize
      await initSocket();

      // Wait a bit more after reinitialization
      waitAttempts = 0;
      while (socketService!.isConnected.value != true && waitAttempts < 10) {
        Logger.log("⏳ Final retry connection attempt ${waitAttempts + 1}/10...", type: "info",);
        await Future.delayed(const Duration(milliseconds: delayMs));
        waitAttempts++;
      }

      if (socketService!.isConnected.value != true) {
        Logger.log(" Socket still not connected after all attempts", type: "error",);
        return;
      }
    }

    Logger.log("✅ Continuing with help request, socket is connected", type: "success",);

    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      Logger.log("📵 No internet", type: "error");
      return;
    }

    isSearching.value = true;
    emergencyMode.value = 1;

    try {
      Logger.log("📤 Sending help request", type: "info");

      final response =
          await ApiService.post(
            '/api/help-requests',
            body: {'latitude': latitude, 'longitude': longitude},
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Help request timeout after 30 seconds. The server may be slow or unreachable.',
                const Duration(seconds: 30),
              );
            },
          );

      Logger.log("📥 Response: ${response.body}", type: "info");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> jsonData = data is String
            ? jsonDecode(data)
            : Map<String, dynamic>.from(data);

        final helpRequest = HelpRequestResponse.fromJson(jsonData);
        final helpRequestId = helpRequest.data.id;

        Logger.log("🆕 [SEEKER] Help Request Created: $helpRequestId", type: "success",);

        currentHelpRequestId.value = helpRequestId;

        final locationController = Get.find<SeakerLocationsController>();
        locationController.setHelpRequestId(helpRequestId);
        Logger.log("✅ [SEEKER] Help request ID set in location controller", type: "success",);

        // ROOM JOIN REMOVED HERE — only join after acceptance
        updateNearbyStats(
          helpRequest.nearbyStats.km1,
          helpRequest.nearbyStats.km2,
        );

        Logger.log("⏳ [SEEKER] Waiting for helper...", type: "info");
      } else {
        final errorData = jsonDecode(response.body);
        final message = errorData["message"] ?? "Request failed";
        Logger.log(" Failed: $message", type: "error");
        emergencyMode.value = 0;
        // Get.snackbar(
        //   "Request Failed",
        //   message,
        //   snackPosition: SnackPosition.BOTTOM,
        //   duration: const Duration(seconds: 3),
        // );
      }
    } on TimeoutException catch (e) {
      Logger.log("⏰ HTTP Request Timeout: ${e.message}", type: "error");
      emergencyMode.value = 0;
      // Get.snackbar(
      //   "Request Timeout",
      //   "The server is taking too long to respond. Please check your connection and try again.",
      //   snackPosition: SnackPosition.BOTTOM,
      //   duration: const Duration(seconds: 4),
      // );
    } on http.ClientException catch (e) {
      Logger.log("🌐 Network Error: ${e.message}", type: "error");
      emergencyMode.value = 0;
      // Get.snackbar(
      //   "Network Error",
      //   "Unable to connect to the server. Please check your internet connection.",
      //   snackPosition: SnackPosition.BOTTOM,
      //   duration: const Duration(seconds: 4),
      // );
    } on Exception catch (e) {
      Logger.log("❌ Error creating help request: $e", type: "error");
      emergencyMode.value = 0;
      // Get.snackbar(
      //   "Error",
      //   "Failed to create help request. Please try again.",
      //   snackPosition: SnackPosition.BOTTOM,
      //   duration: const Duration(seconds: 3),
      // );
    } finally {
      isSearching.value = false;
    }
  }

  void updateNearbyStats(int km1, int km2) {
    nearbyStats.value = NearbyStats(km1: km1, km2: km2);
  }

  void toggleMode() {
    emergencyMode.value = (emergencyMode.value + 1) % 3;
  }

  Future<void> cancelHelpRequest() async {
    stopVibration();
    if (currentHelpRequestId.value.isEmpty) {
      Logger.log("⚠ No active request to cancel", type: "warning");
      return;
    }

    final helpRequestId = currentHelpRequestId.value;
    Logger.log(" [SEEKER] Attempting to cancel help request: $helpRequestId", type: "info",);

    try {
      final result = await _attemptCancelRequest();

      if (result['success']) {
        Logger.log("✅ [SEEKER] Help request cancelled successfully", type: "success",);
        _resetHelpRequestState();

      } else if (result['statusCode'] == 401) {
        Logger.log("🔄 Token expired (401), refreshing token...", type: "info");

        final bool refreshSuccess = await AuthService.refreshToken();

        if (refreshSuccess) {
          Logger.log("✅ Token refreshed successfully, retrying cancel request...", type: "info",);

          final retryResult = await _attemptCancelRequest();

          if (retryResult['success']) {
            Logger.log("✅ [SEEKER] Help request cancelled after token refresh", type: "success",);
            _resetHelpRequestState();

          } else {
            final message = retryResult['message'] ?? 'Failed to cancel after token refresh';
            Logger.log(" Retry failed: $message", type: "error");

            _resetHelpRequestState();
          }
        } else {
          Logger.log("Token refresh failed", type: "error");

          // Still reset state for local cleanup
          _resetHelpRequestState();
        }
      } else {
        final message = result['message'] ?? 'Failed to cancel request';
        Logger.log(" Cancel failed: $message", type: "error");

        // Check if it's a timeout or network error - still reset state locally
        if (result['statusCode'] == 0 ||
            message.contains('timeout') ||
            message.contains('Network')) {
          Logger.log("⚠️ Network/timeout error - resetting state locally", type: "warning",);
          _resetHelpRequestState();

        } else {
          Get.snackbar("Cancel Failed", message, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3),);
        }
      }
    } on TimeoutException catch (e) {
      Logger.log("⏰ Cancel request timeout: ${e.message}", type: "error");
      _resetHelpRequestState();
    } on Exception catch (e) {
      Logger.log(" Unexpected error cancelling: $e", type: "error");
      _resetHelpRequestState();
    }
  }

  Future<Map<String, dynamic>> _attemptCancelRequest() async {
    try {
      Logger.log("📤 Cancelling help request: ${currentHelpRequestId.value}", type: "info",);

      final response =
          await ApiService.post(
            '/api/help-requests/${currentHelpRequestId.value}/cancel',
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Cancel request timeout after 30 seconds. The server may be slow or unreachable.',
                const Duration(seconds: 30),
              );
            },
          );

      Logger.log("📥 Cancel response status: ${response.statusCode}", type: "info");

      if (response.statusCode == 200 || response.statusCode == 204) {
        Logger.log("✅ Help request cancelled successfully", type: "success");
        return {'success': true, 'statusCode': response.statusCode};
      } else {

        String errorMessage = 'Unknown error';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Failed to cancel request';
        } catch (e) {
          errorMessage = 'Server returned status ${response.statusCode}';
        }

        Logger.log(" Cancel request failed: $errorMessage (Status: ${response.statusCode})", type: "error",);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': errorMessage,
        };
      }
    } on TimeoutException catch (e) {
      Logger.log("⏰ Cancel request timeout: ${e.message}", type: "error");
      return {
        'success': false,
        'statusCode': 0,
        'message':
            'Request timeout. Please check your connection and try again.',
      };
    } on http.ClientException catch (e) {
      Logger.log("🌐 Network error during cancel: ${e.message}", type: "error");
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Network error. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      Logger.log("📄 Response parsing error: ${e.message}", type: "error");
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Invalid server response. Please try again.',
      };
    } catch (e) {
      Logger.log(" Unexpected error in _attemptCancelRequest: $e", type: "error",);
      return {
        'success': false,
        'statusCode': 0,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  String get helperName {
    final giverLocation =
        activeHelpRequest.value?['giverLocation'] as Map<String, dynamic>?;
    final user = giverLocation?['user'] as Map<String, dynamic>?;
    return user?['name']?.toString() ?? 'Helper';
  }

  String get address {
    final giverLocation =
        activeHelpRequest.value?['giverLocation'] as Map<String, dynamic>?;
    return giverLocation?['address']?.toString() ?? 'Address unavailable';
  }

  String get lastUpdated {
    final giverLocation =
        activeHelpRequest.value?['giverLocation'] as Map<String, dynamic>?;
    return giverLocation?['lastUpdated']?.toString() ?? 'Just now';
  }

  bool get hasActiveHelpRequest => activeHelpRequest.value != null;

  void debugLocationInfo() {
    Logger.log("=== SEEKER LOCATION DEBUG ===", type: "info");

    Logger.log("📊 Basic Info:", type: "info");
    Logger.log("- hasActiveHelpRequest: $hasActiveHelpRequest", type: "info");
    Logger.log("- currentHelpRequestId: $currentHelpRequestId", type: "info");
    Logger.log("- helperStatus: $helperStatus", type: "info");

    Logger.log("📍 Position Info:", type: "info");
    Logger.log("- giverPosition: $giverPosition", type: "info");
    if (giverPosition.value != null) {
      Logger.log("- giverPosition LatLng: (${giverPosition.value!.latitude}, ${giverPosition.value!.longitude})", type: "info",);
    }

    Logger.log("🎯 Getter Values:", type: "info");
    Logger.log("- otherPersonLatitude: $otherPersonLatitude", type: "info");
    Logger.log("- otherPersonLongitude: $otherPersonLongitude", type: "info");
    Logger.log("- helperLatitude: $helperLatitude", type: "info");
    Logger.log("- helperLongitude: $helperLongitude", type: "info");

    Logger.log("📦 Active Request Structure:", type: "info");
    if (activeHelpRequest.value != null) {
      final req = activeHelpRequest.value!;
      Logger.log("- Request Keys: ${req.keys.toList()}", type: "info");

      if (req.containsKey('helper')) {
        final helper = req['helper'] as Map<String, dynamic>?;
        Logger.log("- Helper exists: ${helper != null}", type: "info");
        if (helper != null) {
          Logger.log("- Helper Keys: ${helper.keys.toList()}", type: "info");

          if (helper.containsKey('location')) {
            final location = helper['location'] as Map<String, dynamic>?;
            Logger.log("- Location exists: ${location != null}", type: "info");
            if (location != null) {
              Logger.log("- Location Keys: ${location.keys.toList()}", type: "info",);
              if (location.containsKey('coordinates')) {
                final coords = location['coordinates'] as List<dynamic>?;
                Logger.log("- Coordinates: $coords", type: "info");
              }
            }
          }
        }
      }

      if (req.containsKey('giverLocation')) {
        final giverLoc = req['giverLocation'] as Map<String, dynamic>?;
        Logger.log("- giverLocation exists: ${giverLoc != null}", type: "info");
        if (giverLoc != null) {
          Logger.log("- giverLocation Keys: ${giverLoc.keys.toList()}", type: "info",);
        }
      }
    } else {
      Logger.log("- No active request", type: "info");
    }

    Logger.log("📡 Socket Info:", type: "info");
    Logger.log("- socketService exists: ${socketService != null}", type: "info",);
    Logger.log("- isSocketInitialized: $isSocketInitialized", type: "info");
    if (socketService != null) {
      Logger.log("- socket connected: ${socketService!.isConnected.value}", type: "info",);
    }

    Logger.log("=== END DEBUG ===", type: "info");
  }

  RxString userName = ''.obs;
  RxString profileImage = ''.obs;
  RxString userId = ''.obs;
  RxString userRole = ''.obs;
  RxString firstName = ''.obs;
  RxString lastName = ''.obs;

  Future<void> loadUserData() async {
    try {
      final userBox = await Hive.openBox('userProfileBox');

      final name = userBox.get('name');
      final id = userBox.get('_id');
      final role = userBox.get('role');
      final image = userBox.get(
        'profileImage',
      ); // was 'image', now 'profileImage'

      userName.value = name ?? '';
      userId.value = id ?? '';
      userRole.value = role ?? '';
      profileImage.value = image ?? '';

      if (name != null && name.toString().trim().isNotEmpty) {
        final parts = name.toString().trim().split(" ");
        firstName.value = parts.first;
        lastName.value = parts.length > 1 ? parts.sublist(1).join(" ") : '';
      }

      // Fetch fresh profile image from API
      await _fetchProfileImage();
    } on Exception catch (e) {
      Logger.log(" Error loading user data: $e", type: "error");
      userName.value = 'Error loading';
    }
  }

  Future<void> _fetchProfileImage() async {
    try {
      final response = await ApiService.get('/api/users/me');
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final user = (body['data'] ?? body) as Map<String, dynamic>;
        String imageUrl = user['profileImage']?.toString() ?? '';
        if (imageUrl.isNotEmpty) {
          profileImage.value = imageUrl;
          Logger.log("Profile image: $imageUrl", type: "info");
        }
      }
    } catch (e) {
      Logger.log(" Error fetching profile image: $e", type: "error");
    }
  }

  @override
  void onClose() {
    // if (socketService?.isConnected.value == true) {
    //   socketService!.socket.disconnect();
    //   Logger.log("🔌 [SEEKER] Socket disconnected", type: "info");
    // }
    removeAllListeners();
    giverPosition.value = null;
    super.onClose();
  }
}

SeakerLocationsController get locationController {
  return Get.find<SeakerLocationsController>();
}
