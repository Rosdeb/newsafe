import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
class BackToLogin extends StatelessWidget {
  final VoidCallback onTap;
  const BackToLogin({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IosTapEffect(
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
          children: [
            AppText("Back to Sign In".tr, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.colorYellow),
            Container(height: 0.8,color: AppColors.colorYellow,),
          ],
        ),
      ),
    );
  }
}
