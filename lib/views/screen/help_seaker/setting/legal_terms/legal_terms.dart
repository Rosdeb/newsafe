import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saferader/views/screen/help_seaker/setting/base/headers.dart';
import '../base/terms_box.dart';

class LegalTerms extends StatelessWidget {
  const LegalTerms({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Transparent to blend with gradient
        statusBarIconBrightness: Brightness.dark, // Dark icons for light bg
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFFFFF1A9), Color(0xFFFFFFFF), Color(0xFFFFF1A9)],
              stops: [0.0046, 0.5005, 0.9964],
            ),
          ),
          child: Column(
              children: [
                SizedBox(height: size.height * 0.07),
                Headers(
                  iconPath: "assets/icon/Vector.svg",
                  title: "Legal Terms",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Expanded(child: TermsBox()),
              ],
          ),
        ),
      ),
    );
  }
}
