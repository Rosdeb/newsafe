import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/views/screen/help_giver/help_giver_home/giverHome.dart';
import 'package:saferader/views/screen/help_seaker/history/seaker_history.dart';
import 'package:saferader/views/screen/help_seaker/home/seaker_home.dart';
import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
import 'package:saferader/views/screen/help_seaker/notifications/seaker_notifications.dart';
import 'package:saferader/views/screen/help_seaker/setting/seaker_setting.dart';
import '../../../controller/UserController/userController.dart';
import '../../../controller/bottom_nav/bottomNavController.dart';
import '../bothHome/bothHome.dart';
import 'bottom_navigations.dart';

class BottomMenuWrappers extends StatelessWidget {
  BottomMenuWrappers({super.key});

  final BottomNavController controller = Get.put(BottomNavController(),permanent: true);
  final userController = Get.find<UserController>();

  Widget dynamicHomePage(String role) {
    if (role == "seeker") {
      return SeakerHome();
    } else if (role == "giver") {
      return Giverhome();
    }else {
      return SeakerHome(); // fallback
    }
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String role = userController.userRole.value;

      // Build pages role-wise
      final List<Widget> pages = [
        dynamicHomePage(role),   // <-- dynamic home
        SeakerLocation(),
        SeakerNotifications(),
        SeakerHistory(),
        SeakerSetting(),
      ];

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: IndexedStack(
            index: controller.selectedIndex.value,
            children: pages,
          ),
        ),
        extendBody: true,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color(0xFFFFF1A9),
                Color(0xFFFFFFFF),
                Color(0xFFFFF1A9),
              ],
              stops: [0.0046, 0.5005, 0.9964],
            ),
          ),
          child: Obx(()=>IosStyleBottomNavigations(
            onTap: controller.selectTab,
            currentIndex: controller.selectedIndex.value,
          )),
        ),
      );
    });
  }
}
