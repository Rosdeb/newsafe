import 'dart:async';

import 'package:get/get.dart';
import 'package:saferader/controller/SocketService/socket_service.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SocketManager - Centralized Socket Management
//
// Prevents race conditions from multiple controllers initializing socket
// independently. Provides queue-based initialization and token-aware reconnection.
// ─────────────────────────────────────────────────────────────────────────────
class SocketManager extends GetxService {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;
  SocketManager._internal();

  SocketService? _socketService;
  Completer<void>? _initCompleter;
  bool _isInitializing = false;
  
  // Track last token used to detect when token changes
  String? _lastTokenUsed;

  /// Get socket instance - safe to call from anywhere
  /// Automatically handles initialization and reconnection
  Future<SocketService> getSocket({String role = 'both'}) async {
    // Quick check: if socket exists and connected, return immediately
    if (_socketService != null && _socketService!.isConnected.value) {
      Logger.log('[SOCKET_MANAGER] Reusing connected socket', type: 'info');
      return _socketService!;
    }

    // If already initializing, wait for completion
    if (_isInitializing) {
      Logger.log('[SOCKET_MANAGER] Initialization in progress, waiting...', type: 'info');
      await _initCompleter?.future;
      return _socketService!;
    }

    // Start new initialization
    return _initializeSocket(role: role);
  }

  /// Initialize socket with fresh token
  Future<SocketService> _initializeSocket({String role = 'both'}) async {
    _isInitializing = true;
    _initCompleter = Completer();

    try {
      // Always fetch fresh token before initialization
      final token = await TokenService().getToken();
      if (token == null) {
        throw Exception('No token available for socket initialization');
      }

      Logger.log('[SOCKET_MANAGER] Initializing socket with fresh token', type: 'info');

      // Clean up existing socket if present
      if (_socketService != null) {
        Logger.log('[SOCKET_MANAGER] Disposing old socket instance', type: 'info');
        _socketService!.disconnectAndDispose();
        _socketService = null;
      }

      // Create and initialize new socket
      _socketService = SocketService();
      await _socketService!.init(token, role: role, retryCount: 3);
      _lastTokenUsed = token;

      Logger.log('[SOCKET_MANAGER] Socket initialized successfully', type: 'success');
      return _socketService!;
    } catch (e, stackTrace) {
      Logger.log('[SOCKET_MANAGER] Initialization failed: $e\n$stackTrace', type: 'error');
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _isInitializing = false;
      if (_initCompleter!.isCompleted) {
        _initCompleter = null;
      }
    }
  }

  /// Force reconnect with fresh token
  /// Call this after token refresh or when authentication errors occur
  Future<void> reconnectWithFreshToken() async {
    Logger.log('[SOCKET_MANAGER] Force reconnecting with fresh token...', type: 'info');

    final token = await TokenService().getToken();
    if (token == null) {
      Logger.log('[SOCKET_MANAGER] No token available for reconnection', type: 'error');
      throw Exception('No token available for socket reconnection');
    }

    // Dispose current socket
    if (_socketService != null) {
      _socketService!.disconnectAndDispose();
      _socketService = null;
    }

    // Reinitialize with fresh token
    await _initializeSocket(role: _socketService?.userRole.value ?? 'both');
    Logger.log('[SOCKET_MANAGER] Reconnection complete', type: 'success');
  }

  /// Check if token has changed and reconnect if needed
  Future<void> checkTokenAndReconnect() async {
    final currentToken = await TokenService().getToken();
    
    if (currentToken == null) {
      Logger.log('[SOCKET_MANAGER] No token available', type: 'warning');
      return;
    }

    if (currentToken != _lastTokenUsed) {
      Logger.log('[SOCKET_MANAGER] Token changed, reconnecting...', type: 'info');
      await reconnectWithFreshToken();
    } else {
      Logger.log('[SOCKET_MANAGER] Token unchanged, no reconnection needed', type: 'info');
    }
  }

  /// Get current socket service (may be null or disconnected)
  SocketService? get socketService => _socketService;

  /// Check if socket is connected and ready
  bool get isConnected => _socketService?.isConnected.value ?? false;

  /// Clean up resources
  @override
  void onClose() {
    disconnectAndDispose();
    super.onClose();
  }

  /// Disconnect and dispose socket
  void disconnectAndDispose() {
    Logger.log('[SOCKET_MANAGER] Disconnecting and disposing...', type: 'info');
    _socketService?.disconnectAndDispose();
    _socketService = null;
    _lastTokenUsed = null;
    _initCompleter = null;
    _isInitializing = false;
  }
}
