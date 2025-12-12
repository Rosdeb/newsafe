import 'package:flutter/material.dart';
import 'package:saferader/utils/app_color.dart';
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final Widget? suffix;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onSubmitted;
  final Color? fillColor;
  final Color? textColor;

  const AppTextField({
    super.key,
    this.autocorrect = false,
    this.enableSuggestions = false,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.fillColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: autocorrect ?? false,
      enableSuggestions: enableSuggestions ?? false,
      keyboardType: keyboardType,
      cursorColor: AppColors.colorYellow,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontWeight: FontWeight.w400,
        color: textColor ?? AppColors.colorSecond,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        hintStyle:const  TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.colorSubheading,
          fontSize: 14,
        ),
        filled: true,
        fillColor: fillColor ?? const Color(0xFF383838),
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            width: 1,
            color: AppColors.colorIcons.withOpacity(0.50)
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:  BorderSide(width: 1.5, color: AppColors.colorYellow),
        ),
      ),
    );
  }
}