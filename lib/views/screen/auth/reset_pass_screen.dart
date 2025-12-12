import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:saferader/controller/password_reset/password_reset.dart';
import 'package:saferader/views/screen/auth/signUpPage/sign_up_screen.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';
import 'package:saferader/views/screen/auth/success_message_screen.dart';

import '../../../controller/signInController/signIn.dart';
import '../../../utils/app_color.dart';
import '../../../utils/app_utils.dart';
import '../../base/AppText/appText.dart';
import '../../base/AppTextField/apptextfield.dart';
import '../../base/animationsWrapper/animations_wrapper.dart';
import '../welcome/welcome_sreen.dart';
import 'base/back_to_login.dart';
class ResetPassScreen extends StatelessWidget {
  final String token;
  ResetPassScreen({super.key, required this.token});

  final PasswordReset controller = Get.put(PasswordReset());


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
          height: 434,
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
              SizedBox(height: size.height * 0.02),
              const AnimatedAppText(
                "Forgot Password",
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEDC602),
              ),
              SizedBox(height: size.height * 0.008),
              const AppText(
                "Enter your email address and we’ll send your a link to reset your password",
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.colorSubheading,
                textAlign: TextAlign.center,
              ),
               SizedBox(height: size.height * 0.023),
              const  Align(
                alignment: Alignment.topLeft,
                child: AppText(
                  "New Password",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colorSubheading,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              Obx(() => AppTextField(
                obscure: controller.passShowHide.value,
                keyboardType: TextInputType.twitter,
                controller: controller.oldPassword,
                hint: "Enter your password",
                suffix: IconButton(
                  icon: Icon(
                    controller.passShowHide.value
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: Colors.white38,
                  ),
                  onPressed: () {
                    controller.toggle();
                  },
                ),
              )),
              SizedBox(height: size.height * 0.025),
              const Align(
                alignment: Alignment.topLeft,
                child: AppText(
                  "New Password",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colorSubheading,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              Obx(() => AppTextField(
                obscure: controller.passShowHide.value,
                keyboardType: TextInputType.twitter,
                controller: controller.newPassword,
                hint: "Enter new password",
                suffix: IconButton(
                  icon: Icon(
                    controller.passShowHide.value
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: Colors.white38,
                  ),
                  onPressed: () {
                    controller.toggle();
                  },
                ),
              )),
              SizedBox(height: size.height * 0.03),
              EnhancedAnimatedWrapper(
                duration:const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 400),
                direction: AnimationDirection.bottom,
                curve: Curves.elasticOut,
                child: Obx(()=>GradientButton(
                  isLoading:controller.isLoading.value,
                  text: "submit".toUpperCase(),
                  onTap: () {
                    final password = controller.oldPassword.text;
                    final newPassword = controller.newPassword.text;
                    if(password.isEmpty|| newPassword.isEmpty){
                      ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                          backgroundColor: Colors.black,
                          content:  Text(
                            'Required fields missing!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }if (password != newPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Passwords do not match!", style: TextStyle(color: Colors.red)),
                          backgroundColor: Colors.black,
                        ),
                      );
                      return;
                    }else{
                      controller.resetPassword(context,newPassword ,token);
                    }

                  },
                ),)
              ),
              SizedBox(height: size.height * 0.02),

            ],
          ),
        ),
      ),
    );
  }
}
