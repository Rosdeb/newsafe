import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:saferader/utils/logger.dart';
import 'package:http/http.dart' as http;
import '../../Service/Firebase/notifications.dart';
import '../../utils/app_constant.dart';
import '../../utils/token_service.dart';
import '../../views/screen/bottom_nav/bottom_nav_wrappers.dart';
import '../UserController/userController.dart';
import '../networkService/networkService.dart';

class SigInController extends GetxController {
  RxBool passShowHide = false.obs;
  RxBool rememberMe = false.obs;
  RxBool isLoading = false.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();


  Future<void> loginUser(
      BuildContext context,
      String emails,
      String passwords,
      ) async {
    final String url = '${AppConstants.BASE_URL}/api/auth/login';
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      //print("Please connect to the internet!");
      return;
    }

    isLoading.value = true;

    final body = {
      'email': emails,
      'password': passwords,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final user = data['user'];
          final token = data["accessToken"];
          final refreshToken = data['refreshToken'];
          final id = user['_id'];
          final role = data['user']['role'];


          await TokenService().saveToken(token);
          await TokenService().saveUserId(id);
          await TokenService().saveRefreshToken(refreshToken);

          final userBox = await Hive.openBox('userProfileBox');
          await userBox.put('name', user['name'] ?? '');
          await userBox.put('email', user['email'] ?? '');
          await userBox.put('_id', user['_id'] ?? '');
          await userBox.put('role', user['role'] ?? '');


          await userBox.put('phone', user['phone'] ?? '');
          await userBox.put('dateOfBirth', user['dateOfBirth'] ?? '');
          await userBox.put('gender', user['gender'] ?? '');
          await userBox.put('image', user['profileImage'] ?? user['profileImage'] ?? '');

          Logger.log("✅ Login successful - Basic info saved to Hive", type: "info");

          final userController = Get.find<UserController>();
          await userController.saveUserRole(role);

          if (rememberMe.value) {
            await saveCredentials(emails.trim(), passwords.trim());
          } else {
            await clearCredentials();
          }

          if(context.mounted){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (builder) => BottomMenuWrappers()),
            );
          }
          registerFcmToken();
          Logger.log("Login successful $data", type: "info");
        } on Exception catch (e) {
          Logger.log("Error parsing success response: $e", type: "error");

        }
      } else if (response.statusCode == 502) {
        final data = jsonDecode(response.body);
        Logger.log("Server error (502): ${data}", type: "error");
      } else {
        try {
          final data = jsonDecode(response.body);
          final message = data["message"] ?? "Login failed. Please try again.";
          Logger.log("Login failed: $message", type: "error");

        }on Exception catch (e) {
          Logger.log("Error response (${response.statusCode}): ${response.body}", type: "error");

        }
      }
    }on Exception catch (e, stackTrace) {
      Logger.log("Unexpected error: $e", type: "error");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerFcmToken() async {
    final fcmToken = await PrefsHelper.getString(AppConstants.fcmToken);
    final accessToken = await TokenService().getToken();
    final networkController = Get.find<NetworkController>();

    if (fcmToken == null) {
      Logger.log("❌ No FCM token found to register", type: "error");
      return;
    }

    if (!networkController.isOnline.value) {
      print("Please connect to the internet! in fcmToken");
      return;
    }

    final String url = "${AppConstants.BASE_URL}/api/users/me/fcm-token";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({"token": fcmToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.log("✅ FCM token registered successfully", type: "info");
      } else {
        Logger.log(
          "❌ Failed to register FCM token: ${response.body}",
          type: "error",
        );
      }
    }on Exception catch (e) {
      Logger.log("❌ Error sending FCM token: $e", type: "error");
    }
  }

  Future<void> loadRememberedCredentials() async {
    try {
      final box = await Hive.openBox('rememberMeBox');
      final savedEmail = box.get('email');
      final savedPassword = box.get('password');
      final savedRememberMe = box.get('rememberMe', defaultValue: false);

      if (savedRememberMe == true && savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe.value = true;
      }
    }on Exception catch (e) {
      Logger.log("Error loading remembered credentials: $e", type: "error");
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    try {
      final box = await Hive.openBox('rememberMeBox');
      await box.put('email', email);
      await box.put('password', password);
      await box.put('rememberMe', true);
    }on Exception catch (e) {
      Logger.log("Error saving credentials: $e", type: "error");
    }
  }

  Future<void> clearCredentials() async {
    try {
      final box = await Hive.openBox('rememberMeBox');
      await box.delete('email');
      await box.delete('password');
      await box.put('rememberMe', false);
    }on Exception catch (e) {
      Logger.log("Error clearing credentials: $e", type: "error");
    }
  }

  void rememberToggle() {
    rememberMe.value = !rememberMe.value;
  }

  void toggle() {
    passShowHide.value = !passShowHide.value;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}