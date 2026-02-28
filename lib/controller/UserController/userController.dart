import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:saferader/utils/logger.dart';

class UserController extends GetxController {

  RxString userRole = "seeker".obs;
  RxString userName = "".obs;
  RxString userEmail = "".obs;
  RxString userPhone = "".obs;
  RxString userImage = "".obs;
  RxString userGender = "".obs;
  RxString userDob = "".obs;


  @override
  void onInit() {
    super.onInit();
    loadUserRole();
    _loadFromHive();
  }

  Future<void> loadUserRole() async {
    try {
      final box = await Hive.openBox('userBox');
      final savedRole = box.get('role', defaultValue: 'both');
      userRole.value = savedRole;
    } catch (e) {
      Logger.log("Error loading user role: $e", type: "error");
    }
  }

  Future<void> saveUserRole(String role) async {
    try {
      final box = await Hive.openBox('userBox');
      await box.put('role', role);
      userRole.value = role;
    } catch (e) {
      Logger.log("Error saving user role: $e", type: "error");
    }
  }

  Future<void> _loadFromHive() async {
    try {
      final box = await Hive.openBox('userProfileBox');
      userName.value = box.get('name', defaultValue: '') ?? '';
      userEmail.value = box.get('email', defaultValue: '') ?? '';
      userPhone.value = box.get('phone', defaultValue: '') ?? '';
      userImage.value = box.get('image', defaultValue: '') ?? box.get('profileImage', defaultValue: '') ?? '';
      userGender.value = box.get('gender', defaultValue: '') ?? '';
      userDob.value = box.get('dateOfBirth', defaultValue: '') ?? '';
      userRole.value = box.get('role', defaultValue: '') ?? '';
    } catch (e) {
      Logger.log("❌ Failed to load user data from Hive: $e", type: "error");
    }
  }

  Future<void> clearUserRole() async {
    try {
      final box = await Hive.openBox('userBox');
      await box.delete('role');
      userRole.value = "both";
    } catch (e) {
      Logger.log("Error clearing user role: $e", type: "error");
    }
  }

  bool isSeeker() => userRole.value == "seeker";
  bool isGiver() => userRole.value == "giver";
  bool isBoth() => userRole.value == "both";

  bool canAccessSeekerFeatures() => userRole.value == "seeker" || userRole.value == "both";
  bool canAccessGiverFeatures() => userRole.value == "giver" || userRole.value == "both";

}