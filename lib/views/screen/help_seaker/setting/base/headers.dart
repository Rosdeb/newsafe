import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';

import '../../../../base/Ios_effect/iosTapEffect.dart';

class Headers extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  final Color? iconBgColor;

  const Headers({
    Key? key,
    required this.iconPath,
    required this.title,
    required this.onTap,
    this.margin,
    this.iconBgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return IosTapEffect(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(left: 20),
        height: 50,
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Color(0xFFFDE047).withOpacity(0.20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.colorYellow,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  height: 22,
                  width: 22,
                ),
              ),
            ),
            SizedBox(width: size.height * 0.020),
            AppText(
              title,
              fontWeight: FontWeight.w600,
              color: AppColors.color2Box,
              fontSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
