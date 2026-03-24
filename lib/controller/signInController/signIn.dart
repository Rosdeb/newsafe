import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/Service/AppleSign/appleSignInServices.dart';
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/Service/Firebase/notifications.dart';
import '../../utils/token_service.dart';
import '../../views/screen/bottom_nav/bottom_nav_wrappers.dart';
import '../UserController/userController.dart';
import '../networkService/networkService.dart';

class SigInController extends GetxController {
  RxBool passShowHide = false.obs;
  RxBool rememberMe = false.obs;
  RxBool isLoading = false.obs;
  RxBool appleLoading = false.obs;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginUser(
      BuildContext context,
      String emails,
      String passwords,
      ) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isLoading.value = true;

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await PrefsHelper.setString(AppConstants.fcmToken, fcmToken);
    }

    final body = {
      'email': emails,
      'password': passwords,
      'fcmToken': fcmToken ?? '',
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token        = data['accessToken']  as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user         = data['user']         as Map<String, dynamic>?;

        Logger.log("Fcm Token: ${user?['fcmToken']}", type: "error");

        if (token == null || user == null) {
          Logger.log("Missing token or user in response", type: "error");
          return;
        }

        final id   = user['_id']  as String? ?? '';
        final role = user['role'] as String? ?? 'both';

        await TokenService().saveToken(token);
        await TokenService().saveUserId(id);
        await TokenService().saveRefreshToken(refreshToken ?? '');

        final userBox = await Hive.openBox('userProfileBox');
        await userBox.put('name',         user['name']         ?? '');
        await userBox.put('email',        user['email']        ?? '');
        await userBox.put('_id',          user['_id']          ?? '');
        await userBox.put('role',         role);
        await userBox.put('phone',        user['phone']        ?? '');
        await userBox.put('dateOfBirth',  user['dateOfBirth']  ?? '');
        await userBox.put('gender',       user['gender']       ?? '');
        await userBox.put('profileImage', user['profileImage'] ?? '');

        Logger.log("Login successful - user saved to Hive", type: "info");

        final userController = Get.find<UserController>();
        await userController.saveUserRole(role);

        if (rememberMe.value) {
          await saveCredentials(emails.trim(), passwords.trim());
        } else {
          await clearCredentials();
        }

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomMenuWrappers()),
          );
        }
      } else {
        final message = data["message"] ?? "Invalid credentials";
        Logger.log("Login failed: $message", type: "error");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on Exception catch (e) {
      Logger.log("Unexpected error: $e", type: "error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRememberedCredentials() async {
    try {
      final box = await Hive.openBox('rememberMeBox');
      final savedEmail     = box.get('email');
      final savedPassword  = box.get('password');
      final savedRememberMe = box.get('rememberMe', defaultValue: false);

      if (savedRememberMe == true &&
          savedEmail != null &&
          savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe.value = true;
      }
    } on Exception catch (e) {
      Logger.log("Error loading remembered credentials: $e", type: "error");
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    try {
      final box = await Hive.openBox('rememberMeBox');
      await box.put('email',      email);
      await box.put('password',   password);
      await box.put('rememberMe', true);
    } on Exception catch (e) {
      Logger.log("Error saving credentials: $e", type: "error");
    }
  }

  Future<void> clearCredentials() async {
    try {
      final box = await Hive.openBox('rememberMeBox');
      await box.delete('email');
      await box.delete('password');
      await box.put('rememberMe', false);
    } on Exception catch (e) {
      Logger.log("Error clearing credentials: $e", type: "error");
    }
  }

  Future<void> signInWithApple() async {
    try {
      appleLoading.value = true;
      final result = await AppleSignInService.signInWithApple();

      if (result == null) {
        appleLoading.value = false;
        print('User cancelled Apple Sign-In');
        return;
      }

      await sendAppleTokenToBackend(
        email: result['email'],
        displayName: result['displayName'],
        photoURL: result['photoURL'],
        identityToken : result['identityToken']
      );

      appleLoading.value = false;
      print('Apple Sign-In successful for ${result['email']}');
    } catch (e) {
      appleLoading.value = false;
      print("Apple Sign-In error: $e");
    }
  }


  Future<bool> sendAppleTokenToBackend({
    required String? email,
    required String? displayName,
    required String? photoURL,
    required String? identityToken,
  }) async {
    final url = "${AppConstants.BASE_URL}/api/v1/auth/login-with-apple";
    var fcmToken = await PrefsHelper.getString(AppConstants.fcmToken);

    final body = {
      'email': email,
      'name': displayName,
      'photoURL': photoURL,
      'identityToken':identityToken,
      'fcmToken': fcmToken,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Logger.log("Apple login response: $data");

        final accessToken = data['data']?['attributes']?['tokens']?['access']?['token'];
        final refreshToken = data['data']?['attributes']?['tokens']?['refresh']?['token'];
        final userId = data['data']?['attributes']?['user']?['id'];
        final isSubscribed = data['data']?['attributes']?['user']?['isSubscribed'] ?? false;

        Logger.log("AccessToken: $accessToken");
        Logger.log("RefreshToken: $refreshToken");
        Logger.log("UserId: $userId");
        Logger.log("IsSubscribed: $isSubscribed");

        // Save tokens and user info (including refresh token)
        if (accessToken != null && userId != null && refreshToken != null) {
          await TokenService().saveToken(accessToken);
          await TokenService().saveRefreshToken(refreshToken);
          await TokenService().saveUserId(userId);
          // if (email != null) {
          //   await TokenService().saveEmail(email);
          // }
        }
        if (isSubscribed == true) {
          Get.offAll(BottomMenuWrappers());
        } else {
          //Get.to(() => const Subscriptions(navigateAfterSuccess: true));
        }
        return true;
      } else {
        String message = "Something went wrong";
        try {
          final body = jsonDecode(response.body);
          message = body['message'] ?? message;
        } catch (_) {}
        Get.snackbar("Failed", message);
        Logger.log("Apple login failed: ${response.body}", type: "error");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
      Logger.log("Apple login error: $e", type: "error");
      return false;
    }
  }

  void rememberToggle() => rememberMe.value = !rememberMe.value;

  void toggle() => passShowHide.value = !passShowHide.value;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}