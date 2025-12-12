import 'package:flutter/material.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
class Gradientbutton1 extends StatelessWidget {
  final String text;
  final VoidCallback ontap;
  const Gradientbutton1({
    super.key,
    required this.text,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return IosTapEffect(
      onTap: ontap,
      child: Container(
        height: 51,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient:LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Color(0xfff7d481), Color(0xffffc91d)], ),
        ),
        child: Center(
          child: AppText(text,fontSize: 16,color: AppColors.color2Box,fontWeight: FontWeight.w600,),
        ),
      ),
    );
  }
}
