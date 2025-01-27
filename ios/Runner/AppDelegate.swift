import Flutter
import UIKit
import MapboxMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ResourceOptionsManager.default.resourceOptions.accessToken = "sk.eyJ1IjoiZ3JhdmdvcjExMSIsImEiOiJjbTZmaWZyZzgwNHk2MmpxcHU4ejFoOTNpIn0.WS1Aq5U_EMcQ4pPSh398Pw"
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
