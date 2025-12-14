import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saferader/utils/logger.dart';
import '../../Models/notification.dart';
import '../../Service/Firebase/notifications.dart';
import '../../utils/api_service.dart';
import '../networkService/networkService.dart';

class NotificationsController extends GetxController {
  final RxBool isNotificationsEnabled = true.obs;
  final RxBool isSoundEnabled = true.obs;
  final RxBool isVibrationEnabled = true.obs;
  final RxBool isLoading = true.obs;
  var currentNow = DateTime.now().obs;
  Timer? _timerUpdater;
  final RxList<NotificationItemModel> notifications = <NotificationItemModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPreferences();
    fetchNotifications();
    startRealTimeUpdater();
  }


  Future<void> loadPreferences() async {
    try {
      isLoading.value = true;

      isNotificationsEnabled.value =
      await NotificationService.getNotificationPreference();
      isSoundEnabled.value = await NotificationService.getSoundPreference();
      isVibrationEnabled.value = await NotificationService.getVibrationPreference();
    }on Exception catch (e) {
      Logger.log('Error loading preferences: $e', type: 'error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleNotifications(bool value) async {
    try {
      await NotificationService.toggleNotifications(value);
      isNotificationsEnabled.value = value;
    }on Exception catch (e) {
      Logger.log('Error toggling notifications: $e', type: 'error');
    }
  }

  Future<void> toggleSound(bool value) async {
    try {
      await NotificationService.toggleSound(value);
      isSoundEnabled.value = value;
    }on Exception catch (e) {
      Logger.log('Error toggling sound: $e', type: 'error');
    }
  }

  Future<void> toggleVibration(bool value) async {
    try {
      await NotificationService.toggleVibration(value);
      isVibrationEnabled.value = value;
    }on Exception catch (e) {
      Logger.log('Error toggling vibration: $e', type: 'error');
    }
  }

  Future<void> fetchNotifications({BuildContext? context}) async {
    final networkController = Get.find<NetworkController>();
    if (!networkController.isOnline.value) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection')),
        );
      }
      return;
    }

    isLoading.value = true;

    try {
      final response = await ApiService.get('/api/notifications');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List? ?? [];

        notifications.value =
            list.map((e) => NotificationItemModel.fromJson(e)).toList();

        Logger.log("Fetched ${notifications.length} notifications", type: "info");
      } else {
        Logger.log("Failed to fetch notifications: ${response.body}", type: "error");
      }
    }on Exception catch (e, st) {
      Logger.log("Unexpected error fetching notifications: $e\n$st", type: "error");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.put('/api/notifications/$notificationId/mark-read');

      if (response.statusCode == 200) {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index].isRead = true;
          notifications.refresh();
        }
        Logger.log("mark as read done ");

      } else {
        Logger.log('Failed to mark notification as read: ${response.body}', type: 'error');
      }
    }on Exception catch (e) {
      Logger.log('Error marking notification as read: $e', type: 'error');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await ApiService.put('/api/notifications/mark-all-read');

      if (response.statusCode == 200) {
        for (var notification in notifications) {
          notification.isRead = true;
        }
        notifications.refresh();
      } else {
        Logger.log('Failed to mark all notifications as read: ${response.body}', type: 'error');
      }
    }on Exception catch (e) {
      Logger.log('Error marking all notifications as read: $e', type: 'error');
    }
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
  }

  void clearAllNotifications() {
    notifications.clear();
  }

  void startRealTimeUpdater() {
    _timerUpdater = Timer.periodic(const Duration(minutes: 1), (timer) {
      currentNow.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _timerUpdater?.cancel();
    super.onClose();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}
