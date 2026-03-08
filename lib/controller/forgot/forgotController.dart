import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/app_constant.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';

import '../../views/screen/auth/otp_verify_screen.dart';
import '../../views/screen/auth/reset_pass_screen.dart';
import '../../views/screen/auth/success_message_screen.dart';
import '../networkService/networkService.dart';

class ForgotController extends GetxController {
  RxBool isForgot = false.obs;
  final TextEditingController forgotEmail = TextEditingController();

  Future<void> forgotPassword(BuildContext context, String emails) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isForgot.value = true;

    final body = {"email": emails};

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.log("Forgot successful: $data", type: "info");
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SimpleOtpScreen(email: emails, isSignUp: false),
            ),
          );
        }
      } else {
        final message = data["message"] ?? "Something went wrong";
        Logger.log("Forgot failed: $message", type: "error");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } on Exception catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isForgot.value = false;
    }
  }

  RxBool isVerify = false.obs;

  Future<void> verifyEmail(
      BuildContext context, String email, String otp) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isVerify.value = true;

    final body = {"email": email, "otp": otp};

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resetToken = data['reset_token'];
        Logger.log("OTP verify successful: $data", type: "info");
        isVerify.value = false;
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessMessageScreen(
                title: "OTP Verification Successful",
                details: "You can now reset your password",
                buttonText: "go to password reset",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResetPassScreen(token: resetToken),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        final message = data["message"] ?? "OTP verification failed";
        Logger.log("OTP verify failed: $message", type: "error");
        isVerify.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } on Exception catch (e, stackTrace) {
      isVerify.value = false;
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isVerify.value = false;
    }
  }

  Future<void> singupEmail(
      BuildContext context, String email, String otp) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isVerify.value = true;

    final body = {"email": email, "otp": otp};

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/api/auth/verify-signup-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.log("Signup OTP verify successful: $data", type: "info");
        isVerify.value = false;
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessMessageScreen(
                title: "OTP Verification Successful",
                details: "You can now reset your password",
                buttonText: "Go To Login Screen",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SigninScreen()),
                  );
                },
              ),
            ),
          );
        }
      } else {
        final message = data["message"] ?? "OTP verification failed";
        Logger.log("Signup OTP verify failed: $message", type: "error");
        isVerify.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } on Exception catch (e, stackTrace) {
      isVerify.value = false;
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isVerify.value = false;
    }
  }

  Future<void> resendSignupOtp(BuildContext context, String email) async {
    final networkController = Get.find<NetworkController>();

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/api/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.log("OTP resent successfully", type: "info");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final message = data["message"] ?? "Failed to resend OTP";
        Logger.log("Resend OTP failed: $message", type: "error");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      Logger.log("Error resending OTP: $e", type: "error");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> resendForgotOtp(BuildContext context, String email) async {
    await forgotPassword(context, email);
  }
}