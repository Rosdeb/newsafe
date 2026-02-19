// import 'dart:typed_data';
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../utils/app_constant.dart';
// import '../../views/screen/help_seaker/notifications/seaker_notifications.dart';
//
// class NotificationService {
//   static const String _channelId = 'app_notifications';
//   static const String _channelName = 'App Notifications';
//   static const String _channelDescription = 'General notifications';
//   static const String _prefNotificationsEnabled = 'notifications_enabled';
//   static const String _prefSoundEnabled = 'sound_enabled';
//   static const String _prefVibrationEnabled = 'vibration_enabled';
//
//   static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//   FlutterLocalNotificationsPlugin();
//
//   static bool _isNotificationsEnabled = true;
//   static bool _isSoundEnabled = true;
//   static bool _isVibrationEnabled = true;
//
//   // GlobalKey for navigation
//   static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
//   static Future<void> initialize() async {
//     await _initializeFirebase();
//     await _initializeLocalNotifications();
//     await _loadNotificationPreferences();
//     await _setupFirebaseListeners();
//   }
//
//   static Future<void> getFcmToken() async {
//     try {
//       // Request notification permissions
//       final NotificationSettings settings = await _firebaseMessaging.requestPermission(
//         alert: true,
//         announcement: false,
//         badge: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//         sound: true,
//       );
//
//       if (settings.authorizationStatus == AuthorizationStatus.denied) {
//         debugPrint('Notification permission denied');
//         return;
//       }
//
//       // Get FCM token
//       final String? fcmToken = await _firebaseMessaging.getToken();
//
//       if (fcmToken != null) {
//         await PrefsHelper.setString(AppConstants.fcmToken, fcmToken);
//         debugPrint('FCM Token saved: $fcmToken');
//
//         // Subscribe to general topic
//         await _firebaseMessaging.subscribeToTopic('signedInUsers');
//       } else {
//         debugPrint('FCM token not available');
//       }
//     } catch (error) {
//       debugPrint('Error getting FCM token: $error');
//     }
//   }
//
//   static Future<void> _loadNotificationPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     _isNotificationsEnabled = prefs.getBool(_prefNotificationsEnabled) ?? true;
//     _isSoundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
//     _isVibrationEnabled = prefs.getBool(_prefVibrationEnabled) ?? true;
//   }
//
//   static Future<void> _saveNotificationPreference(bool isEnabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_prefNotificationsEnabled, isEnabled);
//     _isNotificationsEnabled = isEnabled;
//   }
//
//   // New method to toggle sound
//   static Future<void> toggleSound(bool isEnabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_prefSoundEnabled, isEnabled);
//     _isSoundEnabled = isEnabled;
//     debugPrint('Sound ${isEnabled ? 'enabled' : 'disabled'}');
//   }
//
//   // New method to toggle vibration
//   static Future<void> toggleVibration(bool isEnabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_prefVibrationEnabled, isEnabled);
//     _isVibrationEnabled = isEnabled;
//     debugPrint('Vibration ${isEnabled ? 'enabled' : 'disabled'}');
//   }
//
//   static Future<void> toggleNotifications(bool isEnabled) async {
//     if (isEnabled) {
//       debugPrint('Notifications enabled');
//     } else {
//       await _localNotifications.cancelAll();
//       debugPrint('Notifications disabled and cleared');
//     }
//     await _saveNotificationPreference(isEnabled);
//   }
//
//   static Future<bool> getNotificationPreference() async {
//     await _loadNotificationPreferences();
//     return _isNotificationsEnabled;
//   }
//
//   // New getter for sound preference
//   static Future<bool> getSoundPreference() async {
//     await _loadNotificationPreferences();
//     return _isSoundEnabled;
//   }
//
//   // New getter for vibration preference
//   static Future<bool> getVibrationPreference() async {
//     await _loadNotificationPreferences();
//     return _isVibrationEnabled;
//   }
//
//   static Future<void> _initializeFirebase() async {
//     try {
//       final NotificationSettings settings = await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//       );
//
//       debugPrint('Notification permission: ${settings.authorizationStatus}');
//
//       await getFcmToken();
//       final savedToken = await PrefsHelper.getString(AppConstants.fcmToken);
//       if (savedToken == null) {
//         debugPrint("No saved token → getting new one");
//         await getFcmToken(); // Only first time
//       } else {
//         debugPrint("Saved FCM Token: $savedToken");
//       }
//
//       _firebaseMessaging.onTokenRefresh.listen((newToken) async {
//         debugPrint('FCM Token refreshed: $newToken');
//         await PrefsHelper.setString(AppConstants.fcmToken, newToken);
//       });
//     } on Exception catch (error) {
//       debugPrint('Firebase initialization error: $error');
//     }
//   }
//
//   static Future<void> _initializeLocalNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//     const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     const InitializationSettings initializationSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     // Request Android permissions
//     await _localNotifications
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.requestNotificationsPermission();
//
//     await _localNotifications.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: _handleNotificationTap,
//     );
//
//     // Create notification channel for Android
//     await _createNotificationChannel();
//   }
//
//   static Future<void> _createNotificationChannel() async {
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
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }
//
//   /// Set up all Firebase message listeners
//   static Future<void> _setupFirebaseListeners() async {
//     // Listen for foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint('Foreground message received: ${message.messageId}');
//       _handleForegroundMessage(message);
//     });
//
//     // Listen for background/opened app messages
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint('App opened from notification');
//       _navigateToNotificationsPage(message.data);
//     });
//
//     // Handle terminated state messages
//     final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
//     if (initialMessage != null) {
//       debugPrint('App opened from terminated state via notification');
//       // Delay navigation to ensure app is fully initialized
//       Future.delayed(const Duration(milliseconds: 500), () {
//         _navigateToNotificationsPage(initialMessage.data);
//       });
//     }
//
//     // Set background message handler
//     FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
//   }
//
//   static void _handleForegroundMessage(RemoteMessage message) {
//     if (!_isNotificationsEnabled) return;
//
//     final notification = message.notification;
//     if (notification != null) {
//       _showLocalNotification(
//         title: notification.title ?? 'Notification',
//         body: notification.body ?? '',
//         payload: message.data.toString(),
//       );
//     }
//   }
//
//   /// Background message handler (must be top-level)
//   @pragma('vm:entry-point')
//   static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
//     debugPrint('Background message handled: ${message.messageId}');
//
//     // Load preferences in background
//     final prefs = await SharedPreferences.getInstance();
//     final isEnabled = prefs.getBool(_prefNotificationsEnabled) ?? true;
//
//     if (!isEnabled) return;
//
//     // Show notification in background
//     final notification = message.notification;
//     if (notification != null) {
//       await _showLocalNotification(
//         title: notification.title ?? 'Notification',
//         body: notification.body ?? '',
//         payload: message.data.toString(),
//       );
//     }
//   }
//
//   /// Show local notification with sound and vibration based on preferences
//   static Future<void> _showLocalNotification({
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     if (!_isNotificationsEnabled) return;
//
//     // Create Android notification details with conditional sound and vibration
//     final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       _channelId,
//       _channelName,
//       channelDescription: _channelDescription,
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: _isSoundEnabled,
//       enableVibration: _isVibrationEnabled,
//       showWhen: true,
//       // Optional: Custom vibration pattern (in milliseconds)
//       vibrationPattern: _isVibrationEnabled
//           ? Int64List.fromList([0, 500, 200, 500])
//           : null,
//     );
//
//     final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: _isSoundEnabled,
//     );
//
//     final NotificationDetails platformDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     try {
//       await _localNotifications.show(
//         DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
//         title,
//         body,
//         platformDetails,
//         payload: payload,
//       );
//
//       debugPrint('Local notification shown: $title (Sound: $_isSoundEnabled, Vibration: $_isVibrationEnabled)');
//     } catch (error) {
//       debugPrint('Error showing local notification: $error');
//     }
//   }
//
//   /// Handle notification tap - Navigate to notifications page
//   static void _handleNotificationTap(NotificationResponse response) {
//     debugPrint('Notification tapped - navigating to notifications page');
//     debugPrint('Payload: ${response.payload}');
//
//     // Navigate to notifications page
//     _navigateToNotificationsPage(null);
//   }
//
//   /// Navigate to notifications page
//   static void _navigateToNotificationsPage(Map<String, dynamic>? data) {
//     final context = navigatorKey.currentContext;
//     if (context != null) {
//       // Option 1: Using named route
//       // Navigator.pushNamed(context, '/notifications', arguments: data);
//       // Option 2: Using direct navigation (uncomment if you prefer this)
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => SeakerNotifications(),
//         ),
//       );
//     } else {
//       debugPrint('Navigator context is null, cannot navigate');
//     }
//   }
//
//   static bool get isNotificationsEnabled => _isNotificationsEnabled;
//   static bool get isSoundEnabled => _isSoundEnabled;
//   static bool get isVibrationEnabled => _isVibrationEnabled;
// }
//
// class PrefsHelper {
//   // Save string value
//   static Future<void> setString(String key, String value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(key, value);
//   }
//
//   // Get string value
//   static Future<String?> getString(String key) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(key);
//   }
//
//   // Remove key
//   static Future<void> remove(String key) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(key);
//   }
//
//   // Clear all keys
//   static Future<void> clear() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//   }
// }

import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_constant.dart';
import '../../views/screen/help_seaker/notifications/seaker_notifications.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOP-LEVEL background handler — must live outside the class
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
  // ── Channel IDs ─────────────────────────────────────────────────────────────
  static const String _channelId = 'app_notifications';
  static const String _channelName = 'App Notifications';
  static const String _channelDescription = 'General notifications';

  // ── SharedPreference keys (public so background handler can access) ─────────
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String _prefSoundEnabled = 'sound_enabled';
  static const String _prefVibrationEnabled = 'vibration_enabled';

  // ── Native MethodChannel names — must match AppDelegate.swift exactly ───────
  static const MethodChannel _fcmTokenChannel =
  MethodChannel('fcm_token_channel');
  static const MethodChannel _notificationChannel =
  MethodChannel('notification_channel');

  // ── Firebase & Local Notifications ──────────────────────────────────────────
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // ── In-memory preference state ───────────────────────────────────────────────
  static bool _isNotificationsEnabled = true;
  static bool _isSoundEnabled = true;
  static bool _isVibrationEnabled = true;

  // ── Navigator key — set this on your MaterialApp ──────────────────────────>
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // ───────────────────────────────────────────────────────────────────────────
  // PUBLIC: Call once from main.dart AFTER Firebase.initializeApp()
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    await _loadNotificationPreferences();
    await _initializeFirebase();
    await _initializeLocalNotifications();
    await _setupFirebaseListeners();
    _setupNativeChannelListeners(); // ← listens to iOS AppDelegate events
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NATIVE CHANNEL LISTENERS
  // Receives FCM token and notification-tap events from AppDelegate.swift
  // ───────────────────────────────────────────────────────────────────────────
  static void _setupNativeChannelListeners() {
    // 1. FCM Token sent from iOS native side
    _fcmTokenChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onToken') {
        final args = call.arguments as Map?;
        final token = args?['token'] as String?;
        if (token != null) {
          debugPrint('✅ FCM Token received from native: $token');
          await PrefsHelper.setString(AppConstants.fcmToken, token);
          // Re-subscribe to topic in case it was lost
          await _firebaseMessaging.subscribeToTopic('signedInUsers');
        }
      }
    });

    // 2. Notification tap forwarded from iOS native side
    _notificationChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onNotificationTap') {
        final data = call.arguments as Map<dynamic, dynamic>?;
        debugPrint('📬 Notification tap received from native: $data');
        _navigateToNotificationsPage(
          data?.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    });

    debugPrint('✅ Native MethodChannel listeners registered');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FCM TOKEN
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> getFcmToken() async {
    try {
      final NotificationSettings settings =
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('❌ Notification permission denied');
        return;
      }

      final String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await PrefsHelper.setString(AppConstants.fcmToken, fcmToken);
        debugPrint('✅ FCM Token saved: $fcmToken');
        await _firebaseMessaging.subscribeToTopic('signedInUsers');
      } else {
        debugPrint('⚠️ FCM token not available yet');
      }
    } catch (error) {
      debugPrint('❌ Error getting FCM token: $error');
    }
  }

  /// Returns the FCM token, waiting up to [maxWait] if needed.
  /// Useful for login flow where token must be ready before sending request.
  static Future<String?> waitForFcmToken({Duration? maxWait}) async {
    final duration = maxWait ?? const Duration(seconds: 5);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < duration) {
      final token = await PrefsHelper.getString(AppConstants.fcmToken);
      if (token != null) {
        return token;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('⚠️ FCM token not available after waiting');
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PREFERENCES
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isNotificationsEnabled = prefs.getBool(prefNotificationsEnabled) ?? true;
    _isSoundEnabled = prefs.getBool(_prefSoundEnabled) ?? true;
    _isVibrationEnabled = prefs.getBool(_prefVibrationEnabled) ?? true;
  }

  static Future<void> _saveNotificationPreference(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefNotificationsEnabled, isEnabled);
    _isNotificationsEnabled = isEnabled;
  }

  static Future<void> toggleNotifications(bool isEnabled) async {
    if (!isEnabled) {
      await _localNotifications.cancelAll();
      debugPrint('🔕 All notifications cleared');
    } else {
      debugPrint('🔔 Notifications enabled');
    }
    await _saveNotificationPreference(isEnabled);
  }

  static Future<void> toggleSound(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundEnabled, isEnabled);
    _isSoundEnabled = isEnabled;
    debugPrint('🔊 Sound ${isEnabled ? 'enabled' : 'disabled'}');
  }

  static Future<void> toggleVibration(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVibrationEnabled, isEnabled);
    _isVibrationEnabled = isEnabled;
    debugPrint('📳 Vibration ${isEnabled ? 'enabled' : 'disabled'}');
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

  // ───────────────────────────────────────────────────────────────────────────
  // FIREBASE INIT
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> _initializeFirebase() async {
    try {
      final NotificationSettings settings =
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
          '🔔 Permission status: ${settings.authorizationStatus}');

      // Load or fetch token
      final savedToken =
      await PrefsHelper.getString(AppConstants.fcmToken);
      if (savedToken == null) {
        debugPrint('⚠️ No saved token — fetching new one');
        await getFcmToken();
      } else {
        debugPrint('✅ Saved FCM Token found: $savedToken');
      }

      // Always listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        await PrefsHelper.setString(AppConstants.fcmToken, newToken);
      });
    } on Exception catch (error) {
      debugPrint('❌ Firebase init error: $error');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LOCAL NOTIFICATIONS INIT
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      // Permissions already requested by AppDelegate on iOS —
      // set all to false here to avoid double-prompting
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Android-only permission request
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    await _createAndroidNotificationChannel();
  }

  static Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FIREBASE MESSAGE LISTENERS
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> _setupFirebaseListeners() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 App opened from background notification');
      _navigateToNotificationsPage(message.data);
    });

    // App launched from terminated state via notification
    final RemoteMessage? initialMessage =
    await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📬 App launched from terminated state via notification');
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToNotificationsPage(initialMessage.data);
      });
    }

    // Background handler (top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    if (!_isNotificationsEnabled) return;
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHOW LOCAL NOTIFICATION (public so background handler can call it)
  // ───────────────────────────────────────────────────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isNotificationsEnabled) return;

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      _channelId,
      _channelName,
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

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _isSoundEnabled,
      sound: _isSoundEnabled ? 'default' : null,
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      debugPrint(
          '✅ Notification shown: "$title" (sound: $_isSoundEnabled, vibration: $_isVibrationEnabled)');
    } catch (error) {
      debugPrint('❌ Error showing local notification: $error');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ───────────────────────────────────────────────────────────────────────────
  static void _handleNotificationTap(NotificationResponse response) {
    debugPrint('📬 Local notification tapped. Payload: ${response.payload}');
    _navigateToNotificationsPage(null);
  }

  static void _navigateToNotificationsPage(Map<String, dynamic>? data) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SeakerNotifications()),
      );
    } else {
      debugPrint('⚠️ navigatorKey context is null — cannot navigate');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ───────────────────────────────────────────────────────────────────────────
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
