import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/logger.dart';

import '../../utils/app_constant.dart';
import '../../views/screen/auth/signinPage/signIn_screen.dart';
import '../../views/screen/auth/success_message_screen.dart';
import '../networkService/networkService.dart';

class PasswordReset extends GetxController{

  RxBool isLoading = false.obs;
  RxBool passShowHide = false.obs;
  RxBool passShowHide1 = false.obs;
  final TextEditingController oldPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();

  void toggle(){
    passShowHide.value =! passShowHide.value;
  }
  void toggle1(){
    passShowHide1.value =! passShowHide1.value;
  }
  Future<void> resetPassword(BuildContext context, String password,String token) async {
    final networkController = Get.find<NetworkController>();
    final url = '${AppConstants.BASE_URL}/api/auth/reset-password';

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isLoading.value = true;

    final body = {
      "reset_token": token,
      "password": password,
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
        Logger.log("Reset successful: $data", type: "info");
        if(context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => SuccessMessageScreen(title: "Password Reset Successful",details: "YYou can now login with your New Password",buttonText: "go to sign in",onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (builder)=>SigninScreen()));
              },),
            ),
          );
        }

      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Reset failed.";
        Logger.log("Reset failed: $data", type: "error");
      }
    }on Exception catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
    } finally {
      isLoading.value = false;
    }
  }


}