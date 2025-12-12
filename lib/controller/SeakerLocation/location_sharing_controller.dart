// lib/controller/location_sharing_controller.dart
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';
import '../GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../SeakerHome/seakerHomeController.dart';
import '../SocketService/socket_service.dart';

class LocationSharingController extends GetxController {
  final String role; // 'seeker' or 'giver'
  final String controllerTag;

  LocationSharingController({required this.role, required this.controllerTag});

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
  String get latString => currentPosition.value?.latitude.toString() ?? "";
  String get lngString => currentPosition.value?.longitude.toString() ?? "";
  SocketService? _cachedSocketService;
  DateTime? _socketCacheTime;

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

  Future<void> _forceStopLocationStream() async {
    Logger.log("🛑 [$role] Force stopping location stream...", type: "warning");
    _isStreamActive = false;
    liveLocation.value = false;
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
    try {
      await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, distanceFilter: 0),
      ).listen((_) {}).cancel();
    } catch (e) {}
    await Future.delayed(const Duration(milliseconds: 500));
    Logger.log("✅ [$role] All streams stopped", type: "success");
  }

  SocketService? getActiveSocket() {
    final now = DateTime.now();
    if (_socketCacheTime != null &&
        now.difference(_socketCacheTime!).inSeconds < 2 &&
        _cachedSocketService != null &&
        _cachedSocketService!.isConnected.value) {
      return _cachedSocketService;
    }

    SocketService? socketService;

    if (role == 'seeker') {
      if (Get.isRegistered<SeakerHomeController>()) {
        final controller = Get.find<SeakerHomeController>();
        socketService = controller.socketService;
        if (socketService != null && socketService.isConnected.value) {
          Logger.log("✅ [seeker] Using SeakerHomeController socket", type: "debug");
        }
      }
    } else if (role == 'giver') {
      if (Get.isRegistered<GiverHomeController>()) {
        final controller = Get.find<GiverHomeController>();
        socketService = controller.socketService;
        if (socketService != null && socketService.isConnected.value) {
          Logger.log("✅ [giver] Using GiverHomeController socket", type: "debug");
        }
      }
    }

    if (socketService != null) {
      _cachedSocketService = socketService;
      _socketCacheTime = now;
    } else {
      Logger.log("⚠️ [$role] No active socket found", type: "warning");
    }
    return socketService;
  }

  void setHelpRequestId(String helpRequestId) {
    if (helpRequestId.isNotEmpty) {
      currentHelpRequestId.value = helpRequestId;
      _cachedSocketService = null;
      _socketCacheTime = null;
    }
  }

  void clearHelpRequestId() {
    currentHelpRequestId.value = '';
    _cachedSocketService = null;
    _socketCacheTime = null;
  }

  void forceSocketRefresh() {
    _cachedSocketService = null;
    _socketCacheTime = null;
  }

  void _setupConnectionStateMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isSharingLocation.value) return;
      final socketService = getActiveSocket();
      final wasConnected = isSocketConnected.value;
      final isConnected = socketService != null && socketService.isConnected.value;
      isSocketConnected.value = isConnected;
      if (wasConnected != isConnected && isConnected && currentPosition.value != null) {
        _shareLocation(currentPosition.value!);
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
    lastUpdated.value = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
  }

  Future<bool> handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> getUserLocationOnce() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return;
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentPosition.value = pos;
      _autoShareLocation(pos);
    } catch (e) {
      Logger.log("❌ [$role] Error getting location: $e", type: "error");
    }
  }

  Future<void> startLiveLocation() async {
    Logger.log("🚀 [$role] Starting live location...", type: "info");
    final hasPermission = await handlePermission();
    if (!hasPermission) return;
    if (_isStreamActive || _positionStreamSubscription != null) {
      await _forceStopLocationStream();
    }
    _hasReceivedFirstLocation = false;
    _isStreamActive = false;
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen(
            (Position position) {
          if (!_hasReceivedFirstLocation || position.accuracy <= 50) {
            if (!_hasReceivedFirstLocation) {
              _hasReceivedFirstLocation = true;
              Logger.log("🎯 [$role] First location received!", type: "success");
            }
            currentPosition.value = position;
            _autoShareLocation(position);
          }
        },
        onError: (error) {
          Logger.log("❌ [$role] Stream error: $error", type: "error");
          _isStreamActive = false;
        },
        onDone: () {
          Logger.log("📍 [$role] Stream ended", type: "warning");
          _isStreamActive = false;
          liveLocation.value = false;
        },
        cancelOnError: false,
      );
      _isStreamActive = true;
      liveLocation.value = true;
      _startTimeBasedUpdates();
      Logger.log("✅ [$role] Live location streaming started", type: "success");
    } catch (e, stackTrace) {
      Logger.log("❌ [$role] Failed to start stream: $e", type: "error");
    }
  }

  void resetFirstLocationFlag() {
    _hasReceivedFirstLocation = false;
    Logger.log("📍 [$role] First location flag reset", type: "info");
  }

  void _startTimeBasedUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(milliseconds: _timeThreshold), (timer) {
      if (isSharingLocation.value && currentPosition.value != null && _isStreamActive) {
        _shareLocation(currentPosition.value!);
      }
    });
  }

  String? _getHelpRequestId() {
    if (currentHelpRequestId.value.isNotEmpty) {
      return currentHelpRequestId.value;
    }

    if (role == 'seeker') {
      if (Get.isRegistered<SeakerHomeController>()) {
        final controller = Get.find<SeakerHomeController>();
        final id = controller.currentHelpRequestId.value;
        if (id.isNotEmpty) {
          currentHelpRequestId.value = id;
          return id;
        }
      }
    } else if (role == 'giver') {
      if (Get.isRegistered<GiverHomeController>()) {
        final controller = Get.find<GiverHomeController>();
        final request = controller.acceptedHelpRequest.value;
        final id = request?['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          currentHelpRequestId.value = id;
          return id;
        }
      }
    }

    return null;
  }

  void _shareLocation(Position position) {
    try {
      final helpRequestId = _getHelpRequestId();
      if (helpRequestId == null || helpRequestId.isEmpty) {
        _consecutiveFailures++;
        return;
      }
      final socketService = getActiveSocket();
      if (socketService == null || !socketService.isConnected.value) {
        _consecutiveFailures++;
        isSocketConnected.value = false;
        return;
      }
      isSocketConnected.value = true;
      socketService.sendLocationUpdate(position.latitude, position.longitude);
      _lastSuccessfulUpdate = DateTime.now();
      _consecutiveFailures = 0;
      _lastSentPosition = position;
    } catch (e) {
      _consecutiveFailures++;
    }
  }

  void forceLocationSharingStart() {
    if (currentHelpRequestId.value.isEmpty || currentPosition.value == null) return;
    startLocationSharing();
    shareCurrentLocation();
  }

  void startLocationSharing() {
    isSharingLocation.value = true;
    _lastSentPosition = null;
    _consecutiveFailures = 0;
    if (currentPosition.value != null) {
      _shareLocation(currentPosition.value!);
    }
  }

  void stopLocationSharing() {
    isSharingLocation.value = false;
    _lastSentPosition = null;
    _locationTimer?.cancel();
    _consecutiveFailures = 0;
    _lastSuccessfulUpdate = null;
    _hasReceivedFirstLocation = false;
    _forceStopLocationStream();
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

  bool get isLocationSharingHealthy {
    if (!isSharingLocation.value || currentHelpRequestId.value.isEmpty || !isSocketConnected.value) return false;
    if (_consecutiveFailures >= _maxConsecutiveFailures) return false;
    if (_lastSuccessfulUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastSuccessfulUpdate!);
      if (timeSinceLastUpdate.inSeconds > 60) return false;
    }
    return true;
  }
}