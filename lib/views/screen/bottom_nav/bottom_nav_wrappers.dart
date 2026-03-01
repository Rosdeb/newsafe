import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/views/screen/help_seaker/history/seaker_history.dart';
import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
import 'package:saferader/views/screen/help_seaker/notifications/seaker_notifications.dart';
import 'package:saferader/views/screen/help_seaker/setting/seaker_setting.dart';
import '../../../controller/UnifiedHelpController.dart';
import '../../../controller/UserController/userController.dart';
import '../../../controller/bottom_nav/bottomNavController.dart';
import '../UnifiedHomePage.dart';
import '../bothHome/bothHome.dart';
import 'bottom_navigations.dart';

class BottomMenuWrappers extends StatefulWidget {
  const BottomMenuWrappers({super.key});

  @override
  State<BottomMenuWrappers> createState() => _BottomMenuWrappersState();
}

class _BottomMenuWrappersState extends State<BottomMenuWrappers>
    with WidgetsBindingObserver {
  late final BottomNavController controller;
  late final UserController userController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(BottomNavController(), permanent: true);
    userController = Get.find<UserController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      _onAppPaused();
    }
  }

  void _onAppResumed() {
    try {
      if (Get.isRegistered<UnifiedHelpController>()) {
        Get.find<UnifiedHelpController>().onAppResumed();
      }
    } catch (e) {
      debugPrint('[BottomWrapper] onAppResumed error: $e');
    }
  }

  void _onAppPaused() {
    try {
      if (Get.isRegistered<UnifiedHelpController>()) {
        Get.find<UnifiedHelpController>().onAppPaused();
      }
    } catch (e) {
      debugPrint('[BottomWrapper] onAppPaused error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<Widget> pages = [
        UnifiedHomePage(),
        SeakerLocation(),
        SeakerNotifications(),
        SeakerHistory(),
        SeakerSetting(),
      ];

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: Obx(() => IndexedStack(
            index: controller.selectedIndex.value,
            children: pages,
          )),
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
          child: Obx(() => IosStyleBottomNavigations(
            onTap: controller.selectTab,
            currentIndex: controller.selectedIndex.value,
          )),
        ),
      );
    });
  }
}