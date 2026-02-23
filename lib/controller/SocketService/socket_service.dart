import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'dart:async';

class SocketService extends GetxService {
  IO.Socket? _socket;

  // Getter with null check
  IO.Socket get socket {
    if (_socket == null) {
      throw Exception('Socket not initialized. Call init() first.');
    }
    return _socket!;
  }

  final RxBool isConnected = false.obs;
  final RxString userRole = ''.obs;
  String? currentRoom;
  Completer<void>? _connectionCompleter;
  bool _isInitializing = false;
  Timer? _connectionHealthTimer;
  DateTime? _lastPingTime;
  int _pingTimeoutDisconnects = 0;
  String _originalRole = 'seeker';

  Future<SocketService> init(String token, {String role = 'seeker', int retryCount = 3}) async {
    _originalRole = role;

    if (_isInitializing) {
      Logger.log("⏳ Socket initialization already in progress", type: "info");
      await _connectionCompleter?.future;
      return this;
    }

    int attempt = 0;

    while (attempt < retryCount) {
      _isInitializing = true;
      attempt++;

      try {
        // Dispose old socket
        if (_socket != null && _socket!.connected) {
          _socket!.disconnect();
          _socket!.dispose();
          _socket = null;
        }
      } catch (e) {
        Logger.log("Error disposing old socket: $e", type: "error");
      }

      userRole.value = role;
      _connectionCompleter = Completer<void>();

      _socket = IO.io(
        AppConstants.BASE_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000) // Max delay between reconnection attempts
            .setTimeout(20000)
            .disableAutoConnect()
            .build(),);

      _setupBaseListeners();
      socket.connect();

      try {
        await _connectionCompleter!.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('Socket connection timeout');
          },
        );

        Logger.log("✅ Socket connected successfully on attempt $attempt", type: "success");
        break; // Exit loop if successful
      } catch (e) {
        Logger.log("❌ Socket connection failed on attempt $attempt: $e", type: "error");

        // Wait before retrying
        if (attempt < retryCount) {
          Logger.log("🔄 Retrying in 3 seconds...", type: "info");
          await Future.delayed(const Duration(seconds: 3));
        } else {
          Logger.log("❌ All retry attempts failed", type: "error");
          _isInitializing = false;
          rethrow;
        }
      }
    }

    _isInitializing = false;
    return this;
  }

  void _setupBaseListeners() {
    // Remove all existing listeners first
    final events = [
      'connect',
      'disconnect',
      'connect_error',
      'error',
      'giver_newHelpRequest',      // For givers
      'newHelpRequest',            // For seekers
      'helpRequestAccepted',
      'giver_helpRequestDeclined',
      'declineHelpRequest',
      'receiveLocationUpdate',
      'giver_receiveLocationUpdate',
      'helpRequestCancelled',
      'giver_helpRequestCancelled',
      'helpRequestCompleted',
      'giver_helpRequestCompleted',
      'message',
    ];

    for (var event in events) {
      socket.off(event);
    }
    socket.offAny();

    // Connection events
    socket.onConnect((_) async {
      isConnected.value = true;
      Logger.log("🔌 Socket Connected - ID: ${socket.id}", type: "success");
      
      // Reset ping timeout counter on successful connection
      _pingTimeoutDisconnects = 0;

      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }

      // 🔥 CRITICAL: Rejoin room after reconnection
      if (currentRoom != null) {
        Logger.log("🔄 Reconnected - Rejoining room: $currentRoom", type: "info");
        await joinRoom(currentRoom!);

        // 🔥 Give a moment for room join, then notify that location sharing should resume
        await Future.delayed(const Duration(milliseconds: 500));
        Logger.log("✅ Room rejoined - Location sharing can resume", type: "success");
      }
      
      // Start connection health monitoring
      _startConnectionHealthMonitoring();
    });

    socket.onDisconnect((reason) {
      isConnected.value = false;
      
      // 🔥 DIAGNOSTIC: Track ping timeout disconnects
      if (reason.toString().contains('ping timeout') || reason.toString().contains('pingTimeout')) {
        _pingTimeoutDisconnects++;
        Logger.log("❌ Socket Disconnected - Reason: $reason (Ping Timeout #$_pingTimeoutDisconnects)", type: "error");
        Logger.log("⚠️ This usually indicates the server's pingTimeout is too short or network latency is high", type: "warning");
        
        // If we're getting frequent ping timeouts, log a warning
        if (_pingTimeoutDisconnects >= 3) {
          Logger.log("🚨 Multiple ping timeouts detected! Backend pingTimeout may need adjustment.", type: "error");
        }
      } else {
        Logger.log("❌ Socket Disconnected - Reason: $reason", type: "warning");
      }

      // Stop health monitoring
      _connectionHealthTimer?.cancel();
      _connectionHealthTimer = null;
      _lastPingTime = null;

      // 🔥 IMPORTANT: On disconnect, the socket is automatically removed from all rooms
      // We need to rejoin the room when we reconnect
      if (currentRoom != null) {
        Logger.log("⚠️ Was in room: $currentRoom - will rejoin on reconnect", type: "warning");
      }
    });

    socket.onConnectError((data) {
      Logger.log("❌ Socket Connect Error: $data", type: "error");
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError('Connection failed: $data');
      }
    });

    socket.onError((data) {
      Logger.log("❌ Socket Error: $data", type: "error");
    });

    // Role-based event listeners setup
    _setupRoleBasedListeners();
  }

  void _setupRoleBasedListeners() {
    // Common events for both roles
    socket.on('helpRequestAccepted', (data) {
      Logger.log("❤️ HELP REQUEST ACCEPTED: $data", type: "success");
    });

    socket.on('message', (data) {
      Logger.log("📢 System Message: $data", type: "info");
    });

    socket.on('error', (data) {
      Logger.log(" Error: $data", type: "error");
      Get.snackbar("Error", data.toString());
    });

    if (userRole.value == 'giver' || userRole.value == 'both') {
      _setupGiverListeners();
    }

    if (userRole.value == 'seeker' || userRole.value == 'both') {
      _setupSeekerListeners();
    }
  }

  void _setupGiverListeners() {
    socket.on('giver_newHelpRequest', (data) {
      Logger.log("🆘 NEW HELP REQUEST for Giver: $data", type: "info");
    });

    socket.on('giver_helpRequestDeclined', (data) {
      Logger.log(" Help request declined confirmation: $data", type: "info");
    });

    socket.on('giver_receiveLocationUpdate', (data) {
      Logger.log("📍 Seeker Location Update for Giver: $data", type: "info");
    });

    socket.on('giver_helpRequestCancelled', (data) {
      Logger.log("⛔ Help request cancelled (giver): $data", type: "warning");
    });

    socket.on('giver_helpRequestCompleted', (data) {
      Logger.log("✅ Help request completed (giver): $data", type: "success");
    });
  }

  void _setupSeekerListeners() {
    socket.on('newHelpRequest', (data) {
      Logger.log("🆘 New help request (seeker): $data", type: "info");
      // For users with role 'both' when they're in seeker mode
    });

    socket.on('receiveLocationUpdate', (data) {
      Logger.log("📍 Giver Location Update for Seeker: $data", type: "info");
    });

    socket.on('helpRequestCancelled', (data) {
      Logger.log("⛔ Help request cancelled (seeker): $data", type: "warning");
    });

    socket.on('helpRequestCompleted', (data) {
      Logger.log("✅ Help request completed (seeker): $data", type: "success");
    });
  }

  // Giver-specific methods
  void acceptHelpRequest(String helpRequestId) {
    if (!isConnected.value) {
      Logger.log("⚠️ Socket not connected, cannot accept request", type: "warning");
      return;
    }

    socket.emit('acceptHelpRequest', helpRequestId);
    Logger.log("✅ Accepted help request: $helpRequestId", type: "success");
  }

  void declineHelpRequest(String helpRequestId) {
    if (!isConnected.value) {
      Logger.log("⚠️ Socket not connected, cannot decline request", type: "warning");
      return;
    }

    socket.emit('declineHelpRequest', helpRequestId);
    Logger.log("❌ Declined help request: $helpRequestId", type: "info");
  }

  // Common methods
  void sendLocationUpdate(double latitude, double longitude, {String? helpRequestId}) {
    try {
      if (!isConnected.value) {
        Logger.log("⚠️ Socket not connected, cannot send location", type: "warning");
        return;
      }

      // CRITICAL: According to backend spec, payload should ONLY contain latitude & longitude
      // Server identifies the help request from the room the socket is in
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
      };

      socket.emit('sendLocationUpdate', locationData);
      Logger.log("📍 Sent location update: ($latitude, $longitude) to room: ${currentRoom ?? 'unknown'}", type: "success");

    } on Exception catch (e) {
      Logger.log("Error sending location update: $e", type: "error");
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      if (currentRoom != null && currentRoom != roomId) {
        leaveRoom(currentRoom!);
      }

      if (!isConnected.value) {
        Logger.log("️Cannot join room - socket not connected", type: "warning");
        throw Exception('Socket not connected');
      }
      Logger.log("Attempting to join room: $roomId", type: "info");

      socket.emit('joinRoom', roomId);
      currentRoom = roomId;

      // Wait a short moment for the emit to complete (but not for ack)
      await Future.delayed(const Duration(milliseconds: 300));

      Logger.log("📤 Room join request sent: $roomId", type: "info");

    } catch (e) {
      Logger.log(" Error joining room: $e", type: "error");
      // Don't rethrow - just log and continue
    }
  }

  void leaveRoom(String roomId) {
    socket.emit("leaveRoom", roomId);
    if (currentRoom == roomId) {
      currentRoom = null;
    }
    Logger.log("📤 Left room: $roomId", type: "info");
  }

  void updateRole(String newRole) {
    userRole.value = newRole;
    socket.off('giver_newHelpRequest');
    socket.off('receiveLocationUpdate');
    socket.off('giver_receiveLocationUpdate');
    socket.off('helpRequestCancelled');
    socket.off('giver_helpRequestCancelled');
    socket.off('helpRequestCompleted');
    socket.off('giver_helpRequestCompleted');
    _setupRoleBasedListeners();
    Logger.log("User role updated to: $newRole", type: "info");
  }

  //<-----> Start monitoring connection health to detect potential ping timeout issues
  void _startConnectionHealthMonitoring() {
    _connectionHealthTimer?.cancel();
    _lastPingTime = DateTime.now();
    
    // Monitor connection every 10 seconds
    _connectionHealthTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!isConnected.value || _socket == null || !_socket!.connected) {
        timer.cancel();
        return;
      }
      
      // Log connection health status
      final now = DateTime.now();
      final timeSinceLastCheck = now.difference(_lastPingTime ?? now);
      Logger.log("💓 Connection health check - Connected: ${_socket!.connected}, Time since last check: ${timeSinceLastCheck.inSeconds}s", type: "debug");
      
      _lastPingTime = now;
    });
  }

  void disconnectAndDispose() {
    try {
      // Stop health monitoring
      _connectionHealthTimer?.cancel();
      _connectionHealthTimer = null;
      _lastPingTime = null;
      
      if (currentRoom != null) {
        leaveRoom(currentRoom!);
      }

      // Remove all listeners
      final events = [
        'connect', 'disconnect', 'connect_error', 'error',
        'giver_newHelpRequest', 'newHelpRequest', 'helpRequestAccepted',
        'giver_helpRequestDeclined', 'declineHelpRequest',
        'receiveLocationUpdate', 'giver_receiveLocationUpdate',
        'helpRequestCancelled', 'giver_helpRequestCancelled',
        'helpRequestCompleted', 'giver_helpRequestCompleted', 'message'
      ];

      for (var event in events) {
        socket.off(event);
      }

      socket.offAny();

      if (socket.connected) {
        socket.disconnect();
      }

      socket.dispose();
      isConnected.value = false;
      Logger.log("🔌 Socket properly disposed", type: "info");
    }on Exception catch (e) {
      Logger.log("❌ Error disposing socket: $e", type: "error");
    }
  }

  @override
  void onClose() {
    disconnectAndDispose();
    super.onClose();
  }
}