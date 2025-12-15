import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:saferader/controller/UserController/userController.dart';
import 'package:saferader/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../SeakerHome/seakerHomeController.dart';
import '../SocketService/socket_service.dart';
import '../../services/background_location_socket_service.dart';
import '../../utils/token_service.dart';

class SeakerLocationsController extends GetxController {
  RxBool liveLocation = false.obs;
  Rx<Position?> currentPosition = Rx<Position?>(null);
  RxBool isSharingLocation = false.obs;
  Position? _lastSentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  RxString currentHelpRequestId = ''.obs;
  RxBool isSocketConnected = false.obs;
  bool _hasReceivedFirstLocation = false;
  DateTime? _lastSuccessfulUpdate;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 5;
  final double _distanceThreshold = 10.0;
  final int _timeThreshold = 5000;
  final int _geolocatorDistanceFilter = 10;
  Timer? _locationTimer;
  // 🔥 NEW: Track stream state
  bool _isStreamActive = false;

  String get latString => currentPosition.value?.latitude.toString() ?? "";
  String get lngString => currentPosition.value?.longitude.toString() ?? "";
  SocketService? _cachedSocketService;
  DateTime? _socketCacheTime;


  @override
  void onClose() {
    _locationTimer?.cancel();
    _forceStopLocationStream(); // 🔥 FIXED
    stopLocationSharing();
    super.onClose();
  }

  // 🔥 NEW: Force stop location stream
  Future<void> _forceStopLocationStream() async {
    Logger.log("🛑 [STREAM] Force stopping location stream...", type: "warning");

    _isStreamActive = false;
    liveLocation.value = false;

    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      Logger.log("✅ [STREAM] Subscription cancelled", type: "success");
    }

    // 🔥 Android fix: Cancel any background streams
    try {
      await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 0,
        ),
      ).listen((_) {}).cancel();
    } catch (e) {
      // Expected to fail if no stream exists
    }

    await Future.delayed(const Duration(milliseconds: 500));
    Logger.log("✅ [STREAM] All streams stopped", type: "success");
  }

  SocketService? getActiveSocket() {
    final now = DateTime.now();

    // 🔥 FIXED: Enhanced cache validation - check if cached socket is still connected
    if (_socketCacheTime != null &&
        now.difference(_socketCacheTime!).inSeconds < 2 &&
        _cachedSocketService != null &&
        _cachedSocketService!.isConnected.value) {
      return _cachedSocketService;
    }

    // 🔥 FIXED: If cached socket is disconnected, clear the cache
    if (_cachedSocketService != null && !_cachedSocketService!.isConnected.value) {
      Logger.log("⚠️ [SOCKET] Cached socket is disconnected, clearing cache", type: "warning");
      _cachedSocketService = null;
      _socketCacheTime = null;
    }

    SocketService? socketService;

    // Check Giver first
    if (Get.isRegistered<GiverHomeController>()) {
      final giverController = Get.find<GiverHomeController>();
      if (giverController.socketService != null &&
          giverController.socketService!.isConnected.value) {
        socketService = giverController.socketService;
        Logger.log("✅ [SOCKET] Using Giver socket", type: "debug");
      }
    }

    // Then check Seeker
    if (socketService == null && Get.isRegistered<SeakerHomeController>()) {
      final seekerController = Get.find<SeakerHomeController>();
      if (seekerController.socketService != null &&
          seekerController.socketService!.isConnected.value) {
        socketService = seekerController.socketService;
        Logger.log("✅ [SOCKET] Using Seeker socket", type: "debug");
      }
    }

    // Finally check general socket
    if (socketService == null && Get.isRegistered<SocketService>()) {
      final generalSocket = Get.find<SocketService>();
      if (generalSocket.isConnected.value) {
        socketService = generalSocket;
        Logger.log("✅ [SOCKET] Using General socket", type: "debug");
      }
    }

    if (socketService != null) {
      _cachedSocketService = socketService;
      _socketCacheTime = now;
      Logger.log("✅ [SOCKET] Setting new active socket in cache", type: "debug");
    } else {
      Logger.log("⚠️ [SOCKET] No active socket found", type: "warning");
    }

    return socketService;
  }

  void setHelpRequestId(String helpRequestId) {
    if (helpRequestId.isNotEmpty) {
      currentHelpRequestId.value = helpRequestId;
      _cachedSocketService = null;
      _socketCacheTime = null;

      // Update background service with new help request ID
      BackgroundLocationSocketService.setActiveHelpRequestId(helpRequestId);

      Logger.log("✅ [LOCATION SHARE] Help request ID set: $helpRequestId", type: "success");
    } else {
      Logger.log("⚠️ [LOCATION SHARE] Attempted to set empty help request ID", type: "warning");
      // Clear help request ID in background service too
      BackgroundLocationSocketService.setActiveHelpRequestId('');
    }
  }

  void clearHelpRequestId() {
    final oldId = currentHelpRequestId.value;
    currentHelpRequestId.value = '';
    _cachedSocketService = null;
    _socketCacheTime = null;

    // Also clear in background service
    BackgroundLocationSocketService.setActiveHelpRequestId('');

    Logger.log("📍 [LOCATION SHARE] Help request ID cleared (was: $oldId)", type: "info");
  }

  void forceSocketRefresh() {
    _cachedSocketService = null;
    _socketCacheTime = null;
    Logger.log("🔄 [LOCATION SHARE] Socket cache forcibly refreshed", type: "info");
  }

  // 🔥 NEW: Complete socket refresh including room rejoining
  Future<void> refreshSocketAndRejoinRoom() async {
    Logger.log("🔄 [CONNECTION] Starting complete socket refresh", type: "info");

    // First, force refresh the socket cache to get new socket instance
    forceSocketRefresh();

    // Give a moment for the cache refresh to complete
    await Future.delayed(const Duration(milliseconds: 200));

    // Get the updated socket service
    final socketService = getActiveSocket();

    if (socketService == null) {
      Logger.log("❌ [CONNECTION] No socket service found after refresh", type: "error");
      return;
    }

    Logger.log("✅ [CONNECTION] Socket service found: ${socketService.isConnected.value}", type: "info");

    // Rejoin room if needed
    await rejoinRoomIfNeeded();

    Logger.log("✅ [CONNECTION] Complete socket refresh completed", type: "success");
  }

  // 🔥 NEW: Background service integration methods
  Future<void> startBackgroundLocationSharing() async {
    Logger.log("🔄 [BACKGROUND] Starting background location sharing", type: "info");

    // Initialize the background service if not already done
    if (!await BackgroundLocationSocketService.isServiceRunning()) {
      await BackgroundLocationSocketService.initializeService();
    }

    // Get the auth token using TokenService
    final tokenService = TokenService();
    final token = await tokenService.getToken();

    if (token == null || token.isEmpty) {
      Logger.log("❌ [BACKGROUND] No auth token available", type: "error");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    // Set user role for background service
    String role = 'seeker'; // Default role

    // Safely try to get the user role from either controller
    try {
      if (Get.isRegistered<SeakerHomeController>()) {
        final seekerController = Get.find<SeakerHomeController>();
        role = seekerController.userController.userRole.value;
      } else if (Get.isRegistered<UserController>()) {
        final userController = Get.find<UserController>();
        role = userController.userRole.value;
      }
    } catch (e) {
      Logger.log("⚠️ [BACKGROUND] Could not get user role, using default: $role", type: "warning");
    }

    await prefs.setString('user_role', role);

    // Start background location sharing
    await BackgroundLocationSocketService.startLocationSharing();

    // Set the current help request ID for the background service
    if (currentHelpRequestId.value.isNotEmpty) {
      await BackgroundLocationSocketService.setActiveHelpRequestId(currentHelpRequestId.value);
    }

    Logger.log("✅ [BACKGROUND] Background location sharing started", type: "success");
  }

  Future<void> stopBackgroundLocationSharing() async {
    Logger.log("🔄 [BACKGROUND] Stopping background location sharing", type: "info");

    await BackgroundLocationSocketService.stopLocationSharing();
    await BackgroundLocationSocketService.setActiveHelpRequestId('');

    // Completely stop the background service when not needed
    await BackgroundLocationSocketService.stopService();

    Logger.log("✅ [BACKGROUND] Background location sharing stopped", type: "success");
  }

  // Call this when starting active location sharing
  @override
  void onInit() {
    super.onInit();
    _setupConnectionStateMonitoring();

    // Listen for help request ID changes to update background service
    ever(currentHelpRequestId, (String? requestId) async {
      if (requestId != null && requestId.isNotEmpty) {
        await BackgroundLocationSocketService.setActiveHelpRequestId(requestId);
      } else {
        await BackgroundLocationSocketService.setActiveHelpRequestId('');
      }
    });
  }



  // Method to periodically check for background location updates
  Timer? _backgroundLocationCheckTimer;

  void startBackgroundLocationMonitoring() {
    // Check for location updates from background service every 3 seconds
    _backgroundLocationCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!isSharingLocation.value) {
        // Stop monitoring if not sharing location
        _backgroundLocationCheckTimer?.cancel();
        return;
      }

      // Check for incoming location updates from background service
      final incomingUpdate = await BackgroundLocationSocketService.getIncomingLocationUpdate();
      if (incomingUpdate != null) {
        // Process the incoming location update (this might be from the other party)
        Logger.log("📍 [BACKGROUND] Incoming location update: $incomingUpdate", type: "info");

        // This would typically update the other party's position on the map
        // For example, update giver position if you're a seeker, or seeker position if you're a giver
      }

      // Check for pending location updates that couldn't be sent due to connection issues
      final pendingUpdate = await BackgroundLocationSocketService.getPendingLocationUpdate();
      if (pendingUpdate != null) {
        // This means there was a location that couldn't be sent, might want to handle this
        Logger.log("📍 [BACKGROUND] Pending location update: $pendingUpdate", type: "info");
      }
    });
  }

  // Call this method when starting location sharing
  @override
  void startLocationSharing() {
    isSharingLocation.value = true;
    _lastSentPosition = null;
    _consecutiveFailures = 0;

    final helpRequestId = _getHelpRequestId();
    if (helpRequestId == null || helpRequestId.isEmpty) {
      Logger.log("⚠️ [LOCATION SHARE] Starting without help request ID", type: "warning");
    } else {
      Logger.log("✅ [LOCATION SHARE] Started for request: $helpRequestId", type: "success");
    }

    if (currentPosition.value != null) {
      _shareLocation(currentPosition.value!);
    }

    // Start background service when location sharing starts
    if (helpRequestId != null && helpRequestId.isNotEmpty) {
      startBackgroundLocationSharing();
    }

    // Start monitoring for background updates
    startBackgroundLocationMonitoring();

    Logger.log("✅ [LOCATION SHARE] Location sharing started with background monitoring", type: "success");
  }

  // Update the stop method to cancel the timer
  void stopLocationSharing() {
    Logger.log("🛑 [STOP] Stopping location sharing...", type: "info");

    isSharingLocation.value = false;
    _lastSentPosition = null;
    _locationTimer?.cancel();
    _backgroundLocationCheckTimer?.cancel(); // Cancel the background update timer
    _consecutiveFailures = 0;
    _lastSuccessfulUpdate = null;
    _hasReceivedFirstLocation = false;

    _forceStopLocationStream();

    // Stop background service when location sharing stops
    stopBackgroundLocationSharing();

    Logger.log("✅ [STOP] Location sharing stopped", type: "success");
  }

  // Method to be called when help request is completed or cancelled
  Future<void> completeBackgroundLocationSharing() async {
    Logger.log("🛑 [BACKGROUND] Completing background location sharing (help request ended)", type: "info");

    // Clear help request ID first
    await BackgroundLocationSocketService.setActiveHelpRequestId('');

    // Stop location sharing (this will also stop background service)
    stopLocationSharing();

    Logger.log("✅ [BACKGROUND] Background location sharing completely stopped", type: "success");
  }

  // 🔥 NEW: Comprehensive refresh specifically for returning from map
  Future<void> refreshAfterMapReturn() async {
    Logger.log("🔄 [MAP RETURN] Starting comprehensive refresh after returning from map", type: "info");

    // Force refresh socket cache to get latest socket instance
    forceSocketRefresh();

    // Wait for cache to clear
    await Future.delayed(const Duration(milliseconds: 300));

    // Ensure we have the right socket
    final socketService = getActiveSocket();

    if (socketService == null) {
      Logger.log("❌ [MAP RETURN] No socket service available after map return", type: "error");
      return;
    }

    Logger.log("✅ [MAP RETURN] Socket service available: ${socketService.isConnected.value}", type: "info");

    // If we have an active help request, make sure we're in the right room
    if (currentHelpRequestId.value.isNotEmpty) {
      Logger.log("🚪 [MAP RETURN] Rejoining room: ${currentHelpRequestId.value}", type: "info");
      await rejoinRoomIfNeeded();

      // Wait for room to be joined
      await Future.delayed(const Duration(milliseconds: 500));

      // Share current location to ensure we're active in the system
      if (currentPosition.value != null) {
        Logger.log("📍 [MAP RETURN] Sharing current location after room rejoin", type: "info");
        _shareLocation(currentPosition.value!);
      }

      // Ensure background service is also in sync
      await BackgroundLocationSocketService.setActiveHelpRequestId(currentHelpRequestId.value);
    } else {
      Logger.log("ℹ️ [MAP RETURN] No active help request, skipping room join", type: "info");
      // Clear background service help request ID if none is active
      await BackgroundLocationSocketService.setActiveHelpRequestId('');
    }

    Logger.log("✅ [MAP RETURN] Comprehensive refresh completed", type: "success");
  }

  void _setupConnectionStateMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isSharingLocation.value) {
        return; // Don't cancel timer, keep monitoring
      }

      final socketService = getActiveSocket();
      final wasConnected = isSocketConnected.value;
      final isConnected = socketService != null && socketService.isConnected.value;

      isSocketConnected.value = isConnected;

      if (wasConnected != isConnected) {
        if (isConnected) {
          Logger.log("✅ [CONNECTION] Socket connection restored", type: "success");

          // Rejoin room if we have an active help request
          if (currentHelpRequestId.value.isNotEmpty) {
            Logger.log("🔄 [CONNECTION] Rejoining room after connection restore", type: "info");
            rejoinRoomIfNeeded();
          }

          if (currentPosition.value != null) {
            _shareLocation(currentPosition.value!);
          }
        } else {
          Logger.log("⚠️ [CONNECTION] Socket connection lost", type: "warning");
        }
      }

      if (!isConnected && isSharingLocation.value) {
        Logger.log("⚠️ [CONNECTION] Location sharing active but socket disconnected", type: "warning");
      }
    });
  }

  RxString addressText = "".obs;
  RxString lastUpdated = "".obs;

  Future<void> updateLocation(Position pos) async {
    currentPosition.value = pos;

    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        addressText.value = "${p.street}, ${p.locality}, ${p.country}";
      } else {
        addressText.value = "Address unavailable";
      }
    } catch (_) {
      addressText.value = "Unable to get address";
    }

    lastUpdated.value =
    "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
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
      Logger.log("📍 One-time location: Lat ${pos.latitude}, Lng ${pos.longitude}", type: "info");
      _autoShareLocation(pos);

    } catch (e) {
      Logger.log("❌ Error getting location: $e", type: "error");
    }
  }

  // 🔥 FIXED: Completely rewritten startLiveLocation
  Future<void> startLiveLocation() async {
    Logger.log("🚀 [STREAM] Starting live location...", type: "info");

    final hasPermission = await handlePermission();
    if (!hasPermission) {
      Logger.log("❌ [STREAM] No location permission", type: "error");
      return;
    }

    // 🔥 STEP 1: Complete cleanup first
    if (_isStreamActive || _positionStreamSubscription != null) {
      Logger.log("⚠️ [STREAM] Existing stream detected, stopping it first...", type: "warning");
      await _forceStopLocationStream();
    }

    // 🔥 STEP 2: Reset all flags
    _hasReceivedFirstLocation = false;
    _isStreamActive = false;

    await Future.delayed(const Duration(milliseconds: 500));

    // 🔥 STEP 3: Start fresh stream
    try {
      Logger.log("📡 [STREAM] Creating new position stream...", type: "info");

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // meters
          // timeLimit: Duration(seconds: 30), // 👈 COMMENT OUT THIS LINE TO FIX TIMEOUT ISSUE
        ),
      ).listen(
            (Position position) {
          // 🔥 Accept first position OR high accuracy positions
          if (!_hasReceivedFirstLocation || position.accuracy <= 50) {
            if (!_hasReceivedFirstLocation) {
              _hasReceivedFirstLocation = true;
              Logger.log("🎯 [STREAM] First location received!", type: "success");
            }

            currentPosition.value = position;
            Logger.log(
                "📍 Live location: (${position.latitude}, ${position.longitude}) - Accuracy: ${position.accuracy}m",
                type: "debug"
            );
            _autoShareLocation(position);
          } else {
            Logger.log(
                "⏭️ [STREAM] Skipped low-accuracy: ${position.accuracy}m",
                type: "debug"
            );
          }
        },
        onError: (error) {
          Logger.log("❌ [STREAM] Error: $error", type: "error");
          _isStreamActive = false;
        },
        onDone: () {
          Logger.log("📍 [STREAM] Stream ended", type: "warning");
          _isStreamActive = false;
          liveLocation.value = false;
        },
        cancelOnError: false,
      );

      _isStreamActive = true;
      liveLocation.value = true;
      _startTimeBasedUpdates();

      Logger.log("✅ [STREAM] Live location streaming started successfully", type: "success");

    } catch (e, stackTrace) {
      Logger.log("❌ [STREAM] Failed to start: $e", type: "error");
      Logger.log("Stack: $stackTrace", type: "error");
      _isStreamActive = false;
      liveLocation.value = false;
    }
  }

  void resetFirstLocationFlag() {
    _hasReceivedFirstLocation = false;
    Logger.log("📍 First location flag reset", type: "info");
  }

  void _startTimeBasedUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(milliseconds: _timeThreshold), (timer) {
      if (isSharingLocation.value && currentPosition.value != null && _isStreamActive) {
        _shareLocation(currentPosition.value!);
        Logger.log("⏰ [TIMER] Time-based update sent", type: "debug");
      }
    });
  }

  String? _getHelpRequestId() {
    if (currentHelpRequestId.value.isNotEmpty) {
      return currentHelpRequestId.value;
    }

    if (Get.isRegistered<GiverHomeController>()) {
      final giverController = Get.find<GiverHomeController>();
      final acceptedRequest = giverController.acceptedHelpRequest.value;
      if (acceptedRequest != null) {
        final id = acceptedRequest['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          currentHelpRequestId.value = id;
          return id;
        }
      }
    }

    if (Get.isRegistered<SeakerHomeController>()) {
      final seekerController = Get.find<SeakerHomeController>();
      if (seekerController.hasActiveHelpRequest &&
          seekerController.currentHelpRequestId.value.isNotEmpty) {
        final id = seekerController.currentHelpRequestId.value;
        currentHelpRequestId.value = id;
        return id;
      }
    }

    return null;
  }

  void _shareLocation(Position position) {
    try {
      final helpRequestId = _getHelpRequestId();

      if (helpRequestId == null || helpRequestId.isEmpty) {
        Logger.log("❌ [SHARE] No help request ID", type: "warning");
        _consecutiveFailures++;
        return;
      }

      final socketService = getActiveSocket();

      if (socketService == null) {
        Logger.log("❌ [SHARE] No socket service", type: "error");
        _consecutiveFailures++;
        isSocketConnected.value = false;
        return;
      }

      if (!socketService.isConnected.value) {
        Logger.log("❌ [SHARE] Socket disconnected", type: "error");
        _consecutiveFailures++;
        isSocketConnected.value = false;
        return;
      }

      // 🔥 NEW: Ensure we're in the correct room before sending location
      if (socketService.currentRoom != helpRequestId) {
        Logger.log("⚠️ [SHARE] Not in correct room, joining: $helpRequestId", type: "warning");
        socketService.joinRoom(helpRequestId);
        // Wait a bit for room to join before sending location
        Future.delayed(const Duration(milliseconds: 300)).then((_) {
          // Retry sending location after joining room
          Logger.log("🔄 [SHARE] Retrying location send after room join", type: "info");
          _shareLocation(position);
        });
        return;
      }

      isSocketConnected.value = true;

      Logger.log("📤 [SHARE] Sending to room: $helpRequestId", type: "info");
      Logger.log("   Coordinates: (${position.latitude}, ${position.longitude})", type: "debug");

      socketService.sendLocationUpdate(
        position.latitude,
        position.longitude,
      );

      _lastSuccessfulUpdate = DateTime.now();
      _consecutiveFailures = 0;
      _lastSentPosition = position;

      Logger.log("✅ [SHARE] Location sent successfully", type: "success");

    } catch (e, stackTrace) {
      _consecutiveFailures++;
      Logger.log("❌ [SHARE] Error: $e", type: "error");

      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        Logger.log(
            "⚠️ [SHARE] $_consecutiveFailures consecutive failures!",
            type: "warning"
        );
      }
    }
  }

  void forceLocationSharingStart() {
    if (currentHelpRequestId.value.isEmpty) {
      Logger.log("❌ [LOCATION] Cannot force start: No help request ID", type: "error");
      return;
    }

    if (currentPosition.value == null) {
      Logger.log("❌ [LOCATION] Cannot force start: No position", type: "error");
      return;
    }

    Logger.log("📍 [LOCATION] Force starting location sharing", type: "info");

    // Force refresh socket cache to get updated socket service
    forceSocketRefresh();

    startLocationSharing();
    shareCurrentLocation();
  }



  Map<String, dynamic> getLocationSharingStatus() {
    final timeSinceLastUpdate = _lastSuccessfulUpdate != null
        ? DateTime.now().difference(_lastSuccessfulUpdate!).inSeconds
        : null;

    return {
      'isSharing': isSharingLocation.value,
      'helpRequestId': currentHelpRequestId.value,
      'isSocketConnected': isSocketConnected.value,
      'isStreamActive': _isStreamActive,
      'lastSuccessfulUpdate': _lastSuccessfulUpdate?.toIso8601String(),
      'secondsSinceLastUpdate': timeSinceLastUpdate,
      'consecutiveFailures': _consecutiveFailures,
      'hasCurrentPosition': currentPosition.value != null,
      'isHealthy': _consecutiveFailures < _maxConsecutiveFailures &&
          (timeSinceLastUpdate == null || timeSinceLastUpdate < 60),
    };
  }

  bool get isLocationSharingHealthy {
    if (!isSharingLocation.value) return false;
    if (currentHelpRequestId.value.isEmpty) return false;
    if (!isSocketConnected.value) return false;
    if (_consecutiveFailures >= _maxConsecutiveFailures) return false;

    if (_lastSuccessfulUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastSuccessfulUpdate!);
      if (timeSinceLastUpdate.inSeconds > 60) return false;
    }

    return true;
  }

  // 🔥 FIXED: Complete cleanup in stopLocationSharing

  void _autoShareLocation(Position newPosition) {
    if (!isSharingLocation.value) return;

    if (_shouldSendUpdate(newPosition)) {
      _shareLocation(newPosition);
    }
  }

  bool _shouldSendUpdate(Position newPosition) {
    if (_lastSentPosition == null) {
      return true;
    }

    final distance = Geolocator.distanceBetween(
      _lastSentPosition!.latitude,
      _lastSentPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance >= _distanceThreshold;
  }

  void shareCurrentLocation() {
    if (currentPosition.value != null) {
      _shareLocation(currentPosition.value!);
    } else {
      Logger.log("📍 No current position available", type: "warning");
    }
  }

  // 🔥 NEW: Method to rejoin room after returning from map
  Future<void> rejoinRoomIfNeeded() async {
    final helpRequestId = currentHelpRequestId.value;

    if (helpRequestId.isEmpty) {
      Logger.log("⚠️ [ROOM] No active help request, no need to rejoin", type: "info");
      return;
    }

    final socketService = getActiveSocket();
    if (socketService == null) {
      Logger.log("⚠️ [ROOM] No active socket to rejoin room", type: "warning");
      return;
    }

    // Check if we're already in the right room
    if (socketService.currentRoom == helpRequestId) {
      Logger.log("✅ [ROOM] Already in correct room: $helpRequestId", type: "info");
      return;
    }

    Logger.log("🚪 [ROOM] Rejoining room: $helpRequestId", type: "info");
    await socketService.joinRoom(helpRequestId);

    // Wait a bit for the room join to complete
    await Future.delayed(const Duration(milliseconds: 500));

    Logger.log("✅ [ROOM] Successfully rejoined room: $helpRequestId", type: "success");
  }

  String get sharingStatus {
    if (!isSharingLocation.value) return "Not Sharing";

    String role = "unknown";

    if (Get.isRegistered<SeakerHomeController>()) {
      final userController = Get.find<SeakerHomeController>().userController;
      role = userController.userRole.value;

      switch (role) {
        case "seeker":
          return "Sharing with Helper";
        case "giver":
          return "Sharing with Seeker";
        case "both":
          final isHelper = Get.find<SeakerHomeController>().helperStatus.value;
          return isHelper ? "Sharing with Seeker" : "Sharing with Helper";
      }
    }

    return "Sharing Location";
  }

  Future<void> checkAndEnableAutoSharing() async {
    try {
      final hasPermission = await handlePermission();

      if (hasPermission && !liveLocation.value) {
        await startLiveLocation();
        startLocationSharing();
        Logger.log("📍 Auto location sharing enabled", type: "success");
      }
    } catch (e) {
      Logger.log("❌ Error enabling auto sharing: $e", type: "error");
    }
  }

  Future<void> saveAutoSharingPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_location_sharing', enabled);
  }

  Future<bool> getAutoSharingPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_location_sharing') ?? false;
  }

  void toggleLocationSharing(bool enable) async {
    if (enable) {
      startLocationSharing();
    } else {
      stopLocationSharing();
    }
    await saveAutoSharingPreference(enable);
  }

  Future<void> initializeAutoSharing() async {
    final autoShareEnabled = await getAutoSharingPreference();
    if (autoShareEnabled) {
      await checkAndEnableAutoSharing();
    }
  }

  bool shouldShareLocation() {
    bool hasActiveRequest = false;
    if (Get.isRegistered<SeakerHomeController>()) {
      hasActiveRequest = Get.find<SeakerHomeController>().hasActiveHelpRequest;
    }

    if (!hasActiveRequest && Get.isRegistered<GiverHomeController>()) {
      hasActiveRequest = Get.find<GiverHomeController>().emergencyMode.value == 2;
    }

    return hasActiveRequest && isSharingLocation.value;
  }

  void logLocationSharingDebugInfo() {
    Logger.log("=== LOCATION SHARING DEBUG INFO ===", type: "info");
    Logger.log("📊 Basic State:", type: "info");
    Logger.log("  - isSharingLocation: ${isSharingLocation.value}", type: "info");
    Logger.log("  - liveLocation: ${liveLocation.value}", type: "info");
    Logger.log("  - isStreamActive: $_isStreamActive", type: "info");
    Logger.log("  - currentHelpRequestId: ${currentHelpRequestId.value}", type: "info");
    Logger.log("  - isSocketConnected: ${isSocketConnected.value}", type: "info");

    Logger.log("📍 Location State:", type: "info");
    Logger.log("  - hasCurrentPosition: ${currentPosition.value != null}", type: "info");
    if (currentPosition.value != null) {
      Logger.log("  - Current Position: (${currentPosition.value!.latitude}, ${currentPosition.value!.longitude})", type: "info");
    }
    Logger.log("  - lastSentPosition: ${_lastSentPosition != null}", type: "info");

    Logger.log("📡 Socket State:", type: "info");
    final socketService = getActiveSocket();
    Logger.log("  - SocketService found: ${socketService != null}", type: "info");
    if (socketService != null) {
      Logger.log("  - Socket connected: ${socketService.isConnected.value}", type: "info");
    }

    Logger.log("📈 Health Metrics:", type: "info");
    final status = getLocationSharingStatus();
    status.forEach((key, value) {
      Logger.log("  - $key: $value", type: "info");
    });
    Logger.log("  - isHealthy: $isLocationSharingHealthy", type: "info");

    Logger.log("=== END DEBUG INFO ===", type: "info");
  }
}