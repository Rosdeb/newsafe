// import Flutter
// import UIKit
// import GoogleMaps
// import GoogleMobileAds
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//      MobileAds.shared.start(completionHandler: nil)
//      GMSServices.provideAPIKey("AIzaSyAAvnKkwZndTn8j7MNpL55B42I6jlIIoSk")
//      GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }
//
// import Flutter
// import UIKit
// import GoogleMaps
// import GoogleMobileAds
// // import GoogleSignIn
// import FirebaseCore
// import FirebaseMessaging
// import UserNotifications
//
// @main
// @objc class AppDelegate: FlutterAppDelegate {
//
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//
//     // MARK: - 1. Firebase (initialized in Dart code)
//
//     // MARK: - 2. FCM & Notification Delegates
//     Messaging.messaging().delegate = self
//     if #available(iOS 10.0, *) {
//       UNUserNotificationCenter.current().delegate = self
//     }
//
//
//     // MARK: - 3. Google Maps & Ads
//     MobileAds.shared.start(completionHandler: nil)
//     GMSServices.provideAPIKey("AIzaSyAAvnKkwZndTn8j7MNpL55B42I6jlIIoSk")
//
//     // MARK: - 4. Register Flutter Plugins
//     GeneratedPluginRegistrant.register(with: self)
//
//     // MARK: - 5. Request Notification Permission
//     if #available(iOS 10.0, *) {
//       let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//
//       UNUserNotificationCenter.current().requestAuthorization(
//         options: authOptions
//       ) { granted, error in
//         if let error = error {
//           print("❌ Notification permission error: \(error.localizedDescription)")
//         } else {
//           print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
//         }
//       }
//     }
//
//     // MARK: - 6. Register for Remote Notifications
//     application.registerForRemoteNotifications()
//
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
//
//   // MARK: - Google Sign-In URL Handling (commented out — uncomment when GoogleSignIn is needed)
//   // override func application(
//   //   _ app: UIApplication,
//   //   open url: URL,
//   //   options: [UIApplication.OpenURLOptionsKey: Any] = [:]
//   // ) -> Bool {
//   //   if GIDSignIn.sharedInstance.handle(url) {
//   //     return true
//   //   }
//   //   return super.application(app, open: url, options: options)
//   // }
//
//   // MARK: - Universal Links — Google Sign-In (commented out — uncomment when GoogleSignIn is needed)
//   // override func application(
//   //   _ application: UIApplication,
//   //   continue userActivity: NSUserActivity,
//   //   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
//   // ) -> Bool {
//   //   if let url = userActivity.webpageURL, GIDSignIn.sharedInstance.handle(url) {
//   //     return true
//   //   }
//   //   return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
//   // }
//
//   // MARK: - APNs Token Registration
//   override func application(
//     _ application: UIApplication,
//     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
//   ) {
//     // Hand APNs token to Firebase so FCM can map it
//     Messaging.messaging().apnsToken = deviceToken
//
//     let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
//     print("✅ APNs Device Token: \(tokenString)")
//   }
//
//   override func application(
//     _ application: UIApplication,
//     didFailToRegisterForRemoteNotificationsWithError error: Error
//   ) {
//     print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
//   }
//
//   // MARK: - Foreground Notification Display
//   override func userNotificationCenter(
//     _ center: UNUserNotificationCenter,
//     willPresent notification: UNNotification,
//     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
//   ) {
//     let userInfo = notification.request.content.userInfo
//     print("📬 Foreground notification received: \(userInfo)")
//
//     // Show banner + sound + badge even when app is open
//     if #available(iOS 14.0, *) {
//       completionHandler([.banner, .sound, .badge])
//     } else {
//       completionHandler([.alert, .sound, .badge])
//     }
//   }
//
//   // MARK: - Notification Tap Handler
//   override func userNotificationCenter(
//     _ center: UNUserNotificationCenter,
//     didReceive response: UNNotificationResponse,
//     withCompletionHandler completionHandler: @escaping () -> Void
//   ) {
//     let userInfo = response.notification.request.content.userInfo
//     print("📬 Notification tapped: \(userInfo)")
//
//     // Forward tap data to Flutter side
//     sendNotificationDataToFlutter(userInfo: userInfo)
//
//     completionHandler()
//   }
//
//   // MARK: - Helper: Send notification payload to Flutter
//   private func sendNotificationDataToFlutter(userInfo: [AnyHashable: Any]) {
//     DispatchQueue.main.async {
//       guard let controller = self.window?.rootViewController as? FlutterViewController else {
//         print("⚠️ FlutterViewController not ready — cannot forward notification data")
//         return
//       }
//       let channel = FlutterMethodChannel(
//         name: "notification_channel",
//         binaryMessenger: controller.binaryMessenger
//       )
//       // Convert keys to String for Flutter compatibility
//       let data = Dictionary(uniqueKeysWithValues: userInfo.compactMap { key, value -> (String, Any)? in
//         guard let stringKey = key as? String else { return nil }
//         return (stringKey, value)
//       })
//       channel.invokeMethod("onNotificationTap", arguments: data)
//     }
//   }
// }
//
// // MARK: - MessagingDelegate (FCM Token)
// extension AppDelegate: MessagingDelegate {
//
//   func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//     guard let token = fcmToken else {
//       print("⚠️ FCM token is nil")
//       return
//     }
//
//     print("✅ FCM Token: \(token)")
//
//     // Persist locally so Flutter can read it on next launch
//     UserDefaults.standard.set(token, forKey: "fcm_token")
//
//     // Send to Flutter side via MethodChannel
//     DispatchQueue.main.async {
//       guard let controller = self.window?.rootViewController as? FlutterViewController else {
//         print("⚠️ FlutterViewController not ready — FCM token will be read from UserDefaults")
//         return
//       }
//       let channel = FlutterMethodChannel(
//         name: "fcm_token_channel",
//         binaryMessenger: controller.binaryMessenger
//       )
//       channel.invokeMethod("onToken", arguments: ["token": token])
//       print("✅ FCM Token sent to Flutter")
//     }
//   }
//}

import Flutter
import UIKit
import GoogleMaps
import GoogleMobileAds
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // MARK: - 1. Firebase (initialized in Dart code)

    // MARK: - 2. FCM & Notification Delegates
    Messaging.messaging().delegate = self
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - 3. Google Maps & Ads
    MobileAds.shared.start(completionHandler: nil)
    GMSServices.provideAPIKey("AIzaSyAAvnKkwZndTn8j7MNpL55B42I6jlIIoSk")

    // MARK: - 4. Register Flutter Plugins
    GeneratedPluginRegistrant.register(with: self)

    // MARK: - 5. Request Notification Permission (with vibration support)
    if #available(iOS 10.0, *) {
      // .sound is what triggers vibration on iPhone automatically
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions
      ) { granted, error in
        if let error = error {
          print("❌ Notification permission error: \(error.localizedDescription)")
        } else {
          print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
        }
      }
    }

    // MARK: - 6. Register for Remote Notifications
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - APNs Token Registration
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Hand APNs token to Firebase so FCM can map it
    Messaging.messaging().apnsToken = deviceToken

    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ APNs Device Token: \(tokenString)")
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
  }

  // MARK: - Foreground Notification Display + Vibration
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("📬 Foreground notification received: \(userInfo)")

    // ✅ iOS 15+: Set interruptionLevel to trigger vibration
    if #available(iOS 15.0, *) {
      let content = notification.request.content.mutableCopy() as! UNMutableNotificationContent
      // .active  → vibrates + sound (normal notifications)
      // .timeSensitive → vibrates + bypasses Focus/DND mode
      content.interruptionLevel = .timeSensitive
      print("✅ interruptionLevel set to timeSensitive — vibration enabled")
    }

    // ✅ Show banner + sound + badge + list (list keeps it in Notification Center)
    // .sound here is what physically causes iPhone to vibrate
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge, .list])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // MARK: - Notification Tap Handler
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("📬 Notification tapped: \(userInfo)")

    // Forward tap data to Flutter side
    sendNotificationDataToFlutter(userInfo: userInfo)

    completionHandler()
  }

  // MARK: - Helper: Send notification payload to Flutter
  private func sendNotificationDataToFlutter(userInfo: [AnyHashable: Any]) {
    DispatchQueue.main.async {
      guard let controller = self.window?.rootViewController as? FlutterViewController else {
        print("⚠️ FlutterViewController not ready — cannot forward notification data")
        return
      }
      let channel = FlutterMethodChannel(
        name: "notification_channel",
        binaryMessenger: controller.binaryMessenger
      )
      // Convert keys to String for Flutter compatibility
      let data = Dictionary(uniqueKeysWithValues: userInfo.compactMap { key, value -> (String, Any)? in
        guard let stringKey = key as? String else { return nil }
        return (stringKey, value)
      })
      channel.invokeMethod("onNotificationTap", arguments: data)
    }
  }

  // MARK: - Helper: Build notification content with vibration (iOS 15+)
  @available(iOS 15.0, *)
  private func buildVibrationContent(from original: UNNotificationContent) -> UNMutableNotificationContent {
    let content = original.mutableCopy() as! UNMutableNotificationContent
    content.interruptionLevel = .timeSensitive  // Bypasses Focus mode, triggers vibration
    content.sound = UNNotificationSound.default  // Ensures vibration with default sound
    return content
  }
}

// MARK: - MessagingDelegate (FCM Token)
extension AppDelegate: MessagingDelegate {

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let token = fcmToken else {
      print("⚠️ FCM token is nil")
      return
    }

    print("✅ FCM Token: \(token)")

    // Persist locally so Flutter can read it on next launch
    UserDefaults.standard.set(token, forKey: "fcm_token")

    // Send to Flutter side via MethodChannel
    DispatchQueue.main.async {
      guard let controller = self.window?.rootViewController as? FlutterViewController else {
        print("⚠️ FlutterViewController not ready — FCM token will be read from UserDefaults")
        return
      }
      let channel = FlutterMethodChannel(
        name: "fcm_token_channel",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onToken", arguments: ["token": token])
      print("✅ FCM Token sent to Flutter")
    }
  }
}