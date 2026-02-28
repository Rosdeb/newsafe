import 'package:get/get.dart';
import '../UserController/userController.dart';

/// Backend uses a single role "both" for all users. Role switching is no longer supported.
/// This controller is kept minimal for any legacy references; role is always "both".
class UserRoleController extends GetxController {
  final userController = Get.find<UserController>();
  final RxBool helpGiver = false.obs;
  final RxBool helpSeeker = false.obs;
  final RxBool both = true.obs;

  @override
  void onInit() {
    super.onInit();
    ever(userController.userRole, (_) => updateRoleFlags());
    updateRoleFlags();
  }

  void updateRoleFlags() {
    // Backend and app now use unified "both" role only
    final role = userController.userRole.value;
    helpGiver.value = role == "giver";
    helpSeeker.value = role == "seeker";
    both.value = role == "both" || role.isEmpty;
  }
}
