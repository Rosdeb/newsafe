import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:saferader/views/screen/auth/fogotPage/forgot_screen.dart';

import '../../../../../controller/signInController/signIn.dart';
import '../../../../../utils/app_color.dart';

class RememberMeSection extends StatelessWidget {
  RememberMeSection({super.key});

  final SigInController controller = Get.put(SigInController());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 35,
              child: Obx(() => CupertinoCheckbox(
                activeColor:AppColors.colorYellow,
                value: controller.rememberMe.value,
                onChanged: (_) {
                  controller.rememberToggle();
                },
              )),
            ),
            Text(
              "Remember me".tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ForgotScreen()),
            );
          },
          child: Text(
            "Forgot Password?".tr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.colorYellow,
            ),
          ),
        ),
      ],
    );
  }
}

