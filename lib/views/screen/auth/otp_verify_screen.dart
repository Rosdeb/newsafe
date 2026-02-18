import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pinput/pinput.dart';
import 'package:saferader/controller/forgot/forgotController.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import 'package:saferader/views/screen/auth/reset_pass_screen.dart';
import 'package:saferader/views/screen/auth/success_message_screen.dart';

import '../../../utils/app_color.dart';
import '../../base/AppText/appText.dart';
import '../../base/AppTextField/apptextfield.dart';
import '../../base/animationsWrapper/animations_wrapper.dart';
import '../welcome/welcome_sreen.dart';
import 'base/back_to_login.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:saferader/controller/forgot/forgotController.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import '../../../utils/app_color.dart';
import '../../base/AppText/appText.dart';
import '../../base/AppTextField/apptextfield.dart';
import '../../base/animationsWrapper/animations_wrapper.dart';
import 'base/back_to_login.dart';
import 'dart:async';

class SimpleOtpScreen extends StatefulWidget {
  final bool isSignUp;
  final String email;

  const SimpleOtpScreen({
    Key? key,
    required this.email,
    this.isSignUp = true
  }) : super(key: key);

  @override
  State<SimpleOtpScreen> createState() => _SimpleOtpScreenState();
}

class _SimpleOtpScreenState extends State<SimpleOtpScreen> {
  final ForgotController forgotController = Get.put(ForgotController());
  final TextEditingController pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final int _length = 5;


  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    pinController.dispose();
    _pinFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 120;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    if (!_canResend) return;

    // Call resend OTP API
    if (widget.isSignUp) {
      forgotController.resendSignupOtp(context, widget.email);
    } else {
      forgotController.resendForgotOtp(context, widget.email);
    }

    // Restart timer
    _startTimer();

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP resent successfully'.tr),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xff202020),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        border: Border.all(color: Colors.yellow, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xff202020),
      body: Center(
        child: Container(
          height: 420,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
                "OTP Verification".tr,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEDC602),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              AppText(
                widget.isSignUp
                    ? "Enter the OTP sent to your email to verify your account".tr
                    : "Enter the OTP sent to your email to reset your password".tr,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.colorSubheading,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              Pinput(
                length: _length,
                controller: pinController,
                focusedPinTheme: focusedPinTheme,
                disabledPinTheme: defaultPinTheme,
                focusNode: _pinFocusNode,
                defaultPinTheme: defaultPinTheme,
                submittedPinTheme: submittedPinTheme,
                onSubmitted: (pin) {
                  debugPrint("onSubmitted PinCode: $pin");
                  _pinFocusNode.unfocus();
                  _verifyOtp(pin);
                },
                onCompleted: (pin) {
                  debugPrint("onCompleted PinCode: $pin");
                  _pinFocusNode.unfocus();
                  _verifyOtp(pin);
                },
                onChanged: (value) {
                  debugPrint("Changed: $value");
                },
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                autofillHints: const [AutofillHints.oneTimeCode],
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.025),

              EnhancedAnimatedWrapper(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 400),
                direction: AnimationDirection.bottom,
                curve: Curves.elasticOut,
                child: Obx(
                      () => GradientButton(
                    isLoading: forgotController.isVerify.value,
                    text: "Verify OTP".tr.toUpperCase(),
                    onTap: () {
                      if (pinController.text.length == _length) {
                        _verifyOtp(pinController.text.toString());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter complete OTP'.tr),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Resend OTP Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend)
                    AppText(
                      "Resend OTP in".tr + " ${_formatTime(_remainingSeconds)}",
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colorSubheading,
                    )
                  else
                    IosTapEffect(
                      onTap: _resendOtp,
                      child: Row(
                        children: [
                          AnimatedAppText(
                            "Didn't receive code?".tr,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.colorSubheading,
                          ),
                          AnimatedAppText(
                            "Resend OTP".tr,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEDC602),
                          ),
                        ],
                      ),
                    ),
                ],
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

  void _verifyOtp(String pin) {
    if (widget.isSignUp) {
      forgotController.singupEmail(
        context,
        widget.email,
        pin,
      );
    } else {
      forgotController.verifyEmail(
        context,
        widget.email,
        pin,
      );
    }
  }
}
