import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/logger.dart';

import '../../utils/app_constant.dart';
import '../../views/screen/auth/otp_verify_screen.dart';
import '../../views/screen/auth/reset_pass_screen.dart';
import '../../views/screen/auth/success_message_screen.dart';
import '../networkService/networkService.dart';

class ForgotController extends GetxController {

  RxBool isForgot = false.obs;
  final TextEditingController forgotEmail = TextEditingController();

  Future<void> forgotPassword(BuildContext context, String emails,) async {
    final networkController = Get.find<NetworkController>();
    final url = '${AppConstants.BASE_URL}/api/auth/forgot-password';

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isForgot.value = true;

    final body = {
      "email": emails,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Logger.log("Forgot successful: $data", type: "info");
        if(context.mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SimpleOtpScreen(email: emails,)),);
        }

      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Signup failed.";
        Logger.log("Signup failed: $data", type: "error");
      }
    }on Exception catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
    } finally {
      isForgot.value = false;
    }
  }

  RxBool isVerify = false.obs;

  Future<void> verifyEmail(BuildContext context,String email, String otp,) async {
    final networkController = Get.find<NetworkController>();
    final url = '${AppConstants.BASE_URL}/api/auth/verify-otp';

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isVerify.value = true;

    final body = {
      "email": email,
      "otp": otp,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final reset_token = data['reset_token'];
        Logger.log("Forgot successful: $data", type: "info");
        isVerify.value = false;
        if(context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => SuccessMessageScreen(title: "OTP Verification Successful",details: "You can now reset your password",buttonText: "go to password reset",onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (builder)=>ResetPassScreen(token: reset_token,)));

              },),

            ),
          );
        }

      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Signup failed.";
        Logger.log("Signup failed: $data", type: "error");
        isVerify.value = false;

      }
    }on Exception catch (e, stackTrace) {
      isVerify.value = false;
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
    } finally {
      isVerify.value = false;
    }
  }



}