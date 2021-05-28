import Flutter
import UIKit
import os
import BackgroundTasks

@available(iOS 10.0, *)
public class SwiftFlutterBackgroundPlugin: FlutterPluginAppLifeCycleDelegate, FlutterPlugin  {
    
    private static var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    var bgChannel : FlutterMethodChannel? = nil
    var mainChannel : FlutterMethodChannel? = nil
    var backgroundEngine: FlutterEngine? = nil
    
    public override func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        self.beginFetch()
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        completionHandler(.newData)
        return true
    }
    
    public override func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    public override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "sbapp/MethodBackgroundHandler",
            binaryMessenger: registrar.messenger()
//            codec: FlutterJSONMethodCodec()
        )
        let instance = SwiftFlutterBackgroundPlugin()
        instance.mainChannel = channel
        
        registrar.addMethodCallDelegate(instance, channel: instance.mainChannel!)
        registrar.addApplicationDelegate(instance)
    }
    
    public static func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
        flutterPluginRegistrantCallback = callback
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "createNotificationChannel" ){
            LocalNotificationManager().initNotification()
        }
        if (call.method == "backgroundTask"){
            let args = call.arguments as? Dictionary<String, Any>
            let callbackHandleID = args?["handle"] as? NSNumber
            let defaults = UserDefaults.standard
            
            print("onBackground \(args?["onBackground"] as! Bool)")
            print("onForeground \(args?["onForeground"] as! Bool)")
            print("onCancel \(args?["onCancel"] as! Bool)")
            
            if(args?["onBackground"] as! Bool == true || args?["onForeground"] as! Bool == true){
                defaults.set(callbackHandleID?.int64Value, forKey: "callback_handle")
                DispatchQueue.main.async {
                    self.beginFetch()
                }
                result(true)
                
            }
            if( args?["onCancel"] as! Bool == true){
                defaults.set(callbackHandleID?.int64Value, forKey: "callback_handle")
                self.beginFetch()
                cleanupFlutterResources()
                result(true)
            }
            return
        }
    }
    func cleanupFlutterResources() {
        backgroundEngine?.destroyContext()
        backgroundEngine = nil
    }
    public override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
        {
        let id = notification.request.identifier
        print("Received notification with ID = \(id)")
        
        completionHandler([.sound, .alert])
    }
    
    public override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
        {
        let id = response.notification.request.identifier
        print("Received notification with ID = \(id)")
        
        completionHandler()
    }
         
    public func beginFetch(){
        if (self.backgroundEngine != nil){	
            return
        }
        
        let defaults = UserDefaults.standard
        
       if let callbackHandleID = defaults.object(forKey: "callback_handle") as? Int64 {
            let callbackHandle = FlutterCallbackCache.lookupCallbackInformation(callbackHandleID)
            
            let callbackName = callbackHandle?.callbackName
            let uri = callbackHandle?.callbackLibraryPath
            
            self.backgroundEngine = FlutterEngine(name: "FlutterService", project: nil, allowHeadlessExecution: true)
            self.backgroundEngine!.run(withEntrypoint: callbackName, libraryURI: uri)
            SwiftFlutterBackgroundPlugin.flutterPluginRegistrantCallback?(self.backgroundEngine!)
        }
        
        let binaryMessenger = self.backgroundEngine?.binaryMessenger
        self.bgChannel = FlutterMethodChannel(name: "BackgroundReceive", binaryMessenger: binaryMessenger!)
        
        self.bgChannel?.setMethodCallHandler({
            (call : FlutterMethodCall , result: @escaping FlutterResult) ->Void in
            let args = call.arguments as? Dictionary<String, Any>
            if (args != nil){
                if(args?["receive"] != nil){
                    result(true)
                }
                if(args?["send"] != nil){
                    result(true)
                }
            }
        })
    }
}
