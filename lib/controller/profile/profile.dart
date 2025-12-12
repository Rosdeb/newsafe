import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_constant.dart';
import '../../utils/token_service.dart';
import '../networkService/networkService.dart';

class ProfileController extends GetxController {
  TextEditingController password = TextEditingController();
  RxBool passShowHide = true.obs;
  RxBool isLoading = false.obs;
  RxBool isDistance = false.obs;

  // ------------------ User Profile Values ------------------
  RxString userName = ''.obs;
  RxString userEmail = ''.obs;
  RxString userPhone = ''.obs;
  RxString userId = ''.obs;
  RxString userRole = ''.obs;
  RxString emails = ''.obs;
  RxString genders = ''.obs;
  RxString phones = ''.obs;
  RxString dateOfBirth = ''.obs;
  RxString profileImage = ''.obs;
  RxString firstName = ''.obs;
  RxString lastName = ''.obs;
  RxString selectedLanguage = "English".obs;
  RxString distance = '1'.obs;
  void toggle() => passShowHide.value = !passShowHide.value;

  @override
  void onInit() {
    super.onInit();
    password.text = "myCurrentPassword";
    loadUserData();
  }

  void setLanguage(String lang) => selectedLanguage.value = lang;
  void setDistance(String dis) => distance.value = dis;

  String formatDate(String date) {
    try {
      return date.split("T")[0];
    } catch (_) {
      return date;
    }
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;

      final userBox = await Hive.openBox('userProfileBox');

      final name = userBox.get('name');
      final email = userBox.get('email');
      final phone = userBox.get('phone');
      final gender = userBox.get('gender');
      final dob = userBox.get('dateOfBirth');
      final id = userBox.get('_id');
      final role = userBox.get('role');
      final image = userBox.get('profileImage');

      Logger.log("📦 Raw Hive Data Loaded: name=$name email=$email phone=$phone dob=$dob profile$image", type: "info");

      userName.value = name ?? '';
      userEmail.value = email ?? '';
      userPhone.value = phone ?? 'Not provided';
      userId.value = id ?? '';
      userRole.value = role ?? '';
      profileImage.value = image ?? '';
      genders.value = gender ?? '';

      // ---------------- Full Name Split ----------------
      if (name != null && name.toString().trim().isNotEmpty) {
        final parts = name.toString().trim().split(" ");
        firstName.value = parts.first;

        if (parts.length > 1) {
          lastName.value = parts.sublist(1).join(" ");
        }
      }

      // ---------------- Email ----------------
      emails.value = email?.toString() ?? '';

      // ---------------- Phone ----------------
      if (phone != null && phone.toString().trim().isNotEmpty) {
        phones.value = phone.toString();
      } else {
        phones.value = '';
      }

      // ---------------- DOB ----------------
      if (dob != null && dob.toString().trim().isNotEmpty) {
        dateOfBirth.value = formatDate(dob.toString());
      } else {
        dateOfBirth.value = 'Not provided';
      }

      Logger.log(
        "✅ User Loaded -> Name: ${userName.value}, Email: ${userEmail.value}, Phone: ${userPhone.value}, DOB: ${dateOfBirth.value}", type: "info",);

    }on Exception catch (e) {
      Logger.log("❌ Error loading user data: $e", type: "error");

      userName.value = 'Error loading';
      userEmail.value = 'Error loading';
      userPhone.value = 'Not available';
      dateOfBirth.value = 'Not available';

    } finally {
      isLoading.value = false;
    }
  }

  Future<void> preferableSetting(int distanceValue) async {
    final String url = '${AppConstants.BASE_URL}/api/users/me/preferences';
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      Logger.log("📵 No internet connection", type: "error");
      return;
    }

    isDistance.value = true;

    try {
      final token = await TokenService().getToken();

      if (token == null || token.isEmpty) {
        Logger.log("❌ No token found", type: "error");
        return;
      }

      final body = {
        'maxDistanceKm': distanceValue,
      };

      Logger.log("📤 Updating Preference: $body", type: "info");

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      Logger.log("📥 Status: ${response.statusCode}", type: "info");
      Logger.log("📥 Body: ${response.body}", type: "info");

      if (response.statusCode == 200) {
        Logger.log("✅ Preference updated successfully!", type: "success");

        // ✅ Save selected distance locally in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('selectedDistanceKm', distanceValue);

        // ✅ Update UI observable
        distance.value = distanceValue.toString();

      } else {
        final msg = jsonDecode(response.body)["message"] ?? "Update failed";
        Logger.log("❌ Error: $msg", type: "error");
      }
    } on Exception catch (e) {
      Logger.log("❌ Unexpected error: $e", type: "error");
    } finally {
      isDistance.value = false;
    }
  }

  Future<void> loadDistanceFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDistance = prefs.getInt('selectedDistanceKm') ?? 1;
    distance.value = savedDistance.toString();
  }

  Future<void> refreshProfile() async {
    await loadUserData();
  }
  
}
