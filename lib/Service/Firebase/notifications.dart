
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:saferader/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../controller/UnifiedHelpController.dart';
import '../../utils/app_constant.dart';
import '../../views/screen/bottom_nav/bottom_nav_wrappers.dart';
import '../../views/screen/help_seaker/notifications/seaker_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler (top-level, required by Firebase)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [BACKGROUND] Message received: ${message.messageId}');
  debugPrint('🔔 [BACKGROUND] Message data: ${message.data}');

  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool(NotificationService.prefNotificationsEnabled) ?? true;
  if (!isEnabled) {
    debugPrint('🔕 [BACKGROUND] Notifications disabled');
    return;
  }

  // Check for new_help_request type
  final type = message.data['type']?.toString();
  if (type == 'new_help_request') {
    debugPrint('🆘 [BACKGROUND] New help request detected in background!');
    // Store for later processing when app opens
    final pendingKey = 'pending_help_request';
    await prefs.setString(pendingKey, jsonEncode(message.data));
  }

  final notification = message.notification;
  if (notification != null) {
    debugPrint('📬 [BACKGROUND] Showing local notification: ${notification.title}');
    await NotificationService.showLocalNotification(
      title: notification.title ?? 'Notification',
      body: notification.body ?? '',
      payload: jsonEncode(message.data),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  static const String _channelId = 'app_notifications';
  static const String _channelName = 'App Notifications';
  static const String _channelDescription = 'General notifications';

  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String _prefSoundEnabled = 'sound_enabled';
  static const String _prefVibrationEnabled = 'vibration_enabled';

  static const MethodChannel _fcmTokenChannel = MethodChannel('fcm_token_channel');
  static const MethodChannel _notificationChannel = MethodChannel('notification_channel');

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static bool _isNotificationsEnabled = true;
  static bool _isSoundEnabled = true;
  static bool _isVibrationEnabled = true;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ── Pending notification data (arrived before controller was ready) ──────
  static Map<String, dynamic>? _pendingHelpRequestData;

  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    await _loadNotificationPreferences();
    await _initializeFirebase();
    await _initializeLocalNotifications();
    await _setupFirebaseListeners();
    _setupNativeChannelListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NATIVE CHANNEL
  // ─────────────────────────────────────────────────────────────────────────
  static void _setupNativeChannelListeners() {
    _fcmTokenChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onToken') {
        final args = call.arguments as Map?;
        final token = args?['token'] as String?;
        if (token != null) {
          debugPrint('✅ FCM Token from native: $token');
          await PrefsHelper.setString(AppConstants.fcmToken, token);
          await _firebaseMessaging.subscribeToTopic('signedInUsers');
        }
      }
    });

    _notificationChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onNotificationTap') {
        final data = call.arguments as Map<dynamic, dynamic>?;
        debugPrint('📬 Notification tap from native: $data');
        _navigateFromNotification(
          data?.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    });

    debugPrint('✅ Native channel listeners registered');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FCM TOKEN
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> getFcmToken() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true,
        criticalAlert: true, provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await PrefsHelper.setString(AppConstants.fcmToken, token);
        debugPrint('✅ FCM Token: $token');
        await _firebaseMessaging.subscribeToTopic('signedInUsers');
      }
    } catch (e) {
      debugPrint('❌ getFcmToken error: $e');
    }
  }

  static Future<String?> waitForFcmToken({Duration? maxWait}) async {
    final duration = maxWait ?? const Duration(seconds: 5);
    final start = DateTime.now();
    while (DateTime.now().difference(start) < duration) {
      final token = await PrefsHelper.getString(AppConstants.fcmToken);
      if (token != null) return token;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PREFERENCES
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isNotificationsEnabled = prefs.getBool(prefNotificationsEnabled) ?? true;
    _isSoundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
    _isVibrationEnabled = prefs.getBool(_prefVibrationEnabled) ?? true;
  }

  static Future<void> toggleNotifications(bool isEnabled) async {
    if (!isEnabled) await _localNotifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefNotificationsEnabled, isEnabled);
    _isNotificationsEnabled = isEnabled;
  }

  static Future<void> toggleSound(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, isEnabled);
    _isSoundEnabled = isEnabled;
  }

  static Future<void> toggleVibration(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVibrationEnabled, isEnabled);
    _isVibrationEnabled = isEnabled;
  }

  static Future<bool> getNotificationPreference() async {
    await _loadNotificationPreferences();
    return _isNotificationsEnabled;
  }

  static Future<bool> getSoundPreference() async {
    await _loadNotificationPreferences();
    return _isSoundEnabled;
  }

  static Future<bool> getVibrationPreference() async {
    await _loadNotificationPreferences();
    return _isVibrationEnabled;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIREBASE INIT
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _initializeFirebase() async {
    try {
      await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

      final saved = await PrefsHelper.getString(AppConstants.fcmToken);
      if (saved == null) await getFcmToken();

      _firebaseMessaging.onTokenRefresh.listen((token) async {
        await PrefsHelper.setString(AppConstants.fcmToken, token);
      });
    } catch (e) {
      debugPrint(' Firebase init error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOCAL NOTIFICATIONS INIT
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _localNotifications.initialize(
        settings: InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleLocalTap,
    );

    // Create high-priority channel for help requests
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ));

    debugPrint('✅ Android notification channel created with max importance');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIREBASE LISTENERS
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _setupFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('📬 Foreground message: ${msg.messageId}');
      debugPrint('📬 Message data: ${msg.data}');

      if (!_isNotificationsEnabled) return;

      final type = msg.data['type']?.toString();
      debugPrint('📬 Notification type: $type');

      // Handle new_help_request immediately
      if (type == 'new_help_request') {
        debugPrint('🆘 New help request detected!');
        _injectHelpRequest(msg.data);
      }

      final n = msg.notification;
      if (n != null) {
        // Store full message data as JSON payload
        final payload = jsonEncode(msg.data);
        debugPrint('📝 Showing notification with payload: $payload');
        showLocalNotification(
          title: n.title ?? 'Notification',
          body: n.body ?? '',
          payload: payload,
        );
      } else {
        // Data-only message (no notification payload)
        debugPrint('📝 Data-only message received');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('📬 App opened from background notification');
      debugPrint('📬 Message data: ${msg.data}');
      _navigateFromNotification(msg.data);
    });

    final initial = await _firebaseMessaging.getInitialMessage();
    if (initial != null) {
      debugPrint('📬 App launched from terminated state');
      debugPrint('📬 Initial message data: ${initial.data}');
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateFromNotification(initial.data);
      });
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION ROUTING
  // ─────────────────────────────────────────────────────────────────────────
  static void _navigateFromNotification(Map<String, dynamic>? data) {
    debugPrint('🧭 [NAVIGATE] Called with data: $data');

    final type = data?['type']?.toString();
    debugPrint('🧭 [NAVIGATE] Notification type: $type');

    if (type == 'new_help_request') {
      debugPrint('🧭 [NAVIGATE] Help request notification detected');

      // Store data for processing
      _pendingHelpRequestData = data;

      // Check if controller is ready
      if (Get.isRegistered<UnifiedHelpController>()) {
        debugPrint('🧭 [NAVIGATE] Controller registered, injecting request');
        _injectHelpRequest(data!);

        // Navigate to home
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          debugPrint('🧭 [NAVIGATE] Navigating with context');
          Get.offAll(() => BottomMenuWrappers());
        } else {
          debugPrint('🧭 [NAVIGATE] No context, using Get directly');
          Get.offAll(() => BottomMenuWrappers());
        }
      } else {
        debugPrint('⚠️ [NAVIGATE] Controller not registered, will process later');
        // Controller not ready, will be processed when app fully loads
        // Check if we should navigate anyway
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          debugPrint('🧭 [NAVIGATE] Navigating to home, will process when ready');
          Get.offAll(() => BottomMenuWrappers());
        }
      }
    } else {
      // Regular notification - navigate to notifications page
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        debugPrint('🧭 [NAVIGATE] Navigating to notifications page');
        Navigator.push(context, MaterialPageRoute(builder: (_) => SeakerNotifications()));
      } else {
        debugPrint('⚠️ [NAVIGATE] No context available for navigation');
      }
    }
  }

  // ── Changed: uses UnifiedHelpController ──────────────────────────────────
  static void _injectHelpRequest(Map<String, dynamic> data) {
    try {
      if (!Get.isRegistered<UnifiedHelpController>()) {
        debugPrint('UnifiedHelpController not registered yet — storing pending');
        _pendingHelpRequestData = data;
        return;
      }
      Get.find<UnifiedHelpController>().injectHelpRequestFromNotification(data);
    } catch (e) {
      debugPrint('injectHelpRequest error: $e');
    }
  }

  /// Call this after UnifiedHelpController is ready (in initState)
  static void processPendingNotification() {
    if (_pendingHelpRequestData != null && Get.isRegistered<UnifiedHelpController>()) {
      Logger.log("🔄 Processing pending notification", type: "info");
      Get.find<UnifiedHelpController>().injectHelpRequestFromNotification(_pendingHelpRequestData!);
      _pendingHelpRequestData = null;
    }
  }

  /// Check for pending help request from background handler (Android)
  static Future<void> checkPendingHelpRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString('pending_help_request');

      if (pendingData != null) {
        Logger.log("🔄 Found pending help request from background", type: "info");
        debugPrint("📝 Pending data: $pendingData");

        final data = jsonDecode(pendingData) as Map<String, dynamic>;

        // Clear stored data
        await prefs.remove('pending_help_request');

        // Process if controller is ready
        if (Get.isRegistered<UnifiedHelpController>()) {
          Get.find<UnifiedHelpController>().injectHelpRequestFromNotification(data);
          Logger.log("✅ Pending help request processed", type: "success");
        } else {
          // Store in memory for later
          _pendingHelpRequestData = data;
          Logger.log("⚠️ Controller not ready, stored in memory", type: "warning");
        }
      }
    } catch (e) {
      Logger.log("❌ Error checking pending help request: $e", type: "error");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHOW LOCAL NOTIFICATION
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isNotificationsEnabled) return;

    // Parse payload to check for help request
    Map<String, dynamic>? data;
    bool isHelpRequest = false;
    if (payload != null) {
      try {
        data = jsonDecode(payload) as Map<String, dynamic>;
        isHelpRequest = data['type'] == 'new_help_request';
      } catch (e) {
        debugPrint('⚠️ Failed to parse payload: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: isHelpRequest ? Importance.max : Importance.high,
      priority: isHelpRequest ? Priority.max : Priority.high,
      playSound: _isSoundEnabled,
      enableVibration: _isVibrationEnabled,
      showWhen: true,
      vibrationPattern: _isVibrationEnabled
          ? Int64List.fromList([0, 500, 200, 500])
          : null,
      category: isHelpRequest ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      fullScreenIntent: isHelpRequest, // Show as full-screen for help requests
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _isSoundEnabled,
      sound: _isSoundEnabled ? 'default' : null,
      interruptionLevel: isHelpRequest ? InterruptionLevel.critical : InterruptionLevel.active,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
      debugPrint('✅ Notification shown: "$title" (help request: $isHelpRequest)');
    } catch (e) {
      debugPrint('❌ showLocalNotification error: $e');
    }
  }

  static void _handleLocalTap(NotificationResponse response) {
    debugPrint('📬 Local notification tapped — payload: ${response.payload}');
    if (response.payload == null || response.payload!.isEmpty) {
      _navigateFromNotification(null);
      return;
    }
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromNotification(data);
    } catch (e) {
      debugPrint('Payload parse error: $e');
      _navigateFromNotification(null);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────
  static bool get isNotificationsEnabled => _isNotificationsEnabled;
  static bool get isSoundEnabled => _isSoundEnabled;
  static bool get isVibrationEnabled => _isVibrationEnabled;
}

// ─────────────────────────────────────────────────────────────────────────────
// PrefsHelper
// ─────────────────────────────────────────────────────────────────────────────
class PrefsHelper {
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
