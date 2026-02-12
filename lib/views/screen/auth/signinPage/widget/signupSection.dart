import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';
import '../../signUpPage/sign_up_screen.dart';


class SignUpSection extends StatelessWidget {
  const SignUpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppText(
            "Don't have an account? ".tr,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.colorSubheading,
          ),
          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (builder)=>SignUpScreen()));

            },
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Sign up".tr,
                    style: const TextStyle(
                      color: AppColors.colorYellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    height: 1.5,
                    color: AppColors.colorYellow,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
