// lib/controller/SeekerSocket/seeker_socket_service.dart
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:saferader/utils/logger.dart';

class SeekerSocketService extends GetxService {
  late IO.Socket socket;
  final RxBool isConnected = false.obs;
  String? currentHelpRequestId;

  Future<SeekerSocketService> init(String token) async {
    socket = IO.io(
      "ws://tonydoorn.grassroots-bd.com",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    socket.onConnect((_) {
      isConnected.value = true;
      Logger.log("🔌 Seeker Socket Connected - ID: ${socket.id}", type: "success");

      // Rejoin room if we had an active help request
      if (currentHelpRequestId != null) {
        joinHelpRequestRoom(currentHelpRequestId!);
      }
    });

    socket.onDisconnect((_) {
      isConnected.value = false;
      Logger.log("❌ Seeker Socket Disconnected", type: "warning");
    });

    socket.onError((error) {
      Logger.log("❌ Seeker Socket Error: $error", type: "error");
    });

    return this;
  }

  void joinHelpRequestRoom(String helpRequestId) {
    socket.emit("joinRoom", helpRequestId);
    currentHelpRequestId = helpRequestId;
    Logger.log("🚪 Seeker joined help request room: $helpRequestId", type: "info");
  }

  void leaveHelpRequestRoom() {
    if (currentHelpRequestId != null) {
      socket.emit("leaveRoom", currentHelpRequestId!);
      Logger.log("🚪 Seeker left help request room: $currentHelpRequestId", type: "info");
      currentHelpRequestId = null;
    }
  }

  void sendSeekerLocation(double latitude, double longitude) {
    try {
      if (!isConnected.value) {
        Logger.log("⚠️ Seeker socket not connected", type: "warning");
        return;
      }

      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'helpRequestId': currentHelpRequestId,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'seeker_location'
      };

      socket.emit('sendLocationUpdate', locationData);
      Logger.log("📍 Seeker sent location: ($latitude, $longitude)", type: "success");

    } catch (e) {
      Logger.log("❌ Error sending seeker location: $e", type: "error");
    }
  }

  // Listen for helper location updates
  void onHelperLocationUpdate(Function(dynamic) callback) {
    socket.off('receiveLocationUpdate');
    socket.on('receiveLocationUpdate', callback);
  }

  // Listen for help request acceptance
  void onHelpRequestAccepted(Function(dynamic) callback) {
    socket.off('helpRequestAccepted');
    socket.on('helpRequestAccepted', callback);
  }

  // Listen for help request cancellation
  void onHelpRequestCancelled(Function(dynamic) callback) {
    socket.off('helpRequestCancelled');
    socket.on('helpRequestCancelled', callback);
  }

  // Listen for help request completion
  void onHelpRequestCompleted(Function(dynamic) callback) {
    socket.off('helpRequestCompleted');
    socket.on('helpRequestCompleted', callback);
  }

  @override
  void onClose() {
    leaveHelpRequestRoom();
    socket.disconnect();
    socket.dispose();
    super.onClose();
  }

}