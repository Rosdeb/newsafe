import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:saferader/controller/forgot/forgotController.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/screen/auth/otp_verify_screen.dart';

import '../../../base/AppTextField/apptextfield.dart';
import '../../../base/animationsWrapper/animations_wrapper.dart';
import '../../welcome/welcome_sreen.dart';
import '../base/back_to_login.dart';

class ForgotScreen extends StatelessWidget {
  ForgotScreen({super.key});

  final TextEditingController email = TextEditingController();
  final ForgotController controller = Get.put(ForgotController());


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    SystemChrome.setSystemUIOverlayStyle(
     const SystemUiOverlayStyle(
        statusBarColor: Color(0xff202020),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor:const Color(0xff202020),
      body: Center(
        child: Container(
          height: 371,
          width: double.infinity,
          padding:const EdgeInsets.symmetric(horizontal: 24),
          margin:const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.fill_Color2,
            border: Border.all(width: 0.5, color: AppColors.colorYellow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              AnimatedAppText(
                "Forgot Password".tr,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEDC602),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              AppText(
                "Enter your email address and we’ll send you a link to reset your password".tr,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.colorSubheading,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Align(
                alignment: Alignment.topLeft,
                child: AppText(
                  "Email Address".tr,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colorSubheading,
                ),
              ),
              SizedBox(height: size.height * 0.020),
              AppTextField(
                keyboardType: TextInputType.emailAddress,
                controller: controller.forgotEmail,
                hint: "Enter your email".tr,
                suffix:const Icon(CupertinoIcons.mail, color: Colors.white38),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),

              EnhancedAnimatedWrapper(
                duration:const Duration(milliseconds: 500),
                delay:const Duration(milliseconds: 400),
                direction: AnimationDirection.bottom,
                curve: Curves.elasticOut,
                child: Obx((){
                  return GradientButton(
                    isLoading: controller.isForgot.value,
                    text: "Send reset link".tr.toUpperCase(),
                    onTap: ()async {

                      controller.forgotPassword(context, controller.forgotEmail.text.toString());
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (builder) => const SimpleOtpScreen(),
                      //   ),
                      // );
                    },
                  );
                })
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              AnimatedWidgetWrapper(
                child: BackToLogin(
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
