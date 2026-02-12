import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:saferader/controller/signup/signupController.dart';
import 'package:saferader/views/screen/auth/signUpPage/widget/simpleContainerLIst.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';
import 'package:saferader/views/screen/auth/signinPage/widget/gogleSignIn.dart';
import 'package:saferader/views/screen/auth/signinPage/widget/signupSection.dart';
import '../../../../utils/app_color.dart';
import '../../../../utils/app_icon.dart';
import '../../../base/AppText/appText.dart';
import '../../../base/Ios_effect/iosTapEffect.dart';
import '../../../base/animationsWrapper/animations_wrapper.dart';
import '../../bottom_nav/bottom_nav_wrappers.dart';
import '../../welcome/welcome_sreen.dart';
import '../base/countices.dart';
import '../base/input_signup.dart';
class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final SignUpController controller = Get.put(SignUpController());

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
      body:GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
        padding:const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.08),
            SvgPicture.asset(AppIcons.miniSafeRadar),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Align(
              alignment: Alignment.center,
              child: AnimatedAppText(
                "Join SafeRadar".tr,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEDC602),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            InputSignUpPage(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Container(
              height: 445,
              width: double.infinity,
              padding:const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.fill_Color2,
                border: Border.all(width: 0.5, color: AppColors.colorYellow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.01),
                  AnimatedAppText(
                    "Choose Your Role".tr,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEDC602),
                  ),
                  SizedBox(height: size.height * 0.008),
                  AppText(
                    "Select how you want to participate in the SafeRadar community".tr,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 2,
                    color: AppColors.colorSubheading,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.023),
                  SimpleAnimatedContainersListsss(),
                  SizedBox(height: size.height * 0.015),
                  AppText(
                    "You can change these settings anytime in your profile".tr,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.colorSubheading,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.008),


                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 35,
                  child: Obx(() => CupertinoCheckbox(
                    activeColor:AppColors.colorYellow,
                    value: controller.rememberMe.value,
                    onChanged: (_) {
                      controller.togglePrivacy();
                    },
                  )),
                ),
                RichText(
                  text: TextSpan(
                    text: 'I agree to the '.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AppColors.colorStroke,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Terms of service'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.colorYellow,
                        ),
                      ),
                      TextSpan(
                        text: ' and'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: AppColors.colorStroke,
                        ),
                      ),
                      TextSpan(
                        text: ' Privacy Policy'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          color: AppColors.colorYellow,
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            EnhancedAnimatedWrapper(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 500),
              direction: AnimationDirection.top,
              curve: Curves.elasticOut,
              child:Obx(()=> GradientButton(
                isLoading: controller.isLoading.value,
                text: 'Sign up'.tr.toUpperCase(),
                onTap: () async {
                  final name = controller.nameController.text.trim();
                  final email = controller.emailController.text.trim();
                  final password = controller.passwordController.text;
                  final confirmPassword = controller.confirmPasswordController.text;
                  final phone = controller.phoneController.text;
                  final role = controller.selectedRole.value;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter your name".tr)),
                    );
                    return;
                  }

                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter your email".tr)),
                    );
                    return;
                  }
                  if (!emailRegex.hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a valid email address".tr)),
                    );
                    return;
                  }

                  if (password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a password".tr)),
                    );
                    return;
                  }
                  if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Password must be at least 6 characters".tr)),
                    );
                    return;
                  }

                  if (password != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Passwords do not match".tr)),
                    );
                    return;
                  }

                  await controller.signUpUser(
                    context: context,
                    name: name,
                    email: email,
                    phone: phone,
                    password: password,
                    role: role,
                  );
                },
              )),
            ),


            SizedBox(height: size.height * 0.025),
            Container(
              height: 1.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: AppColors.colorSubheading.withOpacity(0.80),
              ),
            ),
            SizedBox(height: size.height * 0.025),
            AnimatedAppText(
              "or continue with".tr,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.colorSubheading,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            EnhancedAnimatedWrapper(
              duration: const Duration(milliseconds: 800),
              delay:const Duration(milliseconds: 500),
              direction: AnimationDirection.top, // ✅ works now
              curve: Curves.elasticOut,
              child: GoogleOrAppcle(text: "Continue with Google".tr, onTap: (){

              },icon: AppIcons.google,),),
            SizedBox(height: size.height * 0.025),
            EnhancedAnimatedWrapper(
              duration: Duration(milliseconds: 800),
              delay: Duration(milliseconds: 500),
              direction: AnimationDirection.top, // ✅ works now
              curve: Curves.elasticOut,
              child: GoogleOrAppcle(text: "Continue with Apple".tr, onTap: (){

              },icon: AppIcons.apple,),),
            SizedBox(height: size.height * 0.012),
            const EnhancedAnimatedWrapper(
              duration: Duration(milliseconds: 800),
              delay: Duration(milliseconds: 500),
              direction: AnimationDirection.top, // ✅ works now
              curve: Curves.elasticOut,
              child: SignUpSection(),),
            SizedBox(height: size.height * 0.026),

        ],
        ),
      ),
      ),
    );
  }

}





