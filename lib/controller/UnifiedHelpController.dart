import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:saferader/utils/api_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:vibration/vibration.dart';
import '../../Models/HelpRequestResponse.dart';
import '../../Service/Firebase/notifications.dart';
import '../../controller/SeakerLocation/seakerLocationsController.dart';
import '../../controller/SocketService/socket_service.dart';
import '../../controller/UserController/userController.dart';
import '../../controller/networkService/networkService.dart';
import '../../utils/auth_service.dart';
import '../Service/Backgound/background_services.dart';
import 'notifications/notifications_controller.dart';


// ─────────────────────────────────────────────────────────────────────────────
// HelpMode enum: clarifies what the screen should show
// ─────────────────────────────────────────────────────────────────────────────
enum HelpScreenMode {
  idle,           // 0 – default home (toggle available to help here)
  seekerSending,  // 1 – user sent help request, waiting for a helper
  seekerWaiting,  // 2 – helper accepted, help is on the way (seeker view)
  giverSearching, // 3 – user is available and has incoming request cards
  giverHelping,   // 4 – user accepted a request, going to help someone
}

// ─────────────────────────────────────────────────────────────────────────────
// NearbyStats model
// ─────────────────────────────────────────────────────────────────────────────
class NearbyStats {
  final int km1;
  final int km2;
  final int km3;
  NearbyStats({required this.km1, required this.km2, required this.km3});
}

// ─────────────────────────────────────────────────────────────────────────────
// UnifiedHelpController
// Single controller for the entire help flow (seeker + giver)
// ─────────────────────────────────────────────────────────────────────────────
class UnifiedHelpController extends GetxController {
  // ── Dependencies ────────────────────────────────────────────────────────────
  final UserController userController = Get.find<UserController>();
  SocketService? _socketService;

  SocketService? get socketService => _socketService;

  // ── Screen State ────────────────────────────────────────────────────────────
  /// Current screen mode — drives UI rendering in a single switch statement
  Rx<HelpScreenMode> screenMode = HelpScreenMode.idle.obs;

  /// Whether this user has toggled "I am available to help"
  RxBool helperStatus = false.obs;

  // ── Seeker State (when this user asked for help) ─────────────────────────
  RxString seekerHelpRequestId = ''.obs;
  Rx<NearbyStats> nearbyStats = NearbyStats(km1: 0, km2: 0,km3:0).obs;

  /// Position of the helper coming to ME (I am the seeker)
  Rxn<Position> incomingHelperPosition = Rxn<Position>();
  RxString incomingHelperName = ''.obs;
  RxString incomingHelperImage = ''.obs;
  RxString seekerToHelperDistance = 'Calculating...'.obs;
  RxString seekerToHelperEta = 'Calculating...'.obs;

  // ── Giver State (when this user is helping someone) ─────────────────────
  /// List of incoming help requests shown as cards (giver mode)
  RxList<Map<String, dynamic>> pendingRequests = <Map<String, dynamic>>[].obs;

  /// The ONE request this user has accepted to help with
  Rxn<Map<String, dynamic>> acceptedRequest = Rxn<Map<String, dynamic>>();

  /// Live position of the seeker I accepted to help
  Rxn<Position> seekerLivePosition = Rxn<Position>();

  // ── Profile / UI helpers ─────────────────────────────────────────────────
  RxString profileImage = ''.obs;
  RxString firstName = ''.obs;
  RxString lastName = ''.obs;

  // ── Internal ─────────────────────────────────────────────────────────────
  bool _isVibrating = false;
  AudioPlayer? _audioPlayer;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnect = 5;

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _setupLocationDistanceListener();
    loadUserData();
    fetchUserProfile();
    _startHealthMonitoring();        // Start health monitoring

    // Process any pending help requests from notifications
    Future.delayed(const Duration(milliseconds: 500), () {
      NotificationService.processPendingNotification();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOCKET INIT
  // ─────────────────────────────────────────────────────────────────────────
  bool _isInitializingSocket = false;
  DateTime? _lastInitTime;
  static const _minInitInterval = Duration(seconds: 5);

  Future<void> initSocket() async {
    // Prevent concurrent init attempts
    if (_isInitializingSocket) {
      Logger.log('⏳ [SOCKET] Init already in progress, skipping', type: 'info');
      return;
    }

    // Debounce rapid init calls
    final now = DateTime.now();
    if (_lastInitTime != null && now.difference(_lastInitTime!) < _minInitInterval) {
      Logger.log('⏱️ [SOCKET] Too soon since last init, skipping', type: 'info');
      return;
    }

    _isInitializingSocket = true;
    _lastInitTime = now;

    try {
      final token = await TokenService().getToken();
      if (token == null || token.isEmpty) {
        Logger.log('No token — cannot init socket', type: 'error');
        _isInitializingSocket = false;
        return;
      }

      // Reuse existing SocketService if already registered
      if (Get.isRegistered<SocketService>()) {
        final existing = Get.find<SocketService>();
        _socketService = existing;
        existing.updateRole('both');

        // Only setup listeners if not already setup
        if (_socketService!.isConnected.value) {
          Logger.log('✅ [UNIFIED] Socket already connected, reusing', type: 'success');
          _isInitializingSocket = false;
          return;
        }

        _removeAllListeners();
        _setupSocketListeners();
        Logger.log('✅ [UNIFIED] Reusing existing SocketService', type: 'success');
        _isInitializingSocket = false;
        return;
      }

      // Fresh init
      Logger.log('🔄 [SOCKET] Initializing new socket connection...', type: 'info');
      _socketService = await Get.putAsync(
            () => SocketService().init(token, role: 'both'),
        permanent: true,
      );

      if (_socketService != null) {
        _removeAllListeners();
        _setupSocketListeners();

        _socketService!.socket.onConnect((_) async {
          Logger.log('[UNIFIED] Socket connected/reconnected', type: 'success');
          await Future.delayed(const Duration(milliseconds: 300));

          _rejoinRoomAfterReconnect();
          if (helperStatus.value) {
            await _syncAvailabilityToServer(true);
          }
        });

        Logger.log('[UNIFIED] Socket initialized', type: 'success');
      }
    } catch (e) {
      Logger.log('[UNIFIED] Socket init error: $e', type: 'error');
    } finally {
      _isInitializingSocket = false;
    }
  }

  void _tryReconnect() {
    if (_reconnectAttempts >= _maxReconnect) return;
    _reconnectAttempts++;
    _socketService?.reconnect();
    Logger.log('🔄 [UNIFIED] Reconnect attempt $_reconnectAttempts', type: 'info');
  }

  void _rejoinRoomAfterReconnect() {
    _reconnectAttempts = 0;

    // Rejoin seeker room
    if (seekerHelpRequestId.value.isNotEmpty) {
      final id = seekerHelpRequestId.value;
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _socketService?.joinRoom(id);
        _resumeLocationSharing(id);
      });
    }

    //<---->  Rejoin giver room <----->
    final req = acceptedRequest.value;
    if (req != null) {
      final id = req['_id']?.toString() ?? '';
      if (id.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          await _socketService?.joinRoom(id);
          _resumeLocationSharing(id);
        });
      }
    }
  }

  // <─────────────────────────────────────────────────────────────────────────>
  // SOCKET LISTENERS
  // <─────────────────────────────────────────────────────────────────────────>
  void _removeAllListeners() {
    final events = [
      'giver_newHelpRequest',
      'helpRequestAccepted',
      'receiveLocationUpdate',
      'giver_receiveLocationUpdate',
      'helpRequestCancelled',
      'giver_helpRequestCancelled',
      'helpRequestCompleted',
      'giver_helpRequestCompleted',
      'connect',
    ];
    for (final e in events) {
      _socketService?.socket.off(e);
    }

    Logger.log('🎧 [UNIFIED] All socket listeners removed', type: 'info');
  }

  void _setupSocketListeners() {
    if (_socketService == null) return;
    Logger.log('🎧 [UNIFIED] Setting up socket listeners', type: 'info');

    // ── GIVER: New incoming help request ──────────────────────────────────
    _socketService!.socket.on('giver_newHelpRequest', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      Logger.log('🆘 [UNIFIED] New help request received', type: 'info');
      _onNewHelpRequest(data);
    });

    // ── SEEKER: Someone accepted MY request ──────────────────────────────
    _socketService!.socket.on('helpRequestAccepted', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      Logger.log('❤️ [UNIFIED] Help request accepted', type: 'success');
      _onHelpRequestAccepted(data);
    });

    // ── SEEKER: Giver location update (helper coming to me) ──────────────
    _socketService!.socket.on('receiveLocationUpdate', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      _onReceiveHelperLocation(data);
    });

    // ── GIVER: Seeker location update (seeker I'm going to) ──────────────
    _socketService!.socket.on('giver_receiveLocationUpdate', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      Logger.log('📍 [UNIFIED] Seeker location update received', type: 'info');
      _onReceiveSeekerLocation(data);
    });

    // ── SEEKER: Help request cancelled by system/seeker ──────────────────
    _socketService!.socket.on('helpRequestCancelled', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      Logger.log('⛔ [UNIFIED] Seeker: help request cancelled', type: 'warning');
      _onSeekerRequestCancelled(data);
    });

    // ── GIVER: The request I was going to help was cancelled ─────────────
    _socketService!.socket.on('giver_helpRequestCancelled', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      Logger.log('⛔ [UNIFIED] Giver: help request cancelled', type: 'warning');
      _onGiverRequestCancelled(data);
    });

    // ── SEEKER: Help completed ────────────────────────────────────────────
    _socketService!.socket.on('helpRequestCompleted', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      _resetSeekerState();
    });

    // ── GIVER: Request completed ──────────────────────────────────────────
    _socketService!.socket.on('giver_helpRequestCompleted', (data) {
      if (!Get.isRegistered<UnifiedHelpController>()) return;
      _onGiverRequestCompleted(data);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOCKET EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void _onNewHelpRequest(dynamic data) {
    try {
      stopVibration();
      final request = data as Map<String, dynamic>;
      // Avoid duplicate
      final id = request['_id']?.toString() ?? '';
      if (id.isNotEmpty && pendingRequests.any((r) => r['_id'] == id)) return;

      pendingRequests.add(request);

      // Switch to giver searching mode if idle or already in giver mode
      if (screenMode.value == HelpScreenMode.idle ||
          screenMode.value == HelpScreenMode.giverSearching) {
        screenMode.value = HelpScreenMode.giverSearching;
      }

      emergencyVibration();
      Logger.log('[UNIFIED] Pending requests: ${pendingRequests.length}', type: 'success');
    } catch (e) {
      Logger.log('[UNIFIED] _onNewHelpRequest error: $e', type: 'error');
    }
  }

  Future<void> _onHelpRequestAccepted(dynamic data) async {
    try {
      stopVibration();
      final requestData = data as Map<String, dynamic>;
      final helpRequest = requestData['helpRequest'] as Map<String, dynamic>?;
      final giverLocationData = requestData['giverLocation'] as Map<String, dynamic>?;

      if (helpRequest == null) return;
      final helpRequestId = helpRequest['_id']?.toString() ?? '';
      if (helpRequestId.isEmpty) return;

      // Extract helper info
      final helper = requestData['helper'] as Map<String, dynamic>? ??
          helpRequest['helper'] as Map<String, dynamic>?;
      incomingHelperName.value = helper?['name']?.toString() ?? 'Helper';
      incomingHelperImage.value = helper?['profileImage']?.toString() ?? '';

      // Update screen mode (seeker: helper is coming)
      screenMode.value = HelpScreenMode.seekerWaiting;

      // Set initial helper position if provided
      if (giverLocationData != null) {
        final lat = _safeDouble(giverLocationData['latitude']);
        final lng = _safeDouble(giverLocationData['longitude']);
        if (lat != null && lng != null) {
          incomingHelperPosition.value = _makePosition(lat, lng);
          _recalcSeekerDistanceEta();
        }
      }

      // Join socket room
      final locCtrl = _getLocationController();
      locCtrl?.setHelpRequestId(helpRequestId);
      await _socketService?.joinRoom(helpRequestId);

      // Start sharing my location so the helper can track me
      await _startLocationSharing(helpRequestId);

      Logger.log('[UNIFIED] Seeker: help accepted, sharing location', type: 'success');
    } catch (e) {
      Logger.log('[UNIFIED] _onHelpRequestAccepted: $e', type: 'error');
    }
  }

  void _onReceiveHelperLocation(dynamic data) {
    try {
      final loc = _parseLocationData(data);
      if (loc == null) return;
      incomingHelperPosition.value = _makePosition(loc['lat']!, loc['lng']!);
      _recalcSeekerDistanceEta();
    } catch (e) {
      Logger.log('[UNIFIED] _onReceiveHelperLocation: $e', type: 'error');
    }
  }

  void _onReceiveSeekerLocation(dynamic data) {
    try {
      final loc = _parseLocationData(data);
      if (loc == null) return;
      seekerLivePosition.value = _makePosition(loc['lat']!, loc['lng']!);
      _recalcGiverDistanceEta();
    } catch (e) {
      Logger.log('[UNIFIED] _onReceiveSeekerLocation: $e', type: 'error');
    }
  }

  void _onSeekerRequestCancelled(dynamic data) {
    final cancelledId = _extractId(data);
    if (cancelledId.isEmpty || cancelledId == seekerHelpRequestId.value) {
      _resetSeekerState();
    }
  }

  void _onGiverRequestCancelled(dynamic data) {
    final cancelledId = _extractId(data);
    final myAccepted = acceptedRequest.value?['_id']?.toString() ?? '';

    // Remove from pending list
    if (cancelledId.isNotEmpty) {
      pendingRequests.removeWhere((r) => r['_id'] == cancelledId);
    }

    // If it's the request I accepted, reset giver state
    if (cancelledId.isEmpty || cancelledId == myAccepted) {
      _resetGiverState();
    }

    if (pendingRequests.isEmpty && acceptedRequest.value == null) {
      screenMode.value = HelpScreenMode.idle;
      stopVibration();
    }
  }

  void _onGiverRequestCompleted(dynamic data) {
    final completedId = _extractId(data);
    pendingRequests.removeWhere((r) => r['_id'] == completedId);
    final myAccepted = acceptedRequest.value?['_id']?.toString() ?? '';
    if (completedId.isEmpty || completedId == myAccepted) {
      _resetGiverState();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC ACTIONS — SEEKER (I need help)
  // ─────────────────────────────────────────────────────────────────────────

  /// Send help request to server
  Future<void> sendHelpRequest(double latitude, double longitude) async {
    if (_socketService == null) await initSocket();

    // Wait for socket if needed
    int attempts = 0;
    while (_socketService?.isConnected.value != true && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    final networkCtrl = Get.find<NetworkController>();
    if (!networkCtrl.isOnline.value) {
      Logger.log('📵 [UNIFIED] No internet', type: 'error');
      return;
    }

    screenMode.value = HelpScreenMode.seekerSending;

    try {
      final response = await ApiService().post(
        endpoint:'/api/help-requests',
        requiresAuth: true,
        body: {'latitude': latitude, 'longitude': longitude},
      ).timeout(const Duration(seconds: 30));

      if (response != null) {

        final parsed = HelpRequestResponse.fromJson(
          response is String ? jsonDecode(response as String) : Map<String, dynamic>.from(response as Map),
        );
        seekerHelpRequestId.value = parsed.data.id;
        nearbyStats.value = NearbyStats(
          km1: parsed.nearbyStats.km1,
          km2: parsed.nearbyStats.km2,
          km3: parsed.nearbyStats.km3,
        );
        Logger.log('[UNIFIED] Help request created: ${parsed.data.id} \n data: $nearbyStats', type: 'success');
      } else {
        screenMode.value = HelpScreenMode.idle;
        Logger.log('[UNIFIED] Help request failed: ${response}', type: 'error');
      }
    } catch (e) {
      screenMode.value = HelpScreenMode.idle;
      Logger.log('[UNIFIED] sendHelpRequest error: $e', type: 'error');
    }
  }

  /// Cancel my own help request
  Future<void> cancelMyHelpRequest() async {
    stopVibration();
    if (seekerHelpRequestId.value.isEmpty) return;

    try {
      final response = await ApiService().post(
        endpoint: '/api/help-requests/${seekerHelpRequestId.value}/cancel',
        requiresAuth: true,
      ).timeout(const Duration(seconds: 30));

      if (response != 204) {
        Logger.log('[UNIFIED] Help request cancelled', type: 'success');
      }else{

      }

    } catch (e) {
      Logger.log('[UNIFIED] cancelMyHelpRequest error: $e', type: 'error');
    } finally {
      _resetSeekerState();
    }
  }

  /// Mark help as completed from seeker side
  Future<void> seekerMarkHelpDone() async {
    try {
      final id = seekerHelpRequestId.value;
      if (id.isNotEmpty) {
        _socketService?.socket.emit('completeHelpRequest', id);
        _socketService?.leaveRoom(id);
      }
    } finally {
      _resetSeekerState();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC ACTIONS — GIVER (I help someone)
  // ─────────────────────────────────────────────────────────────────────────

  /// Accept an incoming help request
  Future<void> acceptRequest(String requestId) async {
    stopVibration();
    final idx = pendingRequests.indexWhere((r) => r['_id'] == requestId);
    if (idx == -1) return;

    final req = pendingRequests[idx];
    acceptedRequest.value = req;
    pendingRequests.removeAt(idx);
    screenMode.value = HelpScreenMode.giverHelping;

    // Emit to server
    _socketService?.socket.emit('acceptHelpRequest', requestId);
    await _socketService?.joinRoom(requestId);

    // Start sharing MY location so the seeker can track me
    final locCtrl = _getLocationController();
    if (locCtrl != null) {
      locCtrl.stopLocationSharing();
      locCtrl.clearHelpRequestId();
      await Future.delayed(const Duration(milliseconds: 500));
      locCtrl.setHelpRequestId(requestId);
      locCtrl.forceSocketRefresh();
      locCtrl.resetFirstLocationFlag();
      locCtrl.startLocationSharing();
      await locCtrl.startLiveLocation();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (locCtrl.currentPosition.value != null) {
        locCtrl.shareCurrentLocation();
      }
    }

    Logger.log('[UNIFIED] Accepted request $requestId', type: 'success');
  }

  /// Decline an incoming help request
  void declineRequest(String requestId) {
    stopVibration();
    _socketService?.declineHelpRequest(requestId);
    pendingRequests.removeWhere((r) => r['_id'] == requestId);
    if (pendingRequests.isEmpty && acceptedRequest.value == null) {
      screenMode.value = HelpScreenMode.idle;
    }
    Logger.log('[UNIFIED] Declined request $requestId', type: 'info');
  }

  /// Giver cancels the request they accepted (leave/cancel)
  void giverCancelHelp(String requestId) {
    try {
      final locCtrl = _getLocationController();
      locCtrl?.stopLocationSharing();
      locCtrl?.clearHelpRequestId();
      _socketService?.socket.emit('leaveHelpRequestRoom', requestId);
      _socketService?.leaveRoom(requestId);
    } finally {
      _resetGiverState();
    }
  }

  /// Giver marks work as done
  void giverMarkDone(String requestId) {
    try {
      final locCtrl = _getLocationController();
      locCtrl?.stopLocationSharing();
      locCtrl?.clearHelpRequestId();
      _socketService?.socket.emit('completeHelpRequest', requestId);
      _socketService?.leaveRoom(requestId);
      if (_socketService?.isConnected.value == true) {
        _socketService!.socket.emit('leaveHelpRequestRoom', requestId);
      }
      Logger.log('[UNIFIED] Giver marked work done', type: 'success');
    } finally {
      _resetGiverState();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER AVAILABILITY TOGGLE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setHelperAvailability(bool isAvailable) async {
    helperStatus.value = isAvailable;
    try {
      await _syncAvailabilityToServer(isAvailable);
    } catch (e) {
      helperStatus.value = !isAvailable;
      Logger.log('[UNIFIED] setHelperAvailability error: $e', type: 'error');
    }
  }

  Future<void> _syncAvailabilityToServer(bool isAvailable) async {
    final resp = await ApiService().put(
      endpoint: '/api/users/me/availability',
      requiresAuth: true,
      body: {'isAvailable': isAvailable},
    );

    if (resp == null) {
      throw Exception('Availability sync failed: server returned null');
    }

    if (isAvailable) {
      final locCtrl = _getLocationController();
      if (locCtrl != null) {
        if (!locCtrl.liveLocation.value) {
          await locCtrl.startLiveLocation();
          await Future.delayed(const Duration(milliseconds: 500));
        }
        final pos = locCtrl.currentPosition.value;
        if (pos != null) {
          await ApiService().put(endpoint: '/api/users/me/location',
              requiresAuth: true,
              body: {
            'latitude': pos.latitude,
            'longitude': pos.longitude,
          });
        }
        locCtrl.startLocationSharing();
      }
    } else {
      _getLocationController()?.stopLocationSharing();
    }
    Logger.log('[UNIFIED] Availability synced: $isAvailable', type: 'success');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION INJECTION
  // Called when a push notification arrives and the giver taps it
  // ─────────────────────────────────────────────────────────────────────────
  void injectHelpRequestFromNotification(Map<String, dynamic> data) {
    try {
      final requestId = data['helpRequestId']?.toString();
      if (requestId == null || requestId.isEmpty) return;

      if (pendingRequests.any((r) => r['_id'] == requestId)) return;

      final request = {
        '_id': requestId,
        'seeker': {
          'name': data['seekerName'] ?? 'Someone',
          'profileImage': data['seekerImage'] ?? '',
          '_id': data['seekerId'] ?? '',
        },
        'location': {
          'type': 'Point',
          'coordinates': [
            double.tryParse(data['longitude'] ?? '0') ?? 0.0,
            double.tryParse(data['latitude'] ?? '0') ?? 0.0,
          ],
        },
        'distance': data['distance'] ?? 'Calculating...',
        'eta': data['eta'] ?? 'Calculating...',
        'createdAt': DateTime.now().toIso8601String(),
      };

      pendingRequests.add(request);
      screenMode.value = HelpScreenMode.giverSearching;

      if (_socketService == null || !_socketService!.isConnected.value) {
        initSocket();
      }

      emergencyVibration();
      Logger.log('[UNIFIED] Help request injected from notification: $requestId', type: 'success');
    } catch (e) {
      Logger.log('[UNIFIED] injectHelpRequestFromNotification: $e', type: 'error');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISTANCE / ETA CALCULATIONS
  // ─────────────────────────────────────────────────────────────────────────

  void _setupLocationDistanceListener() {
    try {
      final locCtrl = Get.isRegistered<SeakerLocationsController>()
          ? Get.find<SeakerLocationsController>()
          : Get.put(SeakerLocationsController(), permanent: true);

      ever(locCtrl.currentPosition, (pos) {
        if (pos == null) return;
        // Seeker view: recalc distance to incoming helper
        if (incomingHelperPosition.value != null) _recalcSeekerDistanceEta();
        // Giver view: recalc distance to seeker I'm helping
        if (seekerLivePosition.value != null) _recalcGiverDistanceEta();
      });
    } catch (e) {
      Logger.log('[UNIFIED] _setupLocationDistanceListener: $e', type: 'error');
    }
  }

  void _recalcSeekerDistanceEta() {
    try {
      final myPos = _getLocationController()?.currentPosition.value;
      final helperPos = incomingHelperPosition.value;
      if (myPos == null || helperPos == null) return;

      final dist = Geolocator.distanceBetween(
        myPos.latitude, myPos.longitude,
        helperPos.latitude, helperPos.longitude,
      );
      seekerToHelperDistance.value = '${(dist / 1000).toStringAsFixed(2)} km';
      seekerToHelperEta.value = '${((dist / 1000) / 30 * 60).toStringAsFixed(0)} min';
    } catch (e) {
      Logger.log('[UNIFIED] _recalcSeekerDistanceEta: $e', type: 'error');
    }
  }

  void _recalcGiverDistanceEta() {
    try {
      final myPos = _getLocationController()?.currentPosition.value;
      final seekerPos = seekerLivePosition.value;
      if (myPos == null || seekerPos == null || acceptedRequest.value == null) return;

      final dist = Geolocator.distanceBetween(
        myPos.latitude, myPos.longitude,
        seekerPos.latitude, seekerPos.longitude,
      );

      final updated = Map<String, dynamic>.from(acceptedRequest.value!);
      updated['distance'] = '${(dist / 1000).toStringAsFixed(2)} km';
      updated['eta'] = '${((dist / 1000) / 30 * 60).toStringAsFixed(0)} min';
      acceptedRequest.value = updated;
    } catch (e) {
      Logger.log('[UNIFIED] _recalcGiverDistanceEta: $e', type: 'error');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION SHARING HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _startLocationSharing(String helpRequestId) async {
    final locCtrl = _getLocationController();
    if (locCtrl == null) return;

    if (locCtrl.isSharingLocation.value &&
        locCtrl.currentHelpRequestId.value == helpRequestId) return;

    locCtrl.setHelpRequestId(helpRequestId);
    if (!locCtrl.liveLocation.value) {
      await locCtrl.startLiveLocation();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    locCtrl.startLocationSharing();
    Logger.log('📍 [UNIFIED] Location sharing started for $helpRequestId', type: 'success');
  }

  void _resumeLocationSharing(String helpRequestId) {
    final locCtrl = _getLocationController();
    if (locCtrl == null) return;
    locCtrl.setHelpRequestId(helpRequestId);
    if (!locCtrl.isSharingLocation.value) locCtrl.startLocationSharing();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATE RESET
  // ─────────────────────────────────────────────────────────────────────────

  void _resetSeekerState() {
    stopVibration();
    final id = seekerHelpRequestId.value;
    if (id.isNotEmpty) {
      _socketService?.leaveRoom(id);
      _getLocationController()?.clearHelpRequestId();
      _getLocationController()?.stopLocationSharing();
    }
    seekerHelpRequestId.value = '';
    incomingHelperPosition.value = null;
    incomingHelperName.value = '';
    incomingHelperImage.value = '';
    seekerToHelperDistance.value = 'Calculating...';
    seekerToHelperEta.value = 'Calculating...';
    screenMode.value = HelpScreenMode.idle;
    Logger.log('🔄 [UNIFIED] Seeker state reset', type: 'info');
  }

  void _resetGiverState() {
    stopVibration();
    acceptedRequest.value = null;
    seekerLivePosition.value = null;
    if (pendingRequests.isEmpty) {
      screenMode.value = HelpScreenMode.idle;
    } else {
      screenMode.value = HelpScreenMode.giverSearching;
    }
    Logger.log('🔄 [UNIFIED] Giver state reset', type: 'info');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPUTED GETTERS (for UI convenience)
  // ─────────────────────────────────────────────────────────────────────────

  /// Seeker view: name of helper coming to me
  String get helperName => incomingHelperName.value;

  /// Giver view: name of seeker I accepted
  String get acceptedSeekerName {
    final s = acceptedRequest.value?['seeker'] as Map<String, dynamic>?;
    return s?['name']?.toString() ?? 'Someone';
  }

  String get acceptedSeekerImage {
    final s = acceptedRequest.value?['seeker'] as Map<String, dynamic>?;
    return s?['profileImage']?.toString() ?? '';
  }

  String get acceptedRequestId => acceptedRequest.value?['_id']?.toString() ?? '';

  String get acceptedDistance => acceptedRequest.value?['distance']?.toString() ?? 'Calculating...';
  String get acceptedEta => acceptedRequest.value?['eta']?.toString() ?? 'Calculating...';

  /// LatLng of seeker I'm going to help (from live update or original location)
  LatLng? get seekerLatLng {
    if (seekerLivePosition.value != null) {
      return LatLng(seekerLivePosition.value!.latitude, seekerLivePosition.value!.longitude);
    }
    final req = acceptedRequest.value;
    if (req == null) return null;
    final coords = req['location']?['coordinates'] as List<dynamic>?;
    if (coords != null && coords.length == 2) {
      return LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
    }
    return null;
  }

  /// My current position
  Position? get myPosition => _getLocationController()?.currentPosition.value;

  // ─────────────────────────────────────────────────────────────────────────
  // VIBRATION / SOUND
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> emergencyVibration() async {
    _isVibrating = true;
    final notifCtrl = Get.find<NotificationsController>();
    final soundEnabled = notifCtrl.isSoundEnabled.value;
    final notifsEnabled = notifCtrl.isNotificationsEnabled.value;

    if (soundEnabled && notifsEnabled) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.play(AssetSource('mp3/preview.mp3'));
    }

    if (Platform.isAndroid) {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator && notifsEnabled) {
        await Vibration.vibrate(
          pattern: [0, 200, 100, 200, 100, 200, 100, 200],
          intensities: [255, 255, 255, 255],
          repeat: 0,
        );
      }
    } else if (Platform.isIOS) {
      while (_isVibrating) {
        if (!notifsEnabled) break;
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

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE LOAD
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadUserData() async {
    try {
      final box = await Hive.openBox('userProfileBox');
      final name = box.get('name')?.toString() ?? '';
      profileImage.value = box.get('profileImage')?.toString() ?? '';
      if (name.isNotEmpty) {
        final parts = name.trim().split(' ');
        firstName.value = parts.first;
        lastName.value = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    } catch (e) {
      Logger.log('❌ [UNIFIED] loadUserData: $e', type: 'error');
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final resp = await ApiService().get(endpoint: '/api/users/me');
      if (resp != null) {
        final user = (resp!['data'] ?? resp) as Map<String, dynamic>;
        final img = user['profileImage']?.toString() ?? '';
        if (img.isNotEmpty) profileImage.value = img;
      }
    } catch (e) {
      Logger.log('[UNIFIED] fetchUserProfile: $e', type: 'error');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP LIFECYCLE HELPERS (call from UI's WidgetsBindingObserver)
  // ─────────────────────────────────────────────────────────────────────────
  DateTime? _lastResumeTime;
  static const _minResumeInterval = Duration(seconds: 3);

  void onAppResumed() {
    // Debounce rapid resume calls
    final now = DateTime.now();
    if (_lastResumeTime != null && now.difference(_lastResumeTime!) < _minResumeInterval) {
      Logger.log('⏱️ [UNIFIED] Too soon since last resume, skipping', type: 'info');
      return;
    }
    _lastResumeTime = now;

    Logger.log('☀️ [UNIFIED] App resumed', type: 'info');

    // Check socket health and reconnect if needed
    if (_socketService == null || !_socketService!.isConnected.value) {
      Logger.log('🔌 [UNIFIED] Socket disconnected — reconnecting', type: 'warning');
      // Try reconnect first
      _socketService?.reconnect();
      // If reconnect fails, reinitialize
      Future.delayed(const Duration(seconds: 3), () {
        if (_socketService == null || !_socketService!.isConnected.value) {
          Logger.log('🔌 [UNIFIED] Reconnect failed — reinitializing socket', type: 'warning');
          initSocket().then((_) {
            _rejoinRoomAfterReconnect();
          });
        } else {
          _rejoinRoomAfterReconnect();
        }
      });
    } else {
      Logger.log('🔌 [UNIFIED] Socket already connected', type: 'info');
      _rejoinRoomAfterReconnect();
    }

    // Resume location sharing if needed
    _resumeLocationSharingForAppResume();
  }

  void onAppPaused() {
    Logger.log('🌙 [UNIFIED] App paused — keeping socket alive', type: 'info');

    // Start background service ONLY if actively sharing location
    if (seekerHelpRequestId.value.isNotEmpty || acceptedRequest.value != null) {
      Logger.log('📍 [UNIFIED] Starting background service', type: 'info');
      BackgroundService.start();
    }
  }

  void _resumeLocationSharingForAppResume() {
    try {
      final locCtrl = _getLocationController();
      if (locCtrl != null && !locCtrl.liveLocation.value) {
        Logger.log('📍 [UNIFIED] Resuming location sharing', type: 'info');
        locCtrl.resetFirstLocationFlag();
        locCtrl.startLiveLocation();
      }
    } catch (e) {
      Logger.log('❌ [UNIFIED] Error resuming location: $e', type: 'error');
    }
  }



  // ─────────────────────────────────────────────────────────────────────────
  // HEALTH MONITORING
  // ─────────────────────────────────────────────────────────────────────────
  void _startHealthMonitoring() {
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_socketService == null || !_socketService!.isConnected.value) {
        Logger.log('🏥 [HEALTH] Socket disconnected — triggering reconnect', type: 'warning');
        // Use reconnect instead of full init
        _socketService?.reconnect();
      } else {
        Logger.log('🏥 [HEALTH] Socket connection healthy', type: 'info');
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE UTILS
  // ─────────────────────────────────────────────────────────────────────────

  SeakerLocationsController? _getLocationController() {
    try {
      return Get.find<SeakerLocationsController>();
    } catch (_) {
      return null;
    }
  }

  Position _makePosition(double lat, double lng) => Position(
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

  Map<String, double>? _parseLocationData(dynamic data) {
    try {
      Map<String, dynamic> d;
      if (data is String) {
        d = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map) {
        d = Map<String, dynamic>.from(data);
      } else {
        return null;
      }

      final lat = _safeDouble(d['latitude'] ?? d['lat'] ?? d['Latitude'] ?? d['Lat']);
      final lng = _safeDouble(d['longitude'] ?? d['lng'] ?? d['Longitude'] ?? d['Lng']);

      if (lat == null || lng == null) return null;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

      return {'lat': lat, 'lng': lng};
    } catch (_) {
      return null;
    }
  }

  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return double.tryParse(v.toString());
  }

  String _extractId(dynamic data) {
    try {
      if (data is Map) {
        return data['_id']?.toString() ?? data['helpRequestId']?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    Logger.log("🗑️ [UNIFIED] Cleaning up UnifiedHelpController", type: "info");

    // Remove all socket listeners
    _removeAllListeners();

    // Stop vibration and sound
    stopVibration();

    // Cancel all timers
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();

    // Clear socket reference
    _socketService = null;

    // Clear Rx variables to free memory
    screenMode.value = HelpScreenMode.idle;
    helperStatus.value = false;
    seekerHelpRequestId.value = '';
    nearbyStats.value = NearbyStats(km1: 0, km2: 0, km3: 0);
    incomingHelperPosition.value = null;
    incomingHelperName.value = '';
    incomingHelperImage.value = '';
    seekerToHelperDistance.value = 'Calculating...';
    seekerToHelperEta.value = 'Calculating...';
    pendingRequests.clear();
    acceptedRequest.value = null;
    seekerLivePosition.value = null;
    profileImage.value = '';
    firstName.value = '';
    lastName.value = '';

    Logger.log("✅ [UNIFIED] Cleanup completed", type: "success");
    super.onClose();
  }
  }