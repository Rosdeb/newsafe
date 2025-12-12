import 'package:flutter/material.dart';

import '../../../utils/app_color.dart';

class AppText extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? height;
  final TextDecoration? decoration;
  final TextStyle? style; // If you want to override everything

  const AppText(
      this.text, {
        super.key,
        this.color,
        this.fontSize,
        this.fontWeight,
        this.fontStyle,
        this.textAlign,
        this.overflow,
        this.maxLines,
        this.decoration,
        this.style,
        this.height,

      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow,
      style: style ??
          TextStyle(
            height: height,
            letterSpacing: 0,
            fontSize: fontSize ?? 20,
           fontFamily: "Roboto",
            fontWeight: fontWeight ?? FontWeight.w500,
            fontStyle: fontStyle ?? FontStyle.normal,
            decoration: decoration ?? TextDecoration.none,
            color: color ?? AppColors.adminBackground1,
          ),
    );
  }
}
