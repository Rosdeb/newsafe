import 'package:flutter/material.dart';

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
          const AppText(
            "Don't have an account? ",
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
                  const Text(
                    "Sign up",
                    style: TextStyle(
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
