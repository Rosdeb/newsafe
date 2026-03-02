import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:saferader/utils/logger.dart';

import '../../controller/SeakerLocation/seakerLocationsController.dart';
import '../../controller/UnifiedHelpController.dart';

class BackgroundService {
  static Future<void> start() async {
    if (!Get.isRegistered<UnifiedHelpController>()) return;

    final locCtrl = Get.find<SeakerLocationsController>();

    if (locCtrl.isSharingLocation.value) {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Location Sharing Active',
        notificationText: 'Help request in progress',
        notificationIcon: const NotificationIcon(
          metaDataName: 'notification_icon',
        ),
      );

      FlutterForegroundTask.setTaskHandler(_BackgroundTaskHandler());
    }
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

class _BackgroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    Logger.log('[BG] Background service started', type: 'info');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (Get.isRegistered<UnifiedHelpController>()) {
      final ctrl = Get.find<UnifiedHelpController>();
      if (ctrl.socketService?.isConnected.value != true) {
        Logger.log(
          '🔁 [BG] Socket disconnected — reconnecting',
          type: 'warning',
        );
        await ctrl.initSocket();
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    Logger.log(
      '🔋 [BG] Background service stopped (timeout=$isTimeout)',
      type: 'info',
    );
  }
}