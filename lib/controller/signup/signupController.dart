import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:saferader/utils/logger.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';
import '../../utils/app_constant.dart';
import '../../utils/token_service.dart';
import '../../views/screen/auth/otp_verify_screen.dart';
import '../../views/screen/bottom_nav/bottom_nav_wrappers.dart';
import '../UserController/userController.dart';
import '../networkService/networkService.dart';


class SignUpController extends GetxController{
  final RxBool passShowHide = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool passShowHide1 = false.obs;
  final RxBool rememberMe = false.obs;
  final RxString selectedRole = 'seeker'.obs;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();


 void toggle(){
   passShowHide.value =! passShowHide.value;
 }


  void toggle1(){
    passShowHide1.value =! passShowHide1.value;
  }

  final RxInt selectedIndex = 0.obs;

  void tapSelected(int index){
    selectedIndex.value = index;
    if(index==0){
      selectedRole.value = 'seeker';
    }else{
      selectedRole.value = 'giver';
    }
  }

  void togglePrivacy(){
    rememberMe.value = ! rememberMe.value;
  }

  Future<void> signUpUser({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
 }) async {
    final networkController = Get.find<NetworkController>();
    final url = '${AppConstants.BASE_URL}/api/auth/signup';

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isLoading.value = true;

    final body = {
      "name": name,
      "email": email,
      "phoneNumber": phone,
      "password": password,
      "role": role,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = data['message'];
        // final token = data["accessToken"];
        // final refresh = data["refreshToken"];
        // final role = data["user"]["role"];
        // await TokenService().saveToken(token);
        // await TokenService().saveRefreshToken(refresh);
        // final userController = Get.find<UserController>();
        // await userController.saveUserRole(role);
        Logger.log("Signup successful", type: "info");
        if(context.mounted){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SigninScreen()));
        }

      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Signup failed.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message,style:const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),),
            backgroundColor: Colors.red,
            duration:const Duration(seconds: 2),
          ),
        );
        Logger.log("Signup failed: $data", type: "error");
      }
    }on Exception catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");

    } finally {
      isLoading.value = false;
    }
  }


}