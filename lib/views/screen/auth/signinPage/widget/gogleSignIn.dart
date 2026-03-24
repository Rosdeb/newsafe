import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';
import '../../../../base/Ios_effect/iosTapEffect.dart';

class GoogleOrAppcle extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final String icon;
  final bool isLoading;

  const GoogleOrAppcle({super.key, required this.text, required this.onTap,required this.icon, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return IosTapEffect(
      onTap: onTap,
      child: Container(
        height: 51,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          border: Border.all(width: 1.3, color: AppColors.colorYellow.withOpacity(0.50)),
        ),
        child: isLoading ? CupertinoActivityIndicator()
        : Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(icon),
              const SizedBox(width: 8),
              AppText(
                text,
                fontSize: 14,
                color: AppColors.colorSubheading, // Normal color
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
