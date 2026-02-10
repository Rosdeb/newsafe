import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../controller/signup/signupController.dart';
import '../../../../../utils/app_color.dart';
import '../../../../../utils/app_icon.dart';
import '../../../../base/AppText/appText.dart';
import '../../../../base/Ios_effect/iosTapEffect.dart';

class SimpleAnimatedContainersListsss extends StatelessWidget {
  SimpleAnimatedContainersListsss({Key? key}) : super(key: key);

  final SignUpController controller = Get.put(SignUpController());

  final List<Map<String, dynamic>> items = [
    {
      "icon": AppIcons.alart,
      "title": "Help Seeker",
      "subtitle": "Get instant help when you need it most",
      "role":"seeker"
    },
    {
      "icon": AppIcons.flat_handshake,
      "title": "Help Giver",
      "subtitle": "Connect with helpers in your area",
      "role":"giver"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: List.generate(items.length, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            final item = items[index];
            return Obx(() {
              final selectedIndex = controller.selectedIndex.value == index;
              return IosTapEffect(
                onTap: (){
                  controller.tapSelected(index);
                  controller.selectedRole.value = item['role'];
                  print("${item['role']}");
                },
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -100), // Slide from top
                  child: Opacity(
                    opacity: value,
                    child: Column(
                      children: [
                        Container(
                          height: 74,
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.035,
                            vertical: size.width * 0.010,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color:selectedIndex ? AppColors.colorYellow.withOpacity(0.50) : AppColors.colorYellow,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: selectedIndex ? Color(0xFFFDE047).withOpacity(0.25) : Color(0xFFFDE047).withOpacity(0.10) ,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  gradient:const LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Color(0xffffe4a7),
                                      Color(0xfffbd96f),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Builder(
                                    builder: (_) {
                                      final String path = item['icon'];
                                      if (path.endsWith(".svg")) {
                                        return SvgPicture.asset(
                                          path,
                                          width: 24,
                                          height: 24,
                                        );
                                      } else {
                                        return Image.asset(
                                          path,
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.contain,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: size.width * 0.016),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    item["title"],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.colorWhite,
                                  ),
                                  AppText(
                                    item["subtitle"],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (index < 2) const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        );
      }),
    );
  }
}

