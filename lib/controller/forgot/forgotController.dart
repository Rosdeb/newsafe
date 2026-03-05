import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';

import '../../utils/api_service.dart';
import '../../views/screen/auth/otp_verify_screen.dart';
import '../../views/screen/auth/reset_pass_screen.dart';
import '../../views/screen/auth/success_message_screen.dart';
import '../networkService/networkService.dart';

class ForgotController extends GetxController {

  RxBool isForgot = false.obs;
  final TextEditingController forgotEmail = TextEditingController();

  Future<void> forgotPassword(BuildContext context, String emails,) async {
    final networkController = Get.find<NetworkController>();

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
      final apiService = ApiService();
      final response = await apiService.post(
        endpoint: '/api/auth/forgot-password',
        body: body,
        requiresAuth: false,
      );

      if (response != null) {
        Logger.log("Forgot successful: $response", type: "info");
        if(context.mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SimpleOtpScreen(email: emails,isSignUp: false,)),);
        }

      } else {
        Logger.log("Signup failed", type: "error");
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
      final apiService = ApiService();
      final response = await apiService.post(
        endpoint: '/api/auth/verify-otp',
        body: body,
        requiresAuth: false,
      );

      if (response != null) {
        final reset_token = response['reset_token'];
        Logger.log("Forgot successful: $response", type: "info");
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
        Logger.log("Signup failed", type: "error");
        isVerify.value = false;

      }
    }on Exception catch (e, stackTrace) {
      isVerify.value = false;
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
    } finally {
      isVerify.value = false;
    }
  }

  Future<void> singupEmail(BuildContext context,String email, String otp,) async {
    final networkController = Get.find<NetworkController>();

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
      final apiService = ApiService();
      final response = await apiService.post(
        endpoint: '/api/auth/verify-signup-otp',
        body: body,
        requiresAuth: false,
      );

      if (response != null) {
        Logger.log("Forgot successful: $response", type: "info");
        isVerify.value = false;
        if(context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) => SuccessMessageScreen(title: "OTP Verification Successful",details: "You can now reset your password",buttonText: "Go To Login Screen",onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (builder)=>SigninScreen()));
              },),

            ),
          );
        }

      } else {
        Logger.log("Signup failed", type: "error");
        isVerify.value = false;

      }
    }on Exception catch (e, stackTrace) {
      isVerify.value = false;
      Logger.log("Unexpected error: $e\nStack: $stackTrace", type: "error");
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
      final apiService = ApiService();
      final response = await apiService.post(
        endpoint: '/api/auth/resend-otp',
        body: {"email": email},
        requiresAuth: false,
      );

      if (response != null) {
        Logger.log("OTP resent successfully", type: "info");
      } else {
        Logger.log("Failed to resend OTP", type: "error");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to resend OTP'),
              backgroundColor: Colors.red,
            ),
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
    // Call your forgot password API again to resend OTP
    await forgotPassword(context, email);
  }

/*  // Rename your existing verify method to signupEmail
  Future<void> signupEmail(BuildContext context, String email, String otp) async {
    // Your existing verify email logic for signup
    final networkController = Get.find<NetworkController>();
    final url = '${AppConstants.BASE_URL}/api/auth/verify-email';

    if (!networkController.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    isVerify.value = true;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "otp": otp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.log("Email verified successfully", type: "info");
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SigninScreen()),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        final message = data["message"] ?? "Verification failed";
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.log("Error verifying email: $e", type: "error");
    } finally {
      isVerify.value = false;
    }
  }*/




}