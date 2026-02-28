import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../controller/SocketService/socket_service.dart';
import '../controller/SeakerLocation/seakerLocationsController.dart';

class AppLifecycleSocketHandler extends WidgetsBindingObserver {
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is back in foreground, reconnect socket and rejoin room
        await _handleAppResume();
        break;
      case AppLifecycleState.paused:
        // App is in background, but don't disconnect socket
        // Just monitor the connection
        _handleAppPause();
        break;
      case AppLifecycleState.inactive:
        // App is inactive, keep socket alive
        break;
      case AppLifecycleState.detached:
        // App is detached, this rarely happens in practice
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        break;
    }
  }

  Future<void> _handleAppResume() async {
    try {
      // SOCKET_STABILITY: One connection per user. Reconnect the single SocketService.
      if (Get.isRegistered<SocketService>()) {
        final socketService = Get.find<SocketService>();
        await _reconnectSocketAndRejoinRoom(socketService);
      }

      // Refresh location controller after map return
      if (Get.isRegistered<SeakerLocationsController>()) {
        final locationController = Get.find<SeakerLocationsController>();
        await locationController.refreshAfterMapReturn();
      }
      
    } catch (e) {
      debugPrint('Error handling app resume: $e');
    }
  }

  void _handleAppPause() {
    // On app pause, we don't disconnect the socket
    // Just log the state for monitoring purposes
    debugPrint('App paused - keeping socket connection alive');
  }

  Future<void> _reconnectSocketAndRejoinRoom(SocketService? socketService) async {
    if (socketService == null) return;

    try {
      // If socket is not connected, reconnect without full init (avoids connect/disconnect churn)
      if (!socketService.isConnected.value) {
        debugPrint('Socket disconnected, attempting to reconnect...');
        socketService.reconnect();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // After reconnection, rejoin the room if there was one
      final currentRoomId = socketService.currentRoom;
      if (currentRoomId != null && currentRoomId.isNotEmpty) {
        debugPrint('Rejoining room: $currentRoomId');
        await socketService.joinRoom(currentRoomId);
        
        // Wait for room to join
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      debugPrint('Error reconnecting socket: $e');
    }
  }
}