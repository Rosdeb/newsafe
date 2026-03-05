import 'dart:async';

import 'package:get/get.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/auth_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
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
  final RxBool _isSocketReady = false.obs;
  Completer<void>? _readyCompleter;
  final RxString userRole = ''.obs;
  String? currentRoom;

  Completer<void>? _connectionCompleter;
  bool _isInitializing = false;
  int _pingTimeoutCount = 0;

  Future<void> waitForReady({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isSocketReady.value) return;

    try {
      await _readyCompleter?.future.timeout(timeout);
    } catch (e) {
      Logger.log('[SOCKET] Ready timeout: $e', type: 'warning');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  Future<SocketService> init(
      String token, {
        String role = 'both',
        int retryCount = 3,
      }) async {
    userRole.value = role;

    _isSocketReady.value = false;
    _readyCompleter = Completer<void>();

    if (_isInitializing) {
      await _connectionCompleter?.future;
      return this;
    }

    if (_isSocketReady.value && _socket?.connected == true) {
      Logger.log('✅ [SOCKET] Already ready, reusing', type: 'info');
      return this;
    }

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

      // Fetch fresh token before each connection attempt
      String? freshToken = await TokenService().getToken();
      if (freshToken == null) {
        freshToken = token; // Fallback to provided token
        Logger.log('[SOCKET] No fresh token available, using provided token', type: 'warning');
      } else {
        Logger.log('[SOCKET] Using fresh token for connection attempt $attempt', type: 'info');
      }

      _socket = IO.io(
        AppConstants.BASE_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': freshToken})
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(3000)
            .setReconnectionDelayMax(10000)
            .setTimeout(30000)
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
        Logger.log('[SOCKET] Connected on attempt $attempt', type: 'success');
        break;
      } catch (e) {
        Logger.log('[SOCKET] Attempt $attempt failed: $e', type: 'error');
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


  Future<SocketService?> getActiveSocketWithWait({Duration maxWait = const Duration(seconds: 5)}) async {
    // Quick check first
    if (_socket != null && _socket!.connected && _isSocketReady.value) {
      return this;
    }

    // Wait for ready with timeout
    final start = DateTime.now();
    while (DateTime.now().difference(start) < maxWait) {
      if (_socket != null && _socket!.connected && _isSocketReady.value) {
        return this;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    Logger.log('⚠️ [SOCKET] Not ready after ${maxWait.inSeconds}s', type: 'warning');
    return null;
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
        Logger.log('[SOCKET] Rejoining room: $currentRoom', type: 'info');
        await joinRoom(currentRoom!);
      }

      _isSocketReady.value = true;
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.complete();
      }
      Logger.log('[SOCKET] Socket marked as ready', type: 'success');

    });

    socket.onDisconnect((reason) {
      isConnected.value = false;
      _readyCompleter = Completer<void>();

      final r = reason.toString();
      if (r.contains('ping timeout') || r.contains('pingTimeout')) {
        _pingTimeoutCount++;
        Logger.log('[SOCKET] Ping timeout #$_pingTimeoutCount — reason: $r', type: 'warning');
        if (_pingTimeoutCount >= 5) {              // Increased from 3 to 5 for mobile
          Logger.log('[SOCKET] Too many timeouts — forcing reconnect', type: 'warning');
          Future.delayed(const Duration(seconds: 5), () {  // Increased from 2s to 5s
            if (!isConnected.value && _socket != null) {
              reconnect();
            }
          });
        }

      } else if (r.contains('transport close')) {
        // Transport close - try to reconnect immediately
        Logger.log('[SOCKET] Transport closed — attempting immediate reconnect', type: 'warning');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isConnected.value) {
            reconnect();
          }
        });
      } else {
        _pingTimeoutCount = 0;
        Logger.log('[SOCKET] Disconnected — reason: $r', type: 'warning');
        // For other disconnect reasons, try reconnect after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (!isConnected.value && _socket != null) {
            reconnect();
          }
        });
      }
    });

    socket.onConnectError((data) async {
      Logger.log('[SOCKET] Connect error: $data', type: 'error');

      // Check if it's an authentication error
      if (_isAuthError(data)) {
        Logger.log('[SOCKET] Authentication error detected, attempting token refresh...', type: 'warning');

        // Attempt token refresh
        try {
          final refreshed = await AuthService.refreshToken();
          if (refreshed) {
            Logger.log('[SOCKET] Token refreshed successfully, will retry connection', type: 'success');

            // Update auth token for next connection attempt
            await updateAuthToken();

            // Retry connection after short delay
            Future.delayed(const Duration(seconds: 2), () {
              if (!isConnected.value && _socket != null) {
                Logger.log('[SOCKET] Retrying connection with fresh token', type: 'info');
                reconnect();
              }
            });
          } else {
            Logger.log('[SOCKET] Token refresh failed - user may need to re-login', type: 'error');
          }
        } catch (e) {
          Logger.log('[SOCKET] Error during token refresh: $e', type: 'error');
        }
      }

      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError('Connect error: $data');
      }
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.completeError('Connect error: $data');
      }
    });

    socket.onError((data) {
      Logger.log('[SOCKET] Error: $data', type: 'error');
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

      if (!isConnected.value) {
        int waited = 0;
        while (!isConnected.value && waited < 3000) {
          await Future.delayed(const Duration(milliseconds: 200));
          waited += 200;
        }
        if (!isConnected.value) {
          throw Exception('Socket not connected after waiting');
        }
      }

      socket.emit('joinRoom', roomId);
      currentRoom = roomId;
      await Future.delayed(const Duration(milliseconds: 300));
      Logger.log('🚪 [SOCKET] Joined room: $roomId', type: 'info');
    } catch (e) {
      Logger.log('[SOCKET] joinRoom error: $e', type: 'error');
    }
  }


  void leaveRoom(String roomId) {
    try {
      socket.emit('leaveRoom', roomId);
      if (currentRoom == roomId) currentRoom = null;
      Logger.log('[SOCKET] Left room: $roomId', type: 'info');
    } catch (e) {
      Logger.log('[SOCKET] leaveRoom error: $e', type: 'error');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMIT HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void sendLocationUpdate(double latitude, double longitude) {
    if (!isConnected.value) {
      Logger.log('[SOCKET] Not connected — location update skipped', type: 'warning');
      return;
    }
    socket.emit('sendLocationUpdate', {'latitude': latitude, 'longitude': longitude});
    Logger.log('[SOCKET] Location sent: ($latitude, $longitude)', type: 'success');
  }

  void declineHelpRequest(String helpRequestId) {
    if (!isConnected.value) return;
    socket.emit('declineHelpRequest', helpRequestId);
    Logger.log('[SOCKET] Declined: $helpRequestId', type: 'info');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RECONNECT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> reconnect() async {
    if (_socket == null) {
      Logger.log('[SOCKET] Cannot reconnect - socket is null', type: 'warning');
      return;
    }

    if (_socket!.connected) {
      Logger.log('[SOCKET] Already connected - skipping reconnect', type: 'info');
      return;
    }

    _isSocketReady.value = false;
    _readyCompleter = Completer<void>();
    _pingTimeoutCount = 0;

    try {
      // Dispose old socket cleanly
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }

      // Get fresh token
      String? freshToken = await TokenService().getToken();
      if (freshToken == null) {
        Logger.log('[SOCKET] No token available for reconnection', type: 'error');
        return;
      }

      // Create new socket connection
      _socket = IO.io(
        AppConstants.BASE_URL,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': freshToken})
            .enableReconnection()
            .setReconnectionAttempts(3)
            .setReconnectionDelay(2000)
            .setTimeout(15000)
            .disableAutoConnect()
            .build(),
      );

      _registerBaseListeners();

      Logger.log('[SOCKET] Reconnecting with fresh token...', type: 'info');
      _socket!.connect();

      // Wait for connection
      await Future.delayed(const Duration(seconds: 3));

      if (_socket!.connected) {
        Logger.log('[SOCKET] Reconnection successful', type: 'success');
      } else {
        Logger.log('[SOCKET] Reconnection pending...', type: 'warning');
      }
    } catch (e) {
      Logger.log('[SOCKET] Reconnection failed: $e', type: 'error');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOKEN REFRESH AWARENESS
  // ─────────────────────────────────────────────────────────────────────────

  /// Update auth token before reconnect (call after token refresh)
  Future<void> updateAuthToken() async {
    final newToken = await TokenService().getToken();
    if (newToken != null && _socket != null) {
      // Update auth options for next connection
      _socket!.auth = {'token': newToken};
      Logger.log('[SOCKET] Auth token updated for reconnection', type: 'info');
    }
  }

  /// Check if error is authentication-related
  bool _isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('authentication') ||
           errorStr.contains('unauthorized') ||
           errorStr.contains('401') ||
           errorStr.contains('invalid token') ||
           errorStr.contains('token expired');
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
      _isSocketReady.value = false;
      _readyCompleter = null;
      Logger.log('[SOCKET] Disposed', type: 'info');
    } catch (e) {
      Logger.log('[SOCKET] Dispose error: $e', type: 'error');
    }
  }

  @override
  void onClose() {
    disconnectAndDispose();
    super.onClose();
  }
}