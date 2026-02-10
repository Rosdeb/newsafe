import Flutter
import UIKit
import GoogleMaps
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     MobileAds.shared.start(completionHandler: nil)
     GMSServices.provideAPIKey("AIzaSyAAvnKkwZndTn8j7MNpL55B42I6jlIIoSk")
     GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
