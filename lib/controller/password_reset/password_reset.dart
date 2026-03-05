import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';

import '../../utils/api_service.dart';
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
      final apiService = ApiService();
      final response = await apiService.post(
        endpoint: '/api/auth/reset-password',
        body: body,
        requiresAuth: false,
      );

      if (response != null) {
        Logger.log("Reset successful: $response", type: "info");
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
        Logger.log("Reset failed", type: "error");
      }
    }on Exception catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
    } finally {
      isLoading.value = false;
    }
  }


}