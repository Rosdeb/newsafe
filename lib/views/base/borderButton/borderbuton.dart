import 'package:flutter/material.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';

class Borderbuton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const Borderbuton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IosTapEffect(
      onTap: onTap,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xffffb200), Color(0xffffc200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Container(
          height: 51,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            border: Border.all(width: 1, color: AppColors.colorYellow),
          ),
          child: Center(
            child: AppText(
              text,
              fontSize: 16,
              color: AppColors.colorYellow,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
