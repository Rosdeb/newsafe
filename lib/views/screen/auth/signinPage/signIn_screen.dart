import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:saferader/controller/signInController/signIn.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/screen/auth/signUpPage/sign_up_screen.dart';
import 'package:saferader/views/screen/auth/signinPage/widget/gogleSignIn.dart';
import 'package:saferader/views/screen/auth/signinPage/widget/rememberMe.dart';
import 'package:saferader/views/screen/auth/signinPage/widget/signupSection.dart';
import '../../../../utils/app_icon.dart';
import '../../../base/AppText/appText.dart';
import '../../../base/AppTextField/apptextfield.dart';
import '../../../base/Ios_effect/iosTapEffect.dart';
import '../../../base/animationsWrapper/animations_wrapper.dart';
import '../../welcome/welcome_sreen.dart';


class SigninScreen extends StatefulWidget {
  SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final SigInController controller = Get.put(SigInController());
  bool _hasLoadedCredentials = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.loadRememberedCredentials();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedCredentials) {
      controller.loadRememberedCredentials();
      _hasLoadedCredentials = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final isTablet = size.width > 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff202020),
        body: SafeArea(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 560.0 : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.01 : 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.060),
                      SvgPicture.asset(
                        AppIcons.miniSafeRadar,
                        width: isTablet ? size.width * 0.18 : null,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      AnimatedAppText(
                        'Welcome Back To'.tr,
                        fontSize: isTablet ? 38 : 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEDC602),
                      ),
                      SizedBox(height: screenHeight * 0.010),

                      AnimatedWidgetWrapper(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: Center(
                          child: SvgPicture.asset(
                            AppIcons.mini_safe_radar,
                            width: isTablet ? size.width * 0.30 : null,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      AnimatedWidgetWrapper(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: AppText(
                            "Email Address".tr,
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 14 : 12,
                            color: AppColors.colorSubheading,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),

                      AnimatedWidgetWrapper(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: AppTextField(
                          keyboardType: TextInputType.emailAddress,
                          controller: controller.emailController,
                          hint: "Enter your email".tr,
                          suffix: const Icon(CupertinoIcons.mail, color: Colors.white38),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      AnimatedWidgetWrapper(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: AppText(
                            "Password".tr,
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 14 : 12,
                            color: AppColors.colorSubheading,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),

                      AnimatedWidgetWrapper(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: Obx(() => AppTextField(
                          obscure: controller.passShowHide.value,
                          keyboardType: TextInputType.twitter,
                          controller: controller.passwordController,
                          hint: "Enter your password".tr,
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
                      ),

                      AnimatedWidgetWrapper(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        direction: AnimationDirection.bottom,
                        child:  RememberMeSection(),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      EnhancedAnimatedWrapper(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        direction: AnimationDirection.top,
                        curve: Curves.elasticOut,
                        child: Obx(() => GradientButton(
                          isLoading: controller.isLoading.value,
                          text: 'Sign in'.tr.toUpperCase(),
                          onTap: () {
                            controller.loginUser(
                              context,
                              controller.emailController.text.toString(),
                              controller.passwordController.text.toString(),
                            );
                          },
                        )),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Container(
                      //   height: 1.5,
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(5),
                      //     color: AppColors.colorSubheading.withOpacity(0.80),
                      //   ),
                      // ),
                      // SizedBox(height: screenHeight * 0.025),
                      //
                      // AnimatedAppText(
                      //   "or continue with".tr,
                      //   fontSize: isTablet ? 16 : 14,
                      //   fontWeight: FontWeight.w700,
                      //   color: AppColors.colorSubheading,
                      // ),
                      // SizedBox(height: screenHeight * 0.025),
                      //
                      // EnhancedAnimatedWrapper(
                      //   duration: const Duration(milliseconds: 800),
                      //   delay: const Duration(milliseconds: 500),
                      //   direction: AnimationDirection.top,
                      //   curve: Curves.elasticOut,
                      //   child: GoogleOrAppcle(
                      //     text: "Continue with Google".tr,
                      //     onTap: () {
                      //
                      //     },
                      //     icon: AppIcons.google,
                      //   ),
                      // ),
                      // SizedBox(height: screenHeight * 0.025),
                      //
                      // EnhancedAnimatedWrapper(
                      //   duration: const Duration(milliseconds: 800),
                      //   delay: const Duration(milliseconds: 500),
                      //   direction: AnimationDirection.top,
                      //   curve: Curves.elasticOut,
                      //   child: Obx(()=>GoogleOrAppcle(
                      //     isLoading: controller.appleLoading.value,
                      //     text: "Continue with Apple".tr,
                      //     onTap: () {
                      //       controller.signInWithApple();
                      //     },
                      //     icon: AppIcons.apple,
                      //   ))
                      // ),
                      // SizedBox(height: screenHeight * 0.012),

                      const EnhancedAnimatedWrapper(
                        duration: Duration(milliseconds: 800),
                        delay: Duration(milliseconds: 500),
                        direction: AnimationDirection.top,
                        curve: Curves.elasticOut,
                        child: SignUpSection(),
                      ),

                      SizedBox(height: isTablet ? 32 : 16),
                    ],
                  ),
                ),
              ),
            ),
        ),
      ),
    );
  }
}