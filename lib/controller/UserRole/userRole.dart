import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/logger.dart';
import 'package:saferader/utils/token_service.dart';
import '../../utils/app_constant.dart';
import '../GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../SeakerHome/seakerHomeController.dart';
import '../SeakerLocation/seakerLocationsController.dart';
import '../SocketService/socket_service.dart';
import '../UserController/userController.dart';
import '../networkService/networkService.dart';
import '../GiverHOme/giverSocket/helpGiversocket.dart';

class UserRoleController extends GetxController {
  final userController = Get.find<UserController>();
  final RxBool helpGiver = false.obs;
  final RxBool helpSeeker = false.obs;
  final RxBool both = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSwitchingSockets = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(userController.userRole, (_) => updateRoleFlags());
    updateRoleFlags();
  }

  void updateRoleFlags() {
    final role = userController.userRole.value;

    helpGiver.value = role == "giver";
    helpSeeker.value = role == "seeker";
    both.value = role == "both";
  }

  void setRole(String role) {
    Logger.log("🔄 Setting role to: $role", type: "info");

    // Turn off all switches first
    helpGiver.value = false;
    helpSeeker.value = false;
    both.value = false;

    // Turn on only the selected switch
    switch (role) {
      case "giver":
        helpGiver.value = true;
        break;
      case "seeker":
        helpSeeker.value = true;
        break;
      case "both":
        both.value = true;
        break;
    }

    // Update the user controller's role
    userController.userRole.value = role;
  }

  String get selectedRole {
    if (helpGiver.value) return "giver";
    if (helpSeeker.value) return "seeker";
    if (both.value) return "both";
    return "";
  }

  Future<void> switchSocket(String newRole) async {
    if (isSwitchingSockets.value) {
      Logger.log("⚠️ Socket switch already in progress", type: "warning");
      return;
    }

    isSwitchingSockets.value = true;

    try {
      final token = await TokenService().getToken();

      if (token == null || token.isEmpty) {
        Logger.log("❌ No token available for socket switch", type: "error");
        return;
      }

      Logger.log("🔄 Switching to role: $newRole", type: "info");

      // Stop location sharing first
      if (Get.isRegistered<SeakerLocationsController>()) {
        final locationController = Get.find<SeakerLocationsController>();
        locationController.stopLocationSharing();
      }


      await _waitForCleanup(milliseconds: 800);

      // Remove all socket services
      if (Get.isRegistered<SocketService>()) {
        await Get.delete<SocketService>(force: true);
      }

      // Initialize new socket with the correct role
      await Get.putAsync(() => SocketService().init(token, role: newRole));

      Logger.log("✅ Socket switched successfully for role: $newRole", type: "success");

    }on Exception catch (e) {
      Logger.log("❌ Error switching socket: $e", type: "error");
      Get.snackbar(
        "Connection Error",
        "Failed to switch connection. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSwitchingSockets.value = false;
    }
  }

  Future<void> _waitForCleanup({int milliseconds = 300}) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }


  // /// Disconnect ALL sockets completely
  // Future<void> _disconnectAllSockets() async {
  //   Logger.log("🔌 Disconnecting ALL sockets", type: "info");
  //
  //   // Disconnect and remove seeker socket
  //   await _disconnectSeekerSocket();
  //
  //   // Disconnect and remove giver socket
  //   await _disconnectGiverSocket();
  //
  //   // Also dispose any page controllers that might hold socket references
  //   await _disposePageControllers();
  //
  //   Logger.log("✅ All sockets and controllers disposed", type: "success");
  // }
  //
  // Future<void> _disconnectSeekerSocket() async {
  //   try {
  //     if (Get.isRegistered<SocketService>()) {
  //       final seekerSocket = Get.find<SocketService>();
  //
  //       // Use the disposal method
  //       seekerSocket.disconnectAndDispose();
  //
  //       // Remove from GetX
  //       await Get.delete<SocketService>(force: true);
  //
  //       Logger.log("✅ Seeker socket disconnected and removed", type: "success");
  //     }
  //   } catch (e) {
  //     Logger.log("❌ Error disconnecting seeker socket: $e", type: "error");
  //   }
  // }

  // Future<void> _disconnectGiverSocket() async {
  //   try {
  //     if (Get.isRegistered<HelpGiverSocketService>()) {
  //       final giverSocket = Get.find<HelpGiverSocketService>();
  //
  //       // Use the disposal method
  //       giverSocket.disconnectAndDispose();
  //
  //       // Remove from GetX
  //       await Get.delete<HelpGiverSocketService>(force: true);
  //
  //       Logger.log("✅ Giver socket disconnected and removed", type: "success");
  //     }
  //   } catch (e) {
  //     Logger.log("❌ Error disconnecting giver socket: $e", type: "error");
  //   }
  // }
  //
  // /// Dispose page controllers to avoid memory leaks
  // Future<void> _disposePageControllers() async {
  //   try {
  //     // 🔥 CRITICAL: Stop location sharing FIRST before disposing controllers
  //     if (Get.isRegistered<SeakerLocationsController>()) {
  //       final locationController = Get.find<SeakerLocationsController>();
  //       locationController.stopLocationSharing();
  //       Logger.log("📍 Stopped location sharing before controller disposal", type: "info");
  //     }
  //
  //     // Small delay to let location sharing stop
  //     await Future.delayed(const Duration(milliseconds: 200));
  //
  //     // Dispose GiverHomeController if exists
  //     if (Get.isRegistered<GiverHomeController>()) {
  //       final giverController = Get.find<GiverHomeController>();
  //       giverController.removeAllListeners(); // Remove listeners first
  //       giverController.onClose();
  //       await Get.delete<GiverHomeController>(force: true);
  //       Logger.log("✅ GiverHomeController disposed", type: "success");
  //     }
  //
  //     // Dispose SeakerHomeController if exists
  //     if (Get.isRegistered<SeakerHomeController>()) {
  //       final seekerController = Get.find<SeakerHomeController>();
  //       seekerController.removeAllListeners(); // Remove listeners first
  //       seekerController.onClose();
  //       await Get.delete<SeakerHomeController>(force: true);
  //       Logger.log("✅ SeakerHomeController disposed", type: "success");
  //     }
  //   } catch (e) {
  //     Logger.log("❌ Error disposing controllers: $e", type: "error");
  //   }
  // }
  //
  // /// 🔥 UPDATED: Removed extra delays - socket.init() now waits properly
  // Future<void> _connectNewSocket(String newRole, String token) async {
  //   Logger.log("🔌 Connecting new socket(s) for role: $newRole", type: "info");
  //
  //   try {
  //     switch (newRole) {
  //       case "seeker":
  //       // Connect only seeker socket - init() waits for connection
  //         await Get.putAsync(() => SocketService().init(token));
  //         Logger.log("✅ Seeker socket connected", type: "success");
  //         break;
  //
  //       case "giver":
  //       // Connect only giver socket - init() waits for connection
  //         await Get.putAsync(() => HelpGiverSocketService().init(token));
  //         Logger.log("✅ Giver socket connected", type: "success");
  //         break;
  //
  //       case "both":
  //       // Connect seeker socket first
  //         await Get.putAsync(() => SocketService().init(token));
  //         Logger.log("✅ Seeker socket connected", type: "success");
  //
  //         // Small delay between creating two sockets
  //         await Future.delayed(const Duration(milliseconds: 200));
  //
  //         // Connect giver socket
  //         await Get.putAsync(() => HelpGiverSocketService().init(token));
  //         Logger.log("✅ Giver socket connected", type: "success");
  //         break;
  //
  //       default:
  //         Logger.log("⚠️ Unknown role: $newRole", type: "warning");
  //     }
  //   } catch (e) {
  //     Logger.log("❌ Error connecting socket for role $newRole: $e", type: "error");
  //     rethrow; // Propagate error to be caught by switchSocket
  //   }
  // }

  Future<void> roleChange() async {
    final String url = '${AppConstants.BASE_URL}/api/users/me/role';
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      Logger.log("📵 No internet connection", type: "error");
      Get.snackbar(
        "No Internet",
        "Please check your connection",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isLoading.value || isSwitchingSockets.value) {
      Logger.log("⚠️ Role change or socket switch already in progress", type: "warning");
      return;
    }

    isLoading.value = true;

    try {
      final token = await TokenService().getToken();

      if (token == null || token.isEmpty) {
        Logger.log("❌ No token available", type: "error");
        isLoading.value = false;
        return;
      }

      final body = {
        'role': selectedRole,
      };

      Logger.log("📤 Sending role change request: ${jsonEncode(body)}", type: "info");

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      Logger.log("📥 Response status: ${response.statusCode}", type: "info");
      Logger.log("📥 Response body: ${response.body}", type: "info");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['data']['role'];

        // Save to local storage
        await userController.saveUserRole(role);

        // 🔥 CRITICAL: Stop location sharing BEFORE switching sockets
        if (Get.isRegistered<SeakerLocationsController>()) {
          final locationController = Get.find<SeakerLocationsController>();
          locationController.stopLocationSharing();
          Logger.log("📍 Stopped location sharing before socket switch", type: "info");
        }

        await switchSocket(role);

        Logger.log("✅ Role updated successfully: $role", type: "success");


        // Force UI refresh
        Get.forceAppUpdate();

      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Role update failed.";
        Logger.log("❌ Error: $message", type: "error");
        updateRoleFlags();
      }
    }on Exception catch (e) {
      Logger.log("❌ Unexpected error: $e", type: "error");
      updateRoleFlags();
    } finally {
      isLoading.value = false;
    }
  }
}