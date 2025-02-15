import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    let channelName : String = "PushNotificationChannel"
    var deviceToken : String = ""

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let pushNotificationChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        
        if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        pushNotificationChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "requestNotificationPermissions":
                self?.requestNotificationPermissions(result: result)
            case "registerForPushNotifications":
                self?.registerForPushNotifications(application: application, result: result)
            case "retrieveDeviceToken":
                self?.getDeviceToken(result: result)        
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

     private func requestNotificationPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            result(FlutterError(code: "PERMISSION_ERROR", message: "Failed to request permissions", details: error.localizedDescription))
            return
        }
            result(granted)
        }
    }

    private func registerForPushNotifications(application: UIApplication, result: @escaping FlutterResult) {
        application.registerForRemoteNotifications()
        result("Device Token registration initiated")
    }
    
    private func getDeviceToken(result: @escaping FlutterResult) {
        if(deviceToken.isEmpty){
            result(FlutterError(code: "UNAVAILABLE", message: "Device token not available", details: nil))
        } else{
            result(deviceToken)
        }
    }
}