import Flutter
import UIKit
import os
import BackgroundTasks


@available(iOS 10.0, *)
public class SwiftFlutterBackgroundPlugin: NSObject, FlutterPlugin {
    static let identifier = "background_process"
    private let flutterThreadLabelPrefix = "\(SwiftFlutterBackgroundPlugin.identifier).BackgroundFetch"
    private static var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?

//  private var eventSink: FlutterEventSink?
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "sbapp/MethodBackgroundHandler",
            binaryMessenger: registrar.messenger()
        )
        let instance = SwiftFlutterBackgroundPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel )
        registrar.addApplicationDelegate(instance)
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch (call.method) {
        case "createNotificationChannel":
            LocalNotificationManager().initNotification()
            break;
        case "backgroundTask":
            let bgTask = call.arguments as! Int64
            
            break;
        default: result(FlutterMethodNotImplemented)
      }
    }
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        let id = response.notification.request.identifier
        print("Received notification with ID = \(id)")
        
        completionHandler()
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        let id = notification.request.identifier
        print("Received notification with ID = \(id)")
        
        completionHandler([.sound, .alert])
    }
    public static func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
        flutterPluginRegistrantCallback = callback
    }
    public func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
//        completionHandler: @escaping () -> Void,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) -> Bool {
        
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }
}
