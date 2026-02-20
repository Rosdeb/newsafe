import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:saferader/utils/logger.dart';

import '../SocketService/socket_service.dart';

class BothHomeController extends GetxController {
  RxBool isLoading = false.obs;
  RxString userName = ''.obs;
  RxString userRole = ''.obs;
  RxString currentMode = 'seeker'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void toggleMode() {
    currentMode.value = currentMode.value == 'seeker' ? 'giver' : 'seeker';
    if (Get.isRegistered<SocketService>()) {
      final socketService = Get.find<SocketService>();
      socketService.updateRole(currentMode.value);
    }
    Logger.log("🔄 Switched to ${currentMode.value} mode", type: "info");
  }

  RxBool isAvailableAsGiver = false.obs;

  void toggleGiverAvailability() {
    isAvailableAsGiver.value = !isAvailableAsGiver.value;
    Logger.log("🔄 Giver availability: ${isAvailableAsGiver.value}", type: "info");
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;

      final userBox = await Hive.openBox('userProfileBox');

      final name = userBox.get('name');
      final email = userBox.get('email');
      final phone = userBox.get('phone');
      final dob = userBox.get('dateOfBirth');
      final id = userBox.get('_id');
      final role = userBox.get('role');
      Logger.log(
        "Raw Hive Data - name: $name, email: $email, phone: $phone, dob: $dob",
        type: "info",
      );
      userName.value = name ?? '';
      userRole.value = role ?? '';
      Logger.log("User data loaded - Name: ${userName.value}", type: "info");
    } on Exception catch (e) {
      Logger.log("Error loading user data: $e", type: "error");
      userName.value = 'Error loading';
    } finally {
      isLoading.value = false;
    }
  }
}
