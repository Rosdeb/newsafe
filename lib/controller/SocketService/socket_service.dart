import 'dart:async';

import 'package:get/get.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ─────────────────────────────────────────────────────────────────────────────
// SocketService
//
// Owns the single WebSocket connection.
// Controllers register their own listeners on top of this via socket.on().
// This class only manages connect/disconnect/room logic.
// ─────────────────────────────────────────────────────────────────────────────
class SocketService extends GetxService {
  IO.Socket? _socket;

  IO.Socket get socket {
    if (_socket == null) throw Exception('SocketService: call init() first');
    return _socket!;
  }

  final RxBool isConnected = false.obs;
  final RxString userRole = ''.obs;
  String? currentRoom;

  Completer<void>? _connectionCompleter;
  bool _isInitializing = false;
  int _pingTimeoutCount = 0;

  // ─────────────────────────────────────────────────────────────────────────
  Future<SocketService> init(
      String token, {
        String role = 'both',
        int retryCount = 3,
      }) async {
    userRole.value = role;

    if (_isInitializing) {
      await _connectionCompleter?.future;
      return this;
    }

    // Already connected — just reuse
    if (_socket != null && _socket!.connected) {
      Logger.log('✅ [SOCKET] Already connected, reusing', type: 'info');
      return this;
    }

    int attempt = 0;
    while (attempt < retryCount) {
      _isInitializing = true;
      attempt++;

      // Dispose old socket cleanly
      try {
        if (_socket != null) {
          _socket!.dispose();
          _socket = null;
        }
      } catch (e) {
        Logger.log('⚠️ [SOCKET] Dispose error: $e', type: 'warning');
      }

      _connectionCompleter = Completer<void>();

      _socket = IO.io(
        AppConstants.BASE_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .disableAutoConnect()
            .build(),
      );

      _registerBaseListeners();
      socket.connect();

      try {
        await _connectionCompleter!.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('Socket connection timeout'),
        );
        Logger.log('✅ [SOCKET] Connected on attempt $attempt', type: 'success');
        break;
      } catch (e) {
        Logger.log('❌ [SOCKET] Attempt $attempt failed: $e', type: 'error');
        if (attempt < retryCount) {
          await Future.delayed(const Duration(seconds: 3));
        } else {
          _isInitializing = false;
          rethrow;
        }
      }
    }

    _isInitializing = false;
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BASE LISTENERS (connect / disconnect only)
  // ─────────────────────────────────────────────────────────────────────────
  void _registerBaseListeners() {
    socket.offAny();

    socket.onConnect((_) async {
      isConnected.value = true;
      _pingTimeoutCount = 0;
      Logger.log('🔌 [SOCKET] Connected — ID: ${socket.id}', type: 'success');

      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }

      // Auto-rejoin last room
      if (currentRoom != null) {
        Logger.log('🚪 [SOCKET] Rejoining room: $currentRoom', type: 'info');
        await joinRoom(currentRoom!);
      }
    });

    socket.onDisconnect((reason) {
      isConnected.value = false;
      final r = reason.toString();
      if (r.contains('ping timeout') || r.contains('pingTimeout')) {
        _pingTimeoutCount++;
        Logger.log('⚠️ [SOCKET] Ping timeout #$_pingTimeoutCount — reason: $r', type: 'warning');
      } else {
        Logger.log('⚡ [SOCKET] Disconnected — reason: $r', type: 'warning');
      }
    });

    socket.onConnectError((data) {
      Logger.log('❌ [SOCKET] Connect error: $data', type: 'error');
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError('Connect error: $data');
      }
    });

    socket.onError((data) {
      Logger.log('❌ [SOCKET] Error: $data', type: 'error');
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROLE
  // ─────────────────────────────────────────────────────────────────────────

  /// Call this to update role metadata (does NOT rewire listeners — controllers do that)
  void updateRole(String newRole) {
    userRole.value = newRole;
    Logger.log('👤 [SOCKET] Role updated: $newRole', type: 'info');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROOM MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> joinRoom(String roomId) async {
    try {
      if (currentRoom != null && currentRoom != roomId) {
        leaveRoom(currentRoom!);
      }
      if (!isConnected.value) throw Exception('Socket not connected');

      socket.emit('joinRoom', roomId);
      currentRoom = roomId;
      await Future.delayed(const Duration(milliseconds: 300));
      Logger.log('🚪 [SOCKET] Joined room: $roomId', type: 'info');
    } catch (e) {
      Logger.log('❌ [SOCKET] joinRoom error: $e', type: 'error');
    }
  }

  void leaveRoom(String roomId) {
    try {
      socket.emit('leaveRoom', roomId);
      if (currentRoom == roomId) currentRoom = null;
      Logger.log('🚪 [SOCKET] Left room: $roomId', type: 'info');
    } catch (e) {
      Logger.log('❌ [SOCKET] leaveRoom error: $e', type: 'error');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMIT HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void sendLocationUpdate(double latitude, double longitude) {
    if (!isConnected.value) {
      Logger.log('⚠️ [SOCKET] Not connected — location update skipped', type: 'warning');
      return;
    }
    socket.emit('sendLocationUpdate', {'latitude': latitude, 'longitude': longitude});
    Logger.log('📍 [SOCKET] Location sent: ($latitude, $longitude)', type: 'success');
  }

  void declineHelpRequest(String helpRequestId) {
    if (!isConnected.value) return;
    socket.emit('declineHelpRequest', helpRequestId);
    Logger.log('🚫 [SOCKET] Declined: $helpRequestId', type: 'info');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RECONNECT
  // ─────────────────────────────────────────────────────────────────────────
  void reconnect() {
    if (_socket == null || _socket!.connected) return;
    Logger.log('🔄 [SOCKET] Reconnecting...', type: 'info');
    socket.connect();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────────────────
  void disconnectAndDispose() {
    try {
      if (currentRoom != null) leaveRoom(currentRoom!);
      socket.offAny();
      if (socket.connected) socket.disconnect();
      socket.dispose();
      isConnected.value = false;
      Logger.log('🔌 [SOCKET] Disposed', type: 'info');
    } catch (e) {
      Logger.log('❌ [SOCKET] Dispose error: $e', type: 'error');
    }
  }

  @override
  void onClose() {
    disconnectAndDispose();
    super.onClose();
  }
}