import 'dart:async';

import 'package:get/get.dart';
import '../../Service/Firebase/notifications.dart';

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
    loadNotifications();
    startRealTimeUpdater();
  }


  Future<void> loadPreferences() async {
    try {
      isLoading.value = true;

      final notifEnabled = await NotificationService.getNotificationPreference();
      final soundEnabled = await NotificationService.getSoundPreference();
      final vibrationEnabled = await NotificationService.getVibrationPreference();

      isNotificationsEnabled.value = notifEnabled;
      isSoundEnabled.value = soundEnabled;
      isVibrationEnabled.value = vibrationEnabled;
    }on Exception catch (e) {
      print('Error loading preferences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleNotifications(bool value) async {
    try {
      await NotificationService.toggleNotifications(value);
      isNotificationsEnabled.value = value;
    }on Exception catch (e) {
      print('Error toggling notifications: $e');
    }
  }

  Future<void> toggleSound(bool value) async {
    try {
      await NotificationService.toggleSound(value);
      isSoundEnabled.value = value;
    }on Exception catch (e) {
      print('Error toggling sound: $e');
    }
  }

  Future<void> toggleVibration(bool value) async {
    try {
      await NotificationService.toggleVibration(value);
      isVibrationEnabled.value = value;
    }on Exception catch (e) {
      print('Error toggling vibration: $e');
    }
  }

  Future<void> loadNotifications() async {
    notifications.value = [
      NotificationItemModel(
        id: '1',
        title: 'Help Request Accepted',
        body: 'John Doe is on the way to help you',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        type: 'help_accepted',
        distance: '1.5',
        userImage: '',
      ),
      NotificationItemModel(
        id: '2',
        title: 'Help Request Declined',
        body: 'Jane Smith declined your request',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        type: 'help_declined',
        distance: '2.3',
        userImage: '',
      ),
    ];
  }


  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
    notifications.refresh();
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
  }

  void clearAllNotifications() {
    notifications.clear();
  }

  void startRealTimeUpdater(){
    _timerUpdater = Timer.periodic(const Duration(minutes: 1),(timer){
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


class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final String? type;
  final String? distance;
  final String? userImage;
  final String? userName;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type,
    this.distance,
    this.userImage,
    this.userName,
  });
}