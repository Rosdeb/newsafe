import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saferader/views/screen/auth/reset_pass_screen.dart';

import '../../../utils/app_color.dart';
import '../../base/AppText/appText.dart';
import '../../base/animationsWrapper/animations_wrapper.dart';
import '../welcome/welcome_sreen.dart';

class SuccessMessageScreen extends StatelessWidget {
  final String title;
  final String details;
  final String buttonText;
  final VoidCallback onTap;

  const SuccessMessageScreen({super.key, required this.title, required this.details, required this.buttonText,required this.onTap});

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
          height: 317,
          width: double.infinity,
          padding:const EdgeInsets.symmetric(horizontal: 24),
          margin:const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.fill_Color2,
            border: Border.all(width: 0.5, color: AppColors.colorYellow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              SvgPicture.asset("assets/icon/Frame.svg"),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              AnimatedAppText(
                title,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color:const Color(0xFFEDC602),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              AppText(
               details,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.colorSubheading,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              EnhancedAnimatedWrapper(
                duration:const Duration(milliseconds: 500),
                delay:const Duration(milliseconds: 400),
                direction: AnimationDirection.bottom,
                curve: Curves.elasticOut,
                child: GradientButton(
                  text: buttonText.toUpperCase(),
                  onTap:onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
