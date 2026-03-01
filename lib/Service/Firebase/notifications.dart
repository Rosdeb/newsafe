//
// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_instance/src/extension_instance.dart';
// import 'package:get/get_navigation/src/extension_navigation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../controller/GiverHOme/GiverHomeController_/GiverHomeController.dart';
// import '../../utils/app_constant.dart';
// import '../../views/screen/bottom_nav/bottom_nav_wrappers.dart';
// import '../../views/screen/help_seaker/notifications/seaker_notifications.dart';
//
// // ─────────────────────────────────────────────────────────────────────────────
// // TOP-LEVEL background handler — must live outside the class
// // ─────────────────────────────────────────────────────────────────────────────
// @pragma('vm:entry-point')
// Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
//   debugPrint('🔔 Background message: ${message.messageId}');
//
//   final prefs = await SharedPreferences.getInstance();
//   final isEnabled = prefs.getBool(NotificationService.prefNotificationsEnabled) ?? true;
//   if (!isEnabled) return;
//
//   final notification = message.notification;
//   if (notification != null) {
//     await NotificationService.showLocalNotification(
//       title: notification.title ?? 'Notification',
//       body: notification.body ?? '',
//       payload: message.data.toString(),
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // NotificationService
// // ─────────────────────────────────────────────────────────────────────────────
// class NotificationService {
//   // ── Channel IDs ─────────────────────────────────────────────────────────────
//   static const String _channelId = 'app_notifications';
//   static const String _channelName = 'App Notifications';
//   static const String _channelDescription = 'General notifications';
//
//   // ── SharedPreference keys (public so background handler can access) ─────────
//   static const String prefNotificationsEnabled = 'notifications_enabled';
//   static const String _prefSoundEnabled = 'sound_enabled';
//   static const String _prefVibrationEnabled = 'vibration_enabled';
//
//   // ── Native MethodChannel names — must match AppDelegate.swift exactly ───────
//   static const MethodChannel _fcmTokenChannel =
//   MethodChannel('fcm_token_channel');
//   static const MethodChannel _notificationChannel =
//   MethodChannel('notification_channel');
//
//   // ── Firebase & Local Notifications ──────────────────────────────────────────
//   static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//   FlutterLocalNotificationsPlugin();
//
//   // ── In-memory preference state ───────────────────────────────────────────────
//   static bool _isNotificationsEnabled = true;
//   static bool _isSoundEnabled = true;
//   static bool _isVibrationEnabled = true;
//
//   // ── Navigator key — set this on your MaterialApp ──────────────────────────>
//   static final GlobalKey<NavigatorState> navigatorKey =
//   GlobalKey<NavigatorState>();
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // PUBLIC: Call once from main.dart AFTER Firebase.initializeApp()
//   // ───────────────────────────────────────────────────────────────────────────
//   static Future<void> initialize() async {
//     await _loadNotificationPreferences();
//     await _initializeFirebase();
//     await _initializeLocalNotifications();
//     await _setupFirebaseListeners();
//     _setupNativeChannelListeners(); // ← listens to iOS AppDelegate events
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // NATIVE CHANNEL LISTENERS
//   // Receives FCM token and notification-tap events from AppDelegate.swift
//   // ───────────────────────────────────────────────────────────────────────────
//   static void _setupNativeChannelListeners() {
//     // 1. FCM Token sent from iOS native side
//     _fcmTokenChannel.setMethodCallHandler((MethodCall call) async {
//       if (call.method == 'onToken') {
//         final args = call.arguments as Map?;
//         final token = args?['token'] as String?;
//         if (token != null) {
//           debugPrint('✅ FCM Token received from native: $token');
//           await PrefsHelper.setString(AppConstants.fcmToken, token);
//           // Re-subscribe to topic in case it was lost
//           await _firebaseMessaging.subscribeToTopic('signedInUsers');
//         }
//       }
//     });
//
//     // 2. Notification tap forwarded from iOS native side
//     _notificationChannel.setMethodCallHandler((MethodCall call) async {
//       if (call.method == 'onNotificationTap') {
//         final data = call.arguments as Map<dynamic, dynamic>?;
//         debugPrint('📬 Notification tap received from native: $data');
//         _navigateToNotificationsPage(
//           data?.map((k, v) => MapEntry(k.toString(), v)),
//         );
//       }
//     });
//
//     debugPrint('✅ Native MethodChannel listeners registered');
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // FCM TOKEN
//   // ───────────────────────────────────────────────────────────────────────────
//   static Future<void> getFcmToken() async {
//     try {
//       final NotificationSettings settings =
//       await _firebaseMessaging.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: true,
//         provisional: false,
//         sound: true,
//       );
//
//       if (settings.authorizationStatus == AuthorizationStatus.denied) {
//         debugPrint('❌ Notification permission denied');
//         return;
//       }
//
//       final String? fcmToken = await _firebaseMessaging.getToken();
//       if (fcmToken != null) {
//         await PrefsHelper.setString(AppConstants.fcmToken, fcmToken);
//         debugPrint('✅ FCM Token saved: $fcmToken');
//         await _firebaseMessaging.subscribeToTopic('signedInUsers');
//       } else {
//         debugPrint('⚠️ FCM token not available yet');
//       }
//     } catch (error) {
//       debugPrint('❌ Error getting FCM token: $error');
//     }
//   }
//
//   /// Returns the FCM token, waiting up to [maxWait] if needed.
//   /// Useful for login flow where token must be ready before sending request.
//   static Future<String?> waitForFcmToken({Duration? maxWait}) async {
//     final duration = maxWait ?? const Duration(seconds: 5);
//     final startTime = DateTime.now();
//
//     while (DateTime.now().difference(startTime) < duration) {
//       final token = await PrefsHelper.getString(AppConstants.fcmToken);
//       if (token != null) {
//         return token;
//       }
//       await Future.delayed(const Duration(milliseconds: 500));
//     }
//
//     debugPrint('⚠️ FCM token not available after waiting');
//     return null;
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // PREFERENCES
//   // ───────────────────────────────────────────────────────────────────────────
//   static Future<void> _loadNotificationPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     _isNotificationsEnabled = prefs.getBool(prefNotificationsEnabled) ?? true;
//     _isSoundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
//     _isVibrationEnabled = prefs.getBool(_prefVibrationEnabled) ?? true;
//   }
//
//   static Future<void> _saveNotificationPreference(bool isEnabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(prefNotificationsEnabled, isEnabled);
//     _isNotificationsEnabled = isEnabled;
//   }
//
//   static Future<void> toggleNotifications(bool isEnabled) async {
//     if (!isEnabled) {
//       await _localNotifications.cancelAll();
//       debugPrint('🔕 All notifications cleared');
//     } else {
//       debugPrint('🔔 Notifications enabled');
//     }
//     await _saveNotificationPreference(isEnabled);
//   }
//
//   static Future<void> toggleSound(bool isEnabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_prefSoundEnabled, isEnabled);
//     _isSoundEnabled = isEnabled;
//     debugPrint('🔊 Sound ${isEnabled ? 'enabled' : 'disabled'}');
//   }
//
//   static Future<void> toggleVibration(bool isEnabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_prefVibrationEnabled, isEnabled);
//     _isVibrationEnabled = isEnabled;
//     debugPrint('📳 Vibration ${isEnabled ? 'enabled' : 'disabled'}');
//   }
//
//   static Future<bool> getNotificationPreference() async {
//     await _loadNotificationPreferences();
//     return _isNotificationsEnabled;
//   }
//
//   static Future<bool> getSoundPreference() async {
//     await _loadNotificationPreferences();
//     return _isSoundEnabled;
//   }
//
//   static Future<bool> getVibrationPreference() async {
//     await _loadNotificationPreferences();
//     return _isVibrationEnabled;
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // FIREBASE INIT
//   // ───────────────────────────────────────────────────────────────────────────
//   static Future<void> _initializeFirebase() async {
//     try {
//       final NotificationSettings settings =
//       await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//       );
//       debugPrint(
//           '🔔 Permission status: ${settings.authorizationStatus}');
//
//       // Load or fetch token
//       final savedToken =
//       await PrefsHelper.getString(AppConstants.fcmToken);
//       if (savedToken == null) {
//         debugPrint('⚠️ No saved token — fetching new one');
//         await getFcmToken();
//       } else {
//         debugPrint('✅ Saved FCM Token found: $savedToken');
//       }
//
//       // Always listen for token refresh
//       _firebaseMessaging.onTokenRefresh.listen((newToken) async {
//         debugPrint('🔄 FCM Token refreshed: $newToken');
//         await PrefsHelper.setString(AppConstants.fcmToken, newToken);
//       });
//     } on Exception catch (error) {
//       debugPrint('❌ Firebase init error: $error');
//     }
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // LOCAL NOTIFICATIONS INIT
//   // ───────────────────────────────────────────────────────────────────────────
//   static Future<void> _initializeLocalNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const DarwinInitializationSettings iosSettings =
//     DarwinInitializationSettings(
//       // Permissions already requested by AppDelegate on iOS —
//       // set all to false here to avoid double-prompting
//       requestAlertPermission: false,
//       requestBadgePermission: false,
//       requestSoundPermission: false,
//     );
//
//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     //<------>  Android-only permission request <------>
//     await _localNotifications
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.requestNotificationsPermission();
//
//     await _localNotifications.initialize(
//       onDidReceiveNotificationResponse: _handleNotificationTap,
//       settings: initSettings,
//     );
//
//     await _createAndroidNotificationChannel();
//   }
//
//   static void _navigateToNotificationsPage(Map<String, dynamic>? data) {
//     final context = navigatorKey.currentContext;
//     if (context == null) {
//       debugPrint('⚠️ navigatorKey context is null');
//       return;
//     }
//
//     // data তে type check করো
//     final type = data?['type']?.toString();
//
//     if (type == 'new_help_request') {
//       // GiverHomeController এ help request inject করো
//       _injectHelpRequestToController(data!);
//       Get.offAll(() => BottomMenuWrappers());
//     } else {
//       // Normal notification page
//       Navigator.push(context, MaterialPageRoute(builder: (_) => SeakerNotifications()),);
//     }
//   }
//
//   // GiverHomeController এ data inject করার method
//   static void _injectHelpRequestToController(Map<String, dynamic> data) {
//     try {
//       if (!Get.isRegistered<GiverHomeController>()) {
//         debugPrint('GiverHomeController not registered yet');
//         // Controller না থাকলে pending data store করো
//         _pendingHelpRequestData = data;
//         return;
//       }
//
//       final controller = Get.find<GiverHomeController>();
//       controller.injectHelpRequestFromNotification(data);
//
//     } catch (e) {
//       debugPrint(' Error injecting help request: $e');
//     }
//   }
//
//
//
// // Pending data (controller ready হওয়ার আগে notification আসলে)
//   static Map<String, dynamic>? _pendingHelpRequestData;
//
// // Controller ready হলে pending data process করার জন্য
//   static void processPendingNotification() {
//     if (_pendingHelpRequestData != null) {
//       _injectHelpRequestToController(_pendingHelpRequestData!);
//       _pendingHelpRequestData = null;
//     }
//   }
//
//   static Future<void> _createAndroidNotificationChannel() async {
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       _channelId,
//       _channelName,
//       description: _channelDescription,
//       importance: Importance.high,
//       playSound: true,
//       enableVibration: true,
//       showBadge: true,
//     );
//
//     await _localNotifications
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // FIREBASE MESSAGE LISTENERS
//   // ───────────────────────────────────────────────────────────────────────────
//   static Future<void> _setupFirebaseListeners() async {
//     // Foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint('📬 Foreground message: ${message.messageId}');
//       _handleForegroundMessage(message);
//     });
//
//     // App opened from background via notification tap
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint('📬 App opened from background notification');
//       _navigateToNotificationsPage(message.data);
//     });
//
//     // App launched from terminated state via notification
//     final RemoteMessage? initialMessage =
//     await _firebaseMessaging.getInitialMessage();
//     if (initialMessage != null) {
//       debugPrint('📬 App launched from terminated state via notification');
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _navigateToNotificationsPage(initialMessage.data);
//       });
//     }
//
//     // Background handler (top-level function)
//     FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
//   }
//
//   static void _handleForegroundMessage(RemoteMessage message) {
//     if (!_isNotificationsEnabled) return;
//     final notification = message.notification;
//     if (notification != null) {
//       showLocalNotification(
//         title: notification.title ?? 'Notification',
//         body: notification.body ?? '',
//         payload: message.data.toString(),
//       );
//     }
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // SHOW LOCAL NOTIFICATION (public so background handler can call it)
//   // ───────────────────────────────────────────────────────────────────────────
//   static Future<void> showLocalNotification({
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     if (!_isNotificationsEnabled) return;
//
//     final AndroidNotificationDetails androidDetails =
//     AndroidNotificationDetails(
//       _channelId,
//       _channelName,
//       channelDescription: _channelDescription,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: _isSoundEnabled,
//       enableVibration: _isVibrationEnabled,
//       showWhen: true,
//       vibrationPattern: _isVibrationEnabled
//           ? Int64List.fromList([0, 500, 200, 500])
//           : null,
//     );
//
//     final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: _isSoundEnabled,
//       sound: _isSoundEnabled ? 'default' : null,
//       interruptionLevel: InterruptionLevel.active,
//     );
//
//     final NotificationDetails platformDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     try {
//       await _localNotifications.show(
//         id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         title: title,
//         body: body,
//         notificationDetails: platformDetails,
//         payload: payload,
//       );
//       debugPrint(
//           '✅ Notification shown: "$title" (sound: $_isSoundEnabled, vibration: $_isVibrationEnabled)');
//     } catch (error) {
//       debugPrint('❌ Error showing local notification: $error');
//     }
//   }
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // NAVIGATION
//   // ───────────────────────────────────────────────────────────────────────────
//   static void _handleNotificationTap(NotificationResponse response) {
//     debugPrint('📬 Local notification tapped. Payload: ${response.payload}');
//
//     // ✅ Payload parse করো
//     if (response.payload != null && response.payload!.isNotEmpty) {
//       try {
//         // Payload String থেকে Map বানাও
//         final payloadString = response.payload!;
//
//         // dart Map toString() format: {key: value, key2: value2}
//         // এটা JSON না, তাই আলাদাভাবে handle করতে হবে
//         // সবচেয়ে ভালো হলো payload এ JSON পাঠানো
//         final Map<String, dynamic> data = _parsePayload(payloadString);
//         _navigateToNotificationsPage(data);
//       } catch (e) {
//         debugPrint('❌ Payload parse error: $e');
//         _navigateToNotificationsPage(null);
//       }
//     } else {
//       _navigateToNotificationsPage(null);
//     }
//   }
//
//   static Map<String, dynamic> _parsePayload(String payload) {
//     try {
//       // JSON format হলে
//       return Map<String, dynamic>.from(jsonDecode(payload) as Map);
//     } catch (e) {
//       return {};
//     }
//   }
//
//
//
//   // ───────────────────────────────────────────────────────────────────────────
//   // GETTERS
//   // ───────────────────────────────────────────────────────────────────────────
//   static bool get isNotificationsEnabled => _isNotificationsEnabled;
//   static bool get isSoundEnabled => _isSoundEnabled;
//   static bool get isVibrationEnabled => _isVibrationEnabled;
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // PrefsHelper
// // ─────────────────────────────────────────────────────────────────────────────
// class PrefsHelper {
//   static Future<void> setString(String key, String value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(key, value);
//   }
//
//   static Future<String?> getString(String key) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(key);
//   }
//
//   static Future<void> remove(String key) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(key);
//   }
//
//   static Future<void> clear() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//   }
// }

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
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
  debugPrint('🔔 Background message: ${message.messageId}');
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool(NotificationService.prefNotificationsEnabled) ?? true;
  if (!isEnabled) return;

  final notification = message.notification;
  if (notification != null) {
    await NotificationService.showLocalNotification(
      title: notification.title ?? 'Notification',
      body: notification.body ?? '',
      payload: message.data.toString(),
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
      debugPrint('❌ Firebase init error: $e');
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

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIREBASE LISTENERS
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _setupFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('📬 Foreground message: ${msg.messageId}');
      if (!_isNotificationsEnabled) return;
      final n = msg.notification;
      if (n != null) {
        showLocalNotification(
          title: n.title ?? 'Notification',
          body: n.body ?? '',
          payload: jsonEncode(msg.data), // store as JSON for reliable parsing
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('📬 App opened from background notification');
      _navigateFromNotification(msg.data);
    });

    final initial = await _firebaseMessaging.getInitialMessage();
    if (initial != null) {
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
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ navigatorKey context is null');
      return;
    }

    final type = data?['type']?.toString();
    if (type == 'new_help_request') {
      _injectHelpRequest(data!);
      Get.offAll(() => BottomMenuWrappers());
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SeakerNotifications()));
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
    if (_pendingHelpRequestData != null) {
      _injectHelpRequest(_pendingHelpRequestData!);
      _pendingHelpRequestData = null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHOW LOCAL NOTIFICATION
  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // SHOW LOCAL NOTIFICATION
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isNotificationsEnabled) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: _isSoundEnabled,
      enableVibration: _isVibrationEnabled,
      showWhen: true,
      vibrationPattern: _isVibrationEnabled
          ? Int64List.fromList([0, 500, 200, 500])
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _isSoundEnabled,
      sound: _isSoundEnabled ? 'default' : null,
      interruptionLevel: InterruptionLevel.active,
    );

    // ✅ Assign platformDetails before using it
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // ✅ .show() uses positional args (id, title, body, details), payload is named
      await _localNotifications.show(
        id:DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails:platformDetails,
        payload: payload,
      );
      debugPrint(' Notification shown: "$title"');
    } catch (e) {
      debugPrint(' showLocalNotification error: $e');
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
