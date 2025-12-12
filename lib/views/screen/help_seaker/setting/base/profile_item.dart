import 'package:flutter/material.dart';

import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';

class ProfileInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final double? height;
  final double? borderRadius;

  const ProfileInfoBox({
    super.key,
    required this.title,
    required this.value,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (backgroundColor ?? AppColors.iconBg).withOpacity(0.20),
        borderRadius: BorderRadius.circular(borderRadius ?? 10),
        border: Border.all(
          width: 1.2,
          color: borderColor ?? AppColors.colorYellow,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            title,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textColor ?? AppColors.color2Box,
          ),
          AppText(
            value,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor ?? AppColors.color2Box,
          ),
        ],
      ),
    );
  }
}