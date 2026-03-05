import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';
import '../../utils/api_service.dart';
import '../../views/screen/auth/otp_verify_screen.dart';
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
    }else if (index==1){
      selectedRole.value = 'giver';
    }else{
      selectedRole.value = 'both';
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
      final apiService = ApiService();
      final response = await apiService.post(
        endpoint: '/api/auth/signup',
        body: body,
        requiresAuth: false,
      );

      if (response != null) {
        final message = response['message'];
        Logger.log("Signup successful", type: "info");
        if(context.mounted){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SimpleOtpScreen(email: email,isSignUp: true,)));
        }

      } else {
        Logger.log("Signup failed", type: "error");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup failed. Please try again',style:TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),),
            backgroundColor: Colors.red,
            duration:Duration(seconds: 2),
          ),
        );
      }
    }on Exception catch (e, stackTrace) {
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");

    } finally {
      isLoading.value = false;
    }
  }


}