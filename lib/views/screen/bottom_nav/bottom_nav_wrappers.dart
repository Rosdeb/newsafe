import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';
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

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE STATE TRACKING
  // ─────────────────────────────────────────────────────────────
  AppLifecycleState? _lastLifecycleState;
  DateTime? _backgroundTime;
  bool _isReturningFromBackground = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(BottomNavController(), permanent: true);
    userController = Get.find<UserController>();
    WidgetsBinding.instance.addObserver(this);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP LIFECYCLE HANDLING
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    Logger.log("📱 [LIFECYCLE] BottomMenuWrappers: ${_lastLifecycleState} → $state", type: "info");

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;

      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;

      case AppLifecycleState.paused:
        _handleAppPaused();
        break;

      case AppLifecycleState.detached:
        _handleAppDetached();
        break;

      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }

    _lastLifecycleState = state;
  }

  void _handleAppResumed() {
    Logger.log("✅ [LIFECYCLE] Bottom wrapper resumed", type: "success");

    if (!mounted) return;

    // Mark returning from background
    if (_backgroundTime != null) {
      _isReturningFromBackground = true;
      final backgroundDuration = DateTime.now().difference(_backgroundTime!);
      Logger.log("⏱️ [LIFECYCLE] Returning from background (${backgroundDuration.inSeconds}s)", type: "info");
    }

    // Refresh socket via UnifiedHelpController
    _refreshSocketConnection();

    // Reset flags
    _backgroundTime = null;

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isReturningFromBackground = false;
      }
    });
  }

  void _handleAppInactive() {
    Logger.log("⏸️ [LIFECYCLE] Bottom wrapper inactive", type: "info");
    // App is temporarily inactive
  }

  void _handleAppPaused() {
    Logger.log("⏸️ [LIFECYCLE] Bottom wrapper paused", type: "warning");

    // Store background time
    _backgroundTime = DateTime.now();

    // Don't stop socket - keep alive for background
  }

  void _handleAppDetached() {
    Logger.log("🛑 [LIFECYCLE] Bottom wrapper detached", type: "error");
    // App is being destroyed
  }

  void _handleAppHidden() {
    Logger.log("👻 [LIFECYCLE] Bottom wrapper hidden", type: "info");
    // iOS specific
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOCKET MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _refreshSocketConnection() async {
    try {
      if (Get.isRegistered<UnifiedHelpController>()) {
        final unifiedCtrl = Get.find<UnifiedHelpController>();

        // Check socket status
        if (unifiedCtrl.socketService == null ||
            !unifiedCtrl.socketService!.isConnected.value) {
          Logger.log("🔄 [SOCKET] Reconnecting socket from bottom wrapper", type: "warning");
          await unifiedCtrl.initSocket();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Rejoin rooms
        _rejoinActiveRooms(unifiedCtrl);

        Logger.log("✅ [SOCKET] Socket refreshed from bottom wrapper", type: "success");
      }
    } catch (e) {
      Logger.log("❌ [SOCKET] Error in bottom wrapper refresh: $e", type: "error");
    }
  }

  void _rejoinActiveRooms(UnifiedHelpController unifiedCtrl) {
    try {
      // Rejoin seeker room
      if (unifiedCtrl.seekerHelpRequestId.value.isNotEmpty) {
        final id = unifiedCtrl.seekerHelpRequestId.value;
        unifiedCtrl.socketService?.joinRoom(id);
        Logger.log("🏠 [SOCKET] Rejoined seeker room: $id", type: "info");
      }

      // Rejoin giver room
      if (unifiedCtrl.acceptedRequest.value != null) {
        final id = unifiedCtrl.acceptedRequest.value!['_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          unifiedCtrl.socketService?.joinRoom(id);
          Logger.log("🏠 [SOCKET] Rejoined giver room: $id", type: "info");
        }
      }
    } catch (e) {
      Logger.log("❌ [SOCKET] Error rejoining rooms: $e", type: "error");
    }
  }

  @override
  void dispose() {
    Logger.log("🗑️ [DISPOSE] BottomMenuWrappers cleaning up", type: "info");

    WidgetsBinding.instance.removeObserver(this);

    Logger.log("✅ [DISPOSE] BottomMenuWrappers cleanup completed", type: "success");
    super.dispose();
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