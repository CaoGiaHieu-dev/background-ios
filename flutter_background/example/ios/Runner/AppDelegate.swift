import UIKit
import Flutter
import flutter_background

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    /// add this
    static func registerPlugins(with registry: FlutterPluginRegistry) {
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        AppDelegate.registerPlugins(with: self)
        SwiftFlutterBackgroundPlugin.setPluginRegistrantCallback { registry in
            AppDelegate.registerPlugins(with: registry)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
