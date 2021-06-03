//
//  SwiftGmoBackgroundServicePlugin.swift
//  gmo_background_service
//
//  Created by Cao Gia Hieu on 6/1/21.
//

import Flutter
import UIKit
import os
import BackgroundTasks

@available(iOS 10.0, *)
public class SwiftGmoBackgroundServicePlugin: FlutterPluginAppLifeCycleDelegate, FlutterPlugin  {
    
    private static var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?

    var mainChannel : FlutterMethodChannel? = nil
    var backgroundEngine: FlutterEngine? = nil
    var bgChannel : FlutterMethodChannel? = nil
    
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
            name: "gmo.flutter/background_service",
            binaryMessenger: registrar.messenger(),
            codec: FlutterJSONMethodCodec()
        )
        let instance = SwiftGmoBackgroundServicePlugin()
        instance.mainChannel = channel
        
        registrar.addMethodCallDelegate(instance, channel: instance.mainChannel!)
        registrar.addApplicationDelegate(instance)
    }
    public static func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
        flutterPluginRegistrantCallback = callback
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        let callbackHandleID = args?["handle"] as? NSNumber
        let defaults = UserDefaults.standard
        defaults.set(callbackHandleID?.int64Value, forKey: "callback_handle")
        if(call.method == "createNotificationChannel" ){
            LocalNotificationManager().initNotification()
        }
        if (call.method == "backgroundTask") {
            DispatchQueue.main.async {
                self.beginFetch()
            }
        }
        if( call.method == "onCancel"){
            DispatchQueue.main.async {
                self.beginFetch()
                self.cleanupFlutterResources()
            }
        }
        if (call.method == "sendData"){
            if (self.bgChannel != nil){
                DispatchQueue.main.async {
                    self.bgChannel?.invokeMethod("onReceiveData", arguments: call.arguments)
                }
                result(true)
            }
        }
        return
    }
    func cleanupFlutterResources() {
        backgroundEngine?.destroyContext()
        bgChannel = nil
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
            SwiftGmoBackgroundServicePlugin.flutterPluginRegistrantCallback?(self.backgroundEngine!)
        }
        
        let binaryMessenger = self.backgroundEngine?.binaryMessenger
        self.bgChannel = FlutterMethodChannel(
            name: "gmo.flutter/background_service_bg",
            binaryMessenger: binaryMessenger!,
            codec: FlutterJSONMethodCodec()
        )
            self.bgChannel!.setMethodCallHandler({
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                let args = call.arguments as? Dictionary<String, Any>
                let callbackHandleID = args?["handle"] as? NSNumber
                let defaults = UserDefaults.standard
                defaults.set(callbackHandleID?.int64Value, forKey: "callback_handle")
                if (call.method == "backgroundTask"){
                    DispatchQueue.main.async {
                        self.beginFetch()
                    }
                }
                if( call.method == "onCancel"){
                    DispatchQueue.main.async {
                        self.beginFetch()
                        self.cleanupFlutterResources()
                    }
                }
                if (call.method == "sendData"){
                    if (self.mainChannel != nil){
                        DispatchQueue.main.async {
                            self.mainChannel?.invokeMethod("onReceiveData", arguments: call.arguments)
                        }
                    }
                }
                return;
            })
       
    }
}
