import 'package:saferader/utils/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'dart:async';

class HelpGiverSocketService extends GetxService {
  late IO.Socket socket;
  final RxBool isConnected = false.obs;
  String? currentRoom;

  // Add a completer to track connection
  Completer<void>? _connectionCompleter;

  Future<HelpGiverSocketService> init(String token) async {
    // Initialize completer
    _connectionCompleter = Completer<void>();

    socket = IO.io(
      "https://tabs-tions-tennessee-latina.trycloudflare.com",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      isConnected.value = true;
      Logger.log("🔌 Giver Socket Connected - ID: ${socket.id}", type: "success");

      // Complete the connection promise
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete();
      }

      // Rejoin room if we were in one
      if (currentRoom != null) {
        joinRoom(currentRoom!);
      }
    });

    socket.onDisconnect((_) {
      isConnected.value = false;
      Logger.log("❌ Giver Socket Disconnected", type: "warning");
    });

    socket.onConnectError((data) {
      Logger.log("❌ Giver Socket Connect Error: $data", type: "error");

      // Complete with error if not yet completed
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError('Connection failed: $data');
      }
    });

    socket.onError((data) {
      Logger.log("❌ Giver Socket Error: $data", type: "error");
    });

    // Start connection
    socket.connect();

    // Wait for connection with timeout
    try {
      await _connectionCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Logger.log("⏰ Giver socket connection timeout", type: "error");
          throw TimeoutException('Giver socket connection timeout');
        },
      );
      Logger.log("✅ Giver socket connection established successfully", type: "success");
    } catch (e) {
      Logger.log("❌ Failed to establish giver socket connection: $e", type: "error");
      rethrow;
    }

    return this;
  }

  void disconnectAndDispose() {
    try {
      if (currentRoom != null) {
        leaveRoom(currentRoom!);
      }

      final events = [
        'connect',
        'disconnect',
        'connect_error',
        'error',
        'newHelpRequest',
        'helpRequestAccepted',
        'receiveLocationUpdate',
        'helpRequestCancelled',
        'helpRequestCompleted',
        'sendLocationUpdate',
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
      Logger.log("🔌 Giver socket properly disposed", type: "info");
    } catch (e) {
      Logger.log("❌ Error disposing giver socket: $e", type: "error");
    }
  }

  void sendLocationUpdate(double latitude, double longitude, {String? helpRequestId}) {
    try {
      if (!isConnected.value) {
        Logger.log("⚠️ Giver socket not connected, cannot send location", type: "warning");
        return;
      }

      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'helpRequestId': helpRequestId ?? currentRoom,
        'timestamp': DateTime.now().toIso8601String(),
      };

      socket.emit('sendLocationUpdate', locationData);
      Logger.log("📍 Giver sent location update: ($latitude, $longitude)", type: "success");

    } catch (e) {
      Logger.log("❌ Error sending giver location update: $e", type: "error");
    }
  }

  void joinRoom(String roomId) {
    if (currentRoom != null && currentRoom != roomId) {
      leaveRoom(currentRoom!);
    }

    socket.emit("joinRoom", roomId);
    currentRoom = roomId;
    Logger.log("📤 Giver joined room: $roomId", type: "info");
  }

  void leaveRoom(String roomId) {
    socket.emit("leaveRoom", roomId);
    if (currentRoom == roomId) {
      currentRoom = null;
    }
    Logger.log("📤 Giver left room: $roomId", type: "info");
  }

  @override
  void onClose() {
    disconnectAndDispose();
    super.onClose();
  }
}