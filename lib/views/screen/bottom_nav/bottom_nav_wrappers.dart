import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/views/screen/help_giver/help_giver_home/giverHome.dart';
import 'package:saferader/views/screen/help_seaker/history/seaker_history.dart';
import 'package:saferader/views/screen/help_seaker/home/seaker_home.dart';
import 'package:saferader/views/screen/help_seaker/locations/seaker_location.dart';
import 'package:saferader/views/screen/help_seaker/notifications/seaker_notifications.dart';
import 'package:saferader/views/screen/help_seaker/setting/seaker_setting.dart';
import '../../../controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
import '../../../controller/SeakerHome/seakerHomeController.dart';
import '../../../controller/UserController/userController.dart';
import '../../../controller/bottom_nav/bottomNavController.dart';
import '../bothHome/bothHome.dart';
import 'bottom_navigations.dart';

class BottomMenuWrappers extends StatefulWidget {  // ✅ StatefulWidget
  const BottomMenuWrappers({super.key});

  @override
  State<BottomMenuWrappers> createState() => _BottomMenuWrappersState();
}

class _BottomMenuWrappersState extends State<BottomMenuWrappers>
    with WidgetsBindingObserver {  // ✅ Observer mixin

  late final BottomNavController controller;
  late final UserController userController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(BottomNavController(), permanent: true);
    userController = Get.find<UserController>();
    WidgetsBinding.instance.addObserver(this);  // ✅ Register
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // ✅ Remove
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
    final role = userController.userRole.value;

    // Role অনুযায়ী controller find করে reconnect করো
    if (role == 'giver') {
      _resumeGiver();
    } else if (role == 'seeker') {
      _resumeSeeker();
    } else if (role == 'both') {
      // BothHome এ নিজের lifecycle আছে
    }
  }

  void _resumeGiver() {
    try {
      if (Get.isRegistered<GiverHomeController>()) {
        final giverController = Get.find<GiverHomeController>();
        if (giverController.socketService == null ||
            !giverController.socketService!.isConnected.value) {
          giverController.initSocket();
        }
      }
    } catch (e) {
      debugPrint('Error resuming giver: $e');
    }
  }

  void _resumeSeeker() {
    try {
      if (Get.isRegistered<SeakerHomeController>()) {
        final seekerController = Get.find<SeakerHomeController>();
        seekerController.refreshSocketOnResume();
      }
    } catch (e) {
      debugPrint('Error resuming seeker: $e');
    }
  }

  void _onAppPaused() {
    debugPrint('🌙 [BottomWrapper] App paused');
  }

  Widget dynamicHomePage(String role) {
    if (role == "seeker") {
      return SeakerHome();
    } else if (role == "giver") {
      return Giverhome();
    } else if (role == "both") {
      return Bothhome();
    } else {
      return SeakerHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String role = userController.userRole.value;

      final List<Widget> pages = [
        dynamicHomePage(role),
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