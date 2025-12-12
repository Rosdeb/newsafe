import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';

class EmptyHistoryBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final double height;

  const EmptyHistoryBox({
    super.key,
    this.title = "No activity yet",
    this.subtitle = "Your emergency history will appear here",
    this.iconPath = "assets/icon/Group.svg",
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(width: 1.2, color: AppColors.colorYellow),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          SvgPicture.asset(iconPath),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          AppText(
            subtitle,
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: AppColors.color2Box,
          ),
        ],
      ),
    );
  }
}
