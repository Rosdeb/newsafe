import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../utils/app_constant.dart';

/// Background service to maintain location sharing and socket connection when app is in background
/// This allows real-time communication to continue when user switches to Google Maps or other apps
@pragma('vm:entry-point')
class BackgroundLocationSocketService {
  static const String SERVICE_NAME = "LocationSocketSharing";

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'LocationSocketSharingChannel',
        initialNotificationTitle: 'Saferadar Active',
        initialNotificationContent: 'Saferadar is sharing your location and maintaining connections',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // Socket service
  static IO.Socket? _socket;
  static String? _currentRoomId;
  static bool _isSocketConnected = false;
  static Timer? _connectionMonitorTimer;

  // Location service
  static StreamSubscription<Position>? _locationSubscription;
  static Position? _lastPosition;
  static Timer? _locationTimer;
  static bool _isSharingActive = false;
  static Timer? _periodicCheckTimer;

  // Configuration
  static const double LOCATION_UPDATE_DISTANCE = 10.0; // meters
  static const int LOCATION_UPDATE_TIME = 5000; // milliseconds
  static const int CHECK_INTERVAL = 10000; // milliseconds
  static String SOCKET_URL = AppConstants.BASE_URL;

  static ServiceInstance? _currentService;


  static void _updateNotification(String title, String content) {
    if (_currentService != null) {
      if (_currentService is AndroidServiceInstance) {
        (_currentService as AndroidServiceInstance).setForegroundNotificationInfo(
          title: title,
          content: content,
        );
      } else {
        _currentService!.invoke('setNotificationInfo', {
          'title': title,
          'content': content,
        });
      }
    }
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    try {
      _currentService = service;

      // Set as foreground service for Android
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: 'Saferadar Active',
          content: 'Maintaining safety connections',
        );
      }

      // Listen for notification update requests from main app
      service.on('setNotificationInfo').listen((event) {
        if (event != null && event is Map) {
          _updateNotification(
            event['title']?.toString() ?? 'Saferadar',
            event['content']?.toString() ?? 'Active',
          );
        }
      });

      // Listen for stop command
      service.on('stopService').listen((event) async {
        await _cleanupAndStop();
        service.stopSelf();
      });

      // Start location and socket updates
      _startLocationAndSocketUpdates(service);

    } catch (e, stackTrace) {
      print("❌ Background service onStart error: $e");
      print("Stack trace: $stackTrace");
    }
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    try {
      onStart(service);
      return true;
    } catch (ex) {
      print("❌ iOS background service error: $ex");
      return false;
    }
  }

  static void _startLocationAndSocketUpdates(ServiceInstance service) {
    // Check if location sharing should be active
    _checkAndStartServices(service);

    // Set up periodic check with proper cleanup
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(Duration(milliseconds: CHECK_INTERVAL), (timer) {
      _checkAndStartServices(service);
    });
  }

  static Future<void> _checkAndStartServices(ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSharing = prefs.getBool('is_location_sharing_active') ?? false;
      final hasActiveRequest = prefs.getString('current_help_request_id')?.isNotEmpty ?? false;

      if (isSharing && hasActiveRequest) {
        if (!_isSharingActive) {
          _isSharingActive = true;
          await _startLocationTracking(service);
          await _startSocketConnection(service);
        }
      } else {
        if (_isSharingActive) {
          _isSharingActive = false;
          await _stopLocationTracking();
          await _stopSocketConnection();
          _updateNotification('Saferadar Inactive', 'No active help requests');
        }
      }
    } catch (e) {
      print("❌ Error in _checkAndStartServices: $e");
    }
  }

  static Future<void> _startSocketConnection(ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        _updateNotification('Auth Error', 'No authentication token available');
        return;
      }

      // Disconnect existing socket if any
      await _stopSocketConnection();

      // Initialize socket with proper error handling
      _socket = IO.io(
        SOCKET_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(10000)
            .setTimeout(30000)
            .build(),
      );

      // Set up event listeners BEFORE connecting
      _setupSocketEventListeners(service);

      _socket!.connect();

      // Wait a bit to see if connection is successful
      await Future.delayed(Duration(seconds: 3));

    } catch (e) {
      _updateNotification('Connection Error', 'Socket failed: ${e.toString()}');
    }
  }

  static void _setupSocketEventListeners(ServiceInstance service) {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isSocketConnected = true;
      _updateNotification('Saferadar Connected', 'Socket connection established');
      _joinCurrentRoom();
    });

    _socket!.onDisconnect((reason) {
      _isSocketConnected = false;
      _updateNotification('Saferadar Disconnected', 'Attempting to reconnect... ($reason)');
    });

    _socket!.onConnectError((error) {
      _isSocketConnected = false;
      _updateNotification('Connection Error', 'Error: ${error.toString()}');
    });

    _socket!.on('connect_timeout', (data) {
      _isSocketConnected = false;
      _updateNotification('Connection Timeout', 'Connection attempt timed out');
    });

    // Listen for location updates from other users
    _socket!.on('receiveLocationUpdate', (data) {
      _handleIncomingLocationUpdate(data);
    });

    _socket!.on('giver_receiveLocationUpdate', (data) {
      _handleIncomingLocationUpdate(data);
    });

    // Listen for other important events
    _socket!.on('helpRequestCancelled', (data) {
      _handleHelpRequestCancelled(data);
    });

    _socket!.on('helpRequestCompleted', (data) {
      _handleHelpRequestCompleted(data);
    });

    // Monitor connection
    _startConnectionMonitoring(service);
  }

  static void _handleHelpRequestCancelled(dynamic data) {
    _updateNotification('Request Cancelled', 'Help request was cancelled');
    _stopBackgroundLocationSharing();
  }

  static void _handleHelpRequestCompleted(dynamic data) {
    _updateNotification('Request Completed', 'Help request was completed');
    _stopBackgroundLocationSharing();
  }

  static void _startConnectionMonitoring(ServiceInstance service) {
    _connectionMonitorTimer?.cancel();

    _connectionMonitorTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_socket != null) {
        if (!_socket!.connected) {
          _isSocketConnected = false;
          _updateNotification('Reconnecting...', 'Attempting to restore socket connection');
        } else {
          _isSocketConnected = true;
        }
      }
    });
  }

  static Future<void> _stopSocketConnection() async {
    try {
      if (_socket != null) {
        if (_socket!.connected) {
          _socket!.disconnect();
        }
        _socket!.dispose();
      }
      _socket = null;
      _isSocketConnected = false;

      _connectionMonitorTimer?.cancel();
      _connectionMonitorTimer = null;
    } catch (e) {
      print("❌ Error stopping socket: $e");
    }
  }

  static Future<void> _startLocationTracking(ServiceInstance service) async {
    try {
      // Check if location service is enabled
      final hasPermission = await Geolocator.isLocationServiceEnabled();
      if (!hasPermission) {
        _updateNotification('Location Disabled', 'Location services are disabled');
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _updateNotification('Location Disabled', 'Location permission denied');
        return;
      }

      // Cancel any existing subscription
      await _stopLocationTracking();

      // Start listening for location updates
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: LOCATION_UPDATE_DISTANCE.toInt(),
        ),
      ).listen(
            (position) async {
          if (_shouldUpdateLocation(position)) {
            await _sendLocationUpdate(position, service);
            _lastPosition = position;
          }
        },
        onError: (error) {
          print("❌ Location stream error: $error");
          _updateNotification('Location Error', error.toString());
        },
        cancelOnError: false,
      );

      // Also send periodic updates regardless of distance to ensure continuity
      _locationTimer?.cancel();
      _locationTimer = Timer.periodic(Duration(milliseconds: LOCATION_UPDATE_TIME), (timer) async {
        if (_lastPosition != null && _isSocketConnected) {
          await _sendLocationUpdate(_lastPosition!, service);
        }
      });

    } catch (e) {
      print("❌ Error starting location tracking: $e");
      _updateNotification('Tracking Error', e.toString());
    }
  }

  static Future<void> _stopLocationTracking() async {
    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      _locationTimer?.cancel();
      _locationTimer = null;

      _lastPosition = null;
    } catch (e) {
      print("❌ Error stopping location tracking: $e");
    }
  }

  static bool _shouldUpdateLocation(Position newPosition) {
    if (_lastPosition == null) return true;

    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance >= LOCATION_UPDATE_DISTANCE;
  }

  static Future<void> _sendLocationUpdate(Position position, ServiceInstance service) async {
    if (!_isSocketConnected || _socket == null) {
      // Store location for when connection is restored
      try {
        final prefs = await SharedPreferences.getInstance();
        final locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'accuracy': position.accuracy,
        };
        await prefs.setString('pending_location_update', jsonEncode(locationData));
      } catch (e) {
        print("❌ Error storing pending location: $e");
      }
      return;
    }

    try {
      // Send location update to socket
      _socket!.emit('sendLocationUpdate', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      // Update notification
      _updateNotification(
        'Location Shared',
        'Updated: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      );

      // Clear any pending location updates
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_location_update');

    } catch (e) {
      print("❌ Error sending location: $e");
      // Store for later if failed
      try {
        final prefs = await SharedPreferences.getInstance();
        final locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'accuracy': position.accuracy,
        };
        await prefs.setString('pending_location_update', jsonEncode(locationData));
      } catch (storageError) {
        print("❌ Error storing failed location: $storageError");
      }
    }
  }

  // ✅ FIXED: Made async properly
  static Future<void> _handleIncomingLocationUpdate(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('incoming_location_update', jsonEncode(data));
    } catch (e) {
      print("❌ Error handling incoming location: $e");
    }
  }

  static Future<void> _joinCurrentRoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roomId = prefs.getString('current_help_request_id');

      if (roomId != null && roomId.isNotEmpty && _socket != null && _isSocketConnected) {
        _socket!.emit('joinRoom', roomId);
        _currentRoomId = roomId;
      }
    } catch (e) {
      print("❌ Error joining room: $e");
    }
  }

  // ✅ NEW: Complete cleanup method
  static Future<void> _cleanupAndStop() async {
    try {
      _isSharingActive = false;

      // Cancel all timers
      _periodicCheckTimer?.cancel();
      _periodicCheckTimer = null;

      _connectionMonitorTimer?.cancel();
      _connectionMonitorTimer = null;

      _locationTimer?.cancel();
      _locationTimer = null;

      // Stop location tracking
      await _stopLocationTracking();

      // Stop socket connection
      await _stopSocketConnection();

      // Clear state
      _currentRoomId = null;
      _lastPosition = null;
      _currentService = null;

      print("✅ Background service cleaned up successfully");
    } catch (e) {
      print("❌ Error during cleanup: $e");
    }
  }

  // Public API methods

  static Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      print("❌ Error checking service status: $e");
      return false;
    }
  }

  static Future<void> startLocationSharing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_location_sharing_active', true);

      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      }
    } catch (e) {
      print("❌ Error starting location sharing: $e");
    }
  }

  // ✅ FIXED: Proper implementation
  static Future<void> _stopBackgroundLocationSharing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_location_sharing_active', false);

      // Trigger a check to stop services
      if (_currentService != null) {
        await _checkAndStartServices(_currentService!);
      }
    } catch (e) {
      print("❌ Error stopping background location sharing: $e");
    }
  }

  static Future<void> stopLocationSharing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_location_sharing_active', false);

      // Trigger a check to stop services
      if (_currentService != null) {
        await _checkAndStartServices(_currentService!);
      }
    } catch (e) {
      print("❌ Error in stopLocationSharing: $e");
    }
  }

  static Future<void> setLocationSharingActive(bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_location_sharing_active', active);
    } catch (e) {
      print("❌ Error setting location sharing active: $e");
    }
  }

  static Future<void> setActiveHelpRequestId(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (requestId.isNotEmpty) {
        await prefs.setString('current_help_request_id', requestId);

        // Join room in background service if running
        if (_isSharingActive && _currentService != null) {
          await _joinCurrentRoom();
        }
      } else {
        await prefs.remove('current_help_request_id');

        // Leave room if in one
        if (_currentRoomId != null && _socket != null && _isSocketConnected) {
          _socket!.emit('leaveRoom', _currentRoomId);
          _currentRoomId = null;
        }
      }
    } catch (e) {
      print("❌ Error setting help request ID: $e");
    }
  }

  static Future<String> getActiveHelpRequestId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_help_request_id') ?? '';
    } catch (e) {
      print("❌ Error getting help request ID: $e");
      return '';
    }
  }

  static Future<Map<String, dynamic>?> getLastBackgroundLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationStr = prefs.getString('last_background_location');

      if (locationStr != null) {
        return jsonDecode(locationStr);
      }
    } catch (e) {
      print("❌ Error getting last background location: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getPendingLocationUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationStr = prefs.getString('pending_location_update');

      if (locationStr != null) {
        return jsonDecode(locationStr);
      }
    } catch (e) {
      print("❌ Error getting pending location: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getIncomingLocationUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationStr = prefs.getString('incoming_location_update');

      if (locationStr != null) {
        return jsonDecode(locationStr);
      }
    } catch (e) {
      print("❌ Error getting incoming location: $e");
    }
    return null;
  }

  static bool isSocketConnected() {
    return _isSocketConnected;
  }

  // ✅ FIXED: Complete implementation with proper cleanup
  static Future<void> stopService() async {
    try {
      // First cleanup everything
      await _cleanupAndStop();

      // Set sharing to false
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_location_sharing_active', false);

      // Stop the service
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
      }

      print("✅ Background service stopped successfully");
    } catch (e) {
      print("❌ Error stopping service: $e");
    }
  }
}