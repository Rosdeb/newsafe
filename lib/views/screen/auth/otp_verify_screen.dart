import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:pinput/pinput.dart';
import 'package:saferader/controller/forgot/forgotController.dart';
import 'package:saferader/views/screen/auth/reset_pass_screen.dart';
import 'package:saferader/views/screen/auth/success_message_screen.dart';

import '../../../utils/app_color.dart';
import '../../base/AppText/appText.dart';
import '../../base/AppTextField/apptextfield.dart';
import '../../base/animationsWrapper/animations_wrapper.dart';
import '../welcome/welcome_sreen.dart';
import 'base/back_to_login.dart';

class SimpleOtpScreen extends StatefulWidget {
  final String email;
  const SimpleOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<SimpleOtpScreen> createState() => _SimpleOtpScreenState();
}

class _SimpleOtpScreenState extends State<SimpleOtpScreen> {
  final ForgotController forgotController = Get.find<ForgotController>();

  final TextEditingController pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final int _length = 5;

  @override
  void dispose() {
    pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onSubmit(String pin) {

    final isValid = pin == '12345';
    final snackMsg = isValid ? 'OTP verified ✅' : 'Invalid OTP ❌';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackMsg)));
  }

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
      ),);

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border.all(color: Colors.green, width: 2), // ✅ after entered
        borderRadius: BorderRadius.circular(8),
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
              const  AnimatedAppText(
                "OTP Verification",
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEDC602),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              const  AppText(
                "Enter the otp sent to your email address to reset your old password",
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
                  forgotController.verifyEmail(context, widget.email, pin);
                },
                onCompleted: (pin) {
                  debugPrint("onCompleted PinCode: $pin");
                  _pinFocusNode.unfocus();
                  forgotController.verifyEmail(context, widget.email, pin);

                },
                onChanged: (value) {
                  debugPrint("Changed: $value");
                },
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                autofillHints:  [AutofillHints.oneTimeCode],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              EnhancedAnimatedWrapper (
                duration:const Duration(milliseconds: 500),
                delay:const Duration(milliseconds: 400),
                direction: AnimationDirection.bottom,
                curve: Curves.elasticOut,
                child:Obx(()=>GradientButton(
                  isLoading: forgotController.isVerify.value,
                  text: "verify otp".toUpperCase().toUpperCase(),
                  onTap: () {

                    forgotController.verifyEmail(context, widget.email, pinController.text.toString());

                  },
                ),)
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              const AnimatedAppText(
                "Resend Otp?",
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEDC602),
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
