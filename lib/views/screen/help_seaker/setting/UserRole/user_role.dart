import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:saferader/controller/UserRole/userRole.dart';
import '../../../../../utils/app_color.dart';
import '../../../../base/AppText/appText.dart';
import '../base/headers.dart';

class UserRole extends StatelessWidget {
  UserRole({super.key});
 final UserRoleController controller = Get.put(UserRoleController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
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
                title: "User Role",
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: size.height * 0.03),
              Container(
                padding:const  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                margin:const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.iconBg.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(width: 2, color: AppColors.colorYellow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      "Select your role",
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.color2Box,
                    ),
                    SizedBox(height: size.height * 0.01),
                    LabeledSwitch(
                      title: "Help Giver",
                      value: controller.helpGiver,
                      onChanged:null,
                    ),
                    LabeledSwitch(
                      title: "Help Seeker",
                      value: controller.helpSeeker,
                      onChanged:null,
                    ),
                    LabeledSwitch(
                      title: "Both",
                      value: controller.both,
                      onChanged:null,
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class LabeledSwitch extends StatelessWidget {
  final String title;
  final RxBool value;
  final Function(bool)? onChanged;
  final double scale;

  const LabeledSwitch({
    super.key,
    required this.title,
    required this.value,
    this.onChanged,
    this.scale = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          fontSize: 14,
          fontWeight: FontWeight.w200,
          color: AppColors.color2Box,
        ),

        Obx(
              () => Transform.scale(
            scale: scale,
            child: CupertinoSwitch(
              value: value.value,
              onChanged: onChanged == null ? (_) {} : (v) {
                value.value = v;
                onChanged!(v);
              },
              activeColor:AppColors.colorYellow,  // ON track color
              trackColor: Colors.grey.shade300,     // OFF track color
              thumbColor: Colors.white,
              inactiveThumbColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
