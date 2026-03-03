import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../SocketService/socket_service.dart';
import '../../utils/token_service.dart';
import '../UnifiedHelpController.dart';

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
  Timer? _locationTimer;
  bool _isStreamActive = false;

  SocketService? _cachedSocketService;
  DateTime? _socketCacheTime;

  String get latString => currentPosition.value?.latitude.toString() ?? "";
  String get lngString => currentPosition.value?.longitude.toString() ?? "";

  @override
  void onInit() {
    super.onInit();
    _setupConnectionStateMonitoring();
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    _forceStopLocationStream();
    stopLocationSharing();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOCKET RESOLUTION — now uses UnifiedHelpController only
  // ─────────────────────────────────────────────────────────────────────────
  // SocketService? getActiveSocket() {
  //   final now = DateTime.now();
  //
  //   // Return valid cached socket
  //   if (_socketCacheTime != null &&
  //       now.difference(_socketCacheTime!).inSeconds < 2 &&
  //       _cachedSocketService != null &&
  //       _cachedSocketService!.isConnected.value) {
  //     return _cachedSocketService;
  //   }
  //
  //   // Clear stale/disconnected cache
  //   if (_cachedSocketService != null && !_cachedSocketService!.isConnected.value) {
  //     Logger.log("⚠️ [SOCKET] Cached socket disconnected, clearing", type: "warning");
  //     _cachedSocketService = null;
  //     _socketCacheTime = null;
  //   }
  //
  //   SocketService? socketService;
  //
  //   // PRIMARY: UnifiedHelpController's socket
  //   if (Get.isRegistered<UnifiedHelpController>()) {
  //     final ctrl = Get.find<UnifiedHelpController>();
  //     if (ctrl.socketService != null && ctrl.socketService!.isConnected.value) {
  //       socketService = ctrl.socketService;
  //       Logger.log("[SOCKET] Using UnifiedHelpController socket", type: "debug");
  //     }
  //   }
  //
  //   // FALLBACK: Global SocketService singleton
  //   if (socketService == null && Get.isRegistered<SocketService>()) {
  //     final generalSocket = Get.find<SocketService>();
  //     if (generalSocket.isConnected.value) {
  //       socketService = generalSocket;
  //       Logger.log("[SOCKET] Using global SocketService", type: "debug");
  //     }
  //   }
  //
  //   if (socketService != null) {
  //     _cachedSocketService = socketService;
  //     _socketCacheTime = now;
  //   } else {
  //     Logger.log(" [SOCKET] No active socket found", type: "warning");
  //   }
  //
  //   return socketService;
  // }

  SocketService? getActiveSocket() {
    SocketService? socketService;

    // PRIMARY: UnifiedHelpController's socket
    if (Get.isRegistered<UnifiedHelpController>()) {
      final ctrl = Get.find<UnifiedHelpController>();
      if (ctrl.socketService != null && ctrl.socketService!.isConnected.value) {
        socketService = ctrl.socketService;
        Logger.log("[SOCKET] Using UnifiedHelpController socket", type: "debug");
        return socketService;
      }
    }

    // FALLBACK: Global SocketService singleton
    if (Get.isRegistered<SocketService>()) {
      final generalSocket = Get.find<SocketService>();
      if (generalSocket.isConnected.value) {
        socketService = generalSocket;
        Logger.log("[SOCKET] Using global SocketService", type: "debug");
        return socketService;
      }
    }

    Logger.log("[SOCKET] No active socket found", type: "warning");
    return null;
  }


  // ─────────────────────────────────────────────────────────────────────────
  // HELP REQUEST ID MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────
  void setHelpRequestId(String helpRequestId) {
    if (helpRequestId.isNotEmpty) {
      currentHelpRequestId.value = helpRequestId;
      _cachedSocketService = null;
      _socketCacheTime = null;
      Logger.log("[LOCATION SHARE] Help request ID set: $helpRequestId", type: "success");
    } else {
      Logger.log("[LOCATION SHARE] Attempted to set empty help request ID", type: "warning");
    }
  }

  void clearHelpRequestId() {
    final oldId = currentHelpRequestId.value;
    currentHelpRequestId.value = '';
    _cachedSocketService = null;
    _socketCacheTime = null;
    Logger.log("📍 [LOCATION SHARE] Help request ID cleared (was: $oldId)", type: "info");
  }

  void forceSocketRefresh() {
    _cachedSocketService = null;
    _socketCacheTime = null;
    Logger.log("🔄 [LOCATION SHARE] Socket cache forcibly refreshed", type: "info");
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESOLVE HELP REQUEST ID (checks local, then UnifiedHelpController)
  // ─────────────────────────────────────────────────────────────────────────
  String? _getHelpRequestId() {
    // 1. Locally stored ID
    if (currentHelpRequestId.value.isNotEmpty) {
      return currentHelpRequestId.value;
    }

    // 2. From UnifiedHelpController
    if (Get.isRegistered<UnifiedHelpController>()) {
      final ctrl = Get.find<UnifiedHelpController>();

      // Giver side: accepted request
      final req = ctrl.acceptedRequest.value;
      if (req != null) {
        final id = req['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          currentHelpRequestId.value = id;
          return id;
        }
      }

      // Seeker side: own request
      if (ctrl.seekerHelpRequestId.value.isNotEmpty) {
        final id = ctrl.seekerHelpRequestId.value;
        currentHelpRequestId.value = id;
        return id;
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION SHARING LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────
  void startLocationSharing() {
    isSharingLocation.value = true;
    _lastSentPosition = null;
    _consecutiveFailures = 0;

    final helpRequestId = _getHelpRequestId();
    if (helpRequestId == null || helpRequestId.isEmpty) {
      Logger.log("[LOCATION SHARE] Starting without help request ID", type: "warning");
    } else {
      Logger.log("[LOCATION SHARE] Started for request: $helpRequestId", type: "success");
    }

    if (currentPosition.value != null) {
      _shareLocation(currentPosition.value!);
    }

    Logger.log("[LOCATION SHARE] Location sharing started", type: "success");
  }

  void stopLocationSharing() {
    Logger.log("[STOP] Stopping location sharing...", type: "info");
    isSharingLocation.value = false;
    _lastSentPosition = null;
    _locationTimer?.cancel();
    _consecutiveFailures = 0;
    _lastSuccessfulUpdate = null;
    _hasReceivedFirstLocation = false;
    _forceStopLocationStream();
    Logger.log("[STOP] Location sharing stopped", type: "success");
  }

  Future<void> _forceStopLocationStream() async {
    Logger.log("[STREAM] Force stopping location stream...", type: "warning");
    _isStreamActive = false;
    liveLocation.value = false;
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      Logger.log("[STREAM] Subscription cancelled", type: "success");
    }
    await Future.delayed(const Duration(milliseconds: 300));
    Logger.log("[STREAM] All streams stopped", type: "success");
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIVE LOCATION STREAM
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> startLiveLocation() async {
    Logger.log("🚀 [STREAM] Starting live location...", type: "info");

    final hasPermission = await handlePermission();
    if (!hasPermission) {
      Logger.log("[STREAM] No location permission", type: "error");
      return;
    }

    if (_isStreamActive || _positionStreamSubscription != null) {
      Logger.log("⚠[STREAM] Existing stream detected, stopping first...", type: "warning");
      await _forceStopLocationStream();
    }

    _hasReceivedFirstLocation = false;
    _isStreamActive = false;
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      Logger.log("📡 [STREAM] Creating new position stream...", type: "info");

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
            (Position position) {
          if (!_hasReceivedFirstLocation || position.accuracy <= 50) {
            if (!_hasReceivedFirstLocation) {
              _hasReceivedFirstLocation = true;
              Logger.log("🎯 [STREAM] First location received!", type: "success");
            }
            currentPosition.value = position;
            Logger.log(
              "📍 Live location: (${position.latitude}, ${position.longitude}) - Accuracy: ${position.accuracy}m",
              type: "debug",
            );
            _autoShareLocation(position);
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
    } catch (e) {
      Logger.log("❌ [STREAM] Failed to start: $e", type: "error");
      _isStreamActive = false;
      liveLocation.value = false;
    }
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

  void resetFirstLocationFlag() {
    _hasReceivedFirstLocation = false;
    Logger.log("📍 First location flag reset", type: "info");
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARE LOCATION — send via socket
  // ─────────────────────────────────────────────────────────────────────────
  void _shareLocation(Position position) {
    try {
      // Check if still sharing
      if (!isSharingLocation.value) {
        Logger.log("[SHARE] Location sharing stopped — skipping update", type: "info");
        return;
      }

      final helpRequestId = _getHelpRequestId();
      if (helpRequestId == null) {
        Logger.log("[SHARE] No help request ID — skipping update", type: "warning");
        _consecutiveFailures++;
        return;
      }

      final socketService = getActiveSocket();
      if (socketService == null) {
        Logger.log("[SHARE] No socket service — retrying in 2s", type: "warning");
        _consecutiveFailures++;
        // Retry after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (isSharingLocation.value) _shareLocation(position);
        });
        return;
      }

      // Check socket connection
      if (!socketService.isConnected.value) {
        Logger.log("[SHARE] Socket disconnected — reconnecting", type: "error");
        socketService.reconnect();
        _consecutiveFailures++;
        // Retry after reconnection
        Future.delayed(const Duration(seconds: 3), () {
          if (isSharingLocation.value) _shareLocation(position);
        });
        return;
      }

      if (socketService.currentRoom != helpRequestId) {
        Logger.log("[SHARE] Wrong room (${socketService.currentRoom}), joining: $helpRequestId", type: "warning");
        socketService.joinRoom(helpRequestId).then((_) {
          Logger.log("[SHARE] Room joined successfully", type: "success");
          Future.delayed(const Duration(milliseconds: 300), () {
            _shareLocation(position);
          });
        }).catchError((e) {
          Logger.log("[SHARE] Failed to join room: $e", type: "error");
          _consecutiveFailures++;
        });
        return;
      }

      // Location send
      Logger.log("[SHARE] Sending location: (${position.latitude}, ${position.longitude})", type: "debug");
      socketService.sendLocationUpdate(position.latitude, position.longitude);
      _lastSentPosition = position;
      _lastSuccessfulUpdate = DateTime.now();
      _consecutiveFailures = 0;
      Logger.log("[SHARE] Location sent successfully", type: "success");

    } catch (e) {
      _consecutiveFailures++;
      Logger.log("[SHARE] Error: $e", type: "error");
      // Auto retry with limit
      if (_consecutiveFailures < 3) {
        Logger.log("[SHARE] Retrying in 2s (attempt $_consecutiveFailures/3)", type: "warning");
        Future.delayed(const Duration(seconds: 2), () {
          if (isSharingLocation.value) _shareLocation(position);
        });
      } else {
        Logger.log("[SHARE] Too many failures — stopping location sharing", type: "error");
        stopLocationSharing();
      }
    }
  }

  void _autoShareLocation(Position newPosition) {
    if (!isSharingLocation.value) return;
    if (_shouldSendUpdate(newPosition)) {
      _shareLocation(newPosition);
    }
  }

  bool _shouldSendUpdate(Position newPosition) {
    if (_lastSentPosition == null) return true;
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
    }
  }

  void forceLocationSharingStart() {
    if (currentHelpRequestId.value.isEmpty) return;
    if (currentPosition.value == null) return;
    forceSocketRefresh();
    startLocationSharing();
    shareCurrentLocation();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONNECTION MONITORING
  // ─────────────────────────────────────────────────────────────────────────
  void _setupConnectionStateMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isSharingLocation.value) return;

      final socketService = getActiveSocket();
      final wasConnected = isSocketConnected.value;
      final isConnected = socketService != null && socketService.isConnected.value;
      isSocketConnected.value = isConnected;

      if (wasConnected != isConnected) {
        if (isConnected) {
          Logger.log("[CONNECTION] Socket restored — rejoining room", type: "success");
          rejoinRoomIfNeeded();
          if (currentPosition.value != null) {
            Logger.log("[CONNECTION] Sending buffered location after reconnect", type: "info");
            _shareLocation(currentPosition.value!);
          }
        } else {
          Logger.log("[CONNECTION] Socket lost — will retry", type: "warning");
        }
      }

      // Enhanced: Check for stale connections
      if (!isConnected && isSharingLocation.value) {
        Logger.log("[CONNECTION] Location sharing active but socket disconnected", type: "warning");
        // Attempt recovery
        if (_consecutiveFailures < 5) {
          Logger.log("[CONNECTION] Attempting socket recovery...", type: "info");
          socketService?.reconnect();
        }
      }

      // Check for location staleness
      if (_lastSuccessfulUpdate != null &&
          DateTime.now().difference(_lastSuccessfulUpdate!).inSeconds > 30) {
        Logger.log("[CONNECTION] Location update stale (>30s) — forcing refresh", type: "warning");
        if (currentPosition.value != null) {
          _shareLocation(currentPosition.value!);
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROOM MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> rejoinRoomIfNeeded() async {
    final helpRequestId = currentHelpRequestId.value;
    if (helpRequestId.isEmpty) return;

    final socketService = getActiveSocket();
    if (socketService == null) return;

    if (socketService.currentRoom == helpRequestId) {
      Logger.log("[ROOM] Already in room: $helpRequestId", type: "info");
      return;
    }

    Logger.log("[ROOM] Rejoining: $helpRequestId", type: "info");
    await socketService.joinRoom(helpRequestId);
    await Future.delayed(const Duration(milliseconds: 500));
    Logger.log("[ROOM] Rejoined: $helpRequestId", type: "success");
  }

  Future<void> refreshAfterMapReturn() async {
    Logger.log("[MAP RETURN] Refreshing...", type: "info");

    // Cache clear
    _cachedSocketService = null;
    _socketCacheTime = null;

    // Wait for socket ready (max 5 seconds)
    int waited = 0;
    while (getActiveSocket() == null && waited < 5000) {
      await Future.delayed(const Duration(milliseconds: 300));
      waited += 300;
    }

    final socketService = getActiveSocket();
    if (socketService == null) {
      Logger.log("[MAP RETURN] Socket not available", type: "error");
      return;
    }

    // Room rejoin
    if (currentHelpRequestId.value.isNotEmpty) {
      await rejoinRoomIfNeeded();
      await Future.delayed(const Duration(milliseconds: 500));
      if (currentPosition.value != null) {
        _shareLocation(currentPosition.value!);
      }
    }
  }

  Future<void> refreshSocketAndRejoinRoom() async {
    forceSocketRefresh();
    await Future.delayed(const Duration(milliseconds: 200));
    await rejoinRoomIfNeeded();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION PERMISSION & ONE-TIME
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> handlePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<void> getUserLocationOnce() async {
    if (!await handlePermission()) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = pos;
      _autoShareLocation(pos);
    } catch (e) {
      Logger.log("❌ Error getting location: $e", type: "error");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADDRESS / UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  RxString addressText = "".obs;
  RxString lastUpdated = "".obs;

  Future<void> updateLocation(Position pos) async {
    currentPosition.value = pos;
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        addressText.value = "${p.street}, ${p.locality}, ${p.country}";
      }
    } catch (_) {
      addressText.value = "Unable to get address";
    }
    lastUpdated.value =
    "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  bool get isLocationSharingHealthy {
    if (!isSharingLocation.value) return false;
    if (currentHelpRequestId.value.isEmpty) return false;
    if (!isSocketConnected.value) return false;
    if (_consecutiveFailures >= _maxConsecutiveFailures) return false;
    if (_lastSuccessfulUpdate != null &&
        DateTime.now().difference(_lastSuccessfulUpdate!).inSeconds > 60) return false;
    return true;
  }

  String get sharingStatus {
    if (!isSharingLocation.value) return "Not Sharing";
    if (!Get.isRegistered<UnifiedHelpController>()) return "Sharing Location";
    final ctrl = Get.find<UnifiedHelpController>();
    switch (ctrl.screenMode.value) {
      case HelpScreenMode.seekerWaiting:
        return "Sharing with Helper";
      case HelpScreenMode.giverHelping:
        return "Sharing with Seeker";
      default:
        return "Sharing Location";
    }
  }

  bool shouldShareLocation() {
    if (!Get.isRegistered<UnifiedHelpController>()) return false;
    final mode = Get.find<UnifiedHelpController>().screenMode.value;
    return isSharingLocation.value &&
        (mode == HelpScreenMode.seekerWaiting || mode == HelpScreenMode.giverHelping);
  }

  Future<void> checkAndEnableAutoSharing() async {
    if (await handlePermission() && !liveLocation.value) {
      await startLiveLocation();
      startLocationSharing();
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
    if (enable) startLocationSharing();
    else stopLocationSharing();
    await saveAutoSharingPreference(enable);
  }
}