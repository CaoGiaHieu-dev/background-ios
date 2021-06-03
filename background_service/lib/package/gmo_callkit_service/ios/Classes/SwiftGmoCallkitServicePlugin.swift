//
//  SwiftGmoCallkitServicePlugin.swift
//  gmo_background_service
//
//  Created by Cao Gia Hieu on 6/1/21.
//

import Flutter
import UIKit
import UserNotifications
import AVFoundation

enum Constants: String {
    case graphqlUrl = "graphql_url"
    case ringingTimeout = "ringing_timeout"
    case ringtoneSound = "ringtoneSound"
    
}

struct defaultConfigs {
    static let graphqlUrl = "https://nodejsbun.herokuapp.com/"
    static let ringingTimeout = 15000
}

func callApi(query: String!) {
    let url = URL(string: UserDefaults.standard.string(forKey: Constants.graphqlUrl.rawValue) ?? defaultConfigs.graphqlUrl)!
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    let json: [String: Any] = ["query": query ?? ""]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    request.httpBody = jsonData
    let task = URLSession.shared.dataTask(with: request) {(data, res, e) in
        if let e = e {
            print("🍎❌ Error took place \(e)")
            return
        }
        
        if let data = data, let dataString = String(data: data, encoding: .utf8) {
           print("🍎✅ Response data string: \n \(dataString)")
        }
    }
    task.resume()
}

public class SwiftGmoCallkitServicePlugin: NSObject {
    private static var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "gmo.flutter/callkit",  binaryMessenger: registrar.messenger())
        let plugin = SwiftGmoCallkitServicePlugin(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }

    init(messenger: FlutterBinaryMessenger) {
        self.voIPCenter = GmoVoIPCenter(
            eventChannel: FlutterEventChannel(
                name: "gmo.flutter/callkit_event",
                binaryMessenger: messenger
            )
        )
        super.init()
        self.notificationCenter.delegate = self
    }
    private let voIPCenter: GmoVoIPCenter
    private let notificationCenter = UNUserNotificationCenter.current()
    private let options: UNAuthorizationOptions = [.alert]
    private func getCurrentCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(self.voIPCenter.callKitCenter.call?.toJson())
    }
    private func setConfig(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "InvalidArguments setConfig", message: nil, details: nil))
                return
        }
        let graphqlUrl = args[Constants.graphqlUrl.rawValue] as? String
        let ringingTimeout = args[Constants.ringingTimeout.rawValue] as? Int
        let ringtoneSound = args[Constants.ringtoneSound.rawValue] as? String
        if(graphqlUrl != nil) {
            UserDefaults.standard.set(graphqlUrl, forKey: Constants.graphqlUrl.rawValue)
            print("⚙✅ Saved graphqlUrl: \(graphqlUrl!)")
        }
        if(ringingTimeout != nil) {
            UserDefaults.standard.set(ringingTimeout, forKey: Constants.ringingTimeout.rawValue)
            print("⚙✅ Saved ringingTimeout: \(ringingTimeout!)")
        }
        if(ringtoneSound != nil) {
            UserDefaults.standard.set(ringtoneSound, forKey: Constants.ringtoneSound.rawValue)
            self.voIPCenter.callKitCenter.setup(delegate: self.voIPCenter)
            print("⚙✅ update ringtoneSound: \(ringtoneSound!)")
        }
        
        result(nil)
    }
    private func getIncomingCallerName(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(self.voIPCenter.callKitCenter.call?.callerName)
    }

    private func startCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let uuid = args["uuid"] as? String,
            let targetName = args["targetName"] as? String,
            let hasVideo = args["hasVideo"] as? Bool else {
                result(FlutterError(code: "InvalidArguments startCall", message: nil, details: nil))
                return
        }
        self.voIPCenter.callKitCenter.startCall(uuidString: uuid, targetName: targetName, hasVideo: hasVideo)
        result(nil)
    }

    private func endCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.voIPCenter.endCall()
        result(nil)
    }

    private func acceptIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let callerState = args["callerState"] as? String else {
                result(FlutterError(code: "InvalidArguments acceptIncomingCall", message: nil, details: nil))
                return
        }
        self.voIPCenter.callKitCenter.acceptIncomingCall(alreadyEndCallerReason: callerState == "calling" ? nil : .failed, isFromFlutter: true)
        result(nil)
    }

    private func unansweredIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let skipLocalNotification = args["skipLocalNotification"] as? Bool else {
                result(FlutterError(code: "InvalidArguments unansweredIncomingCall", message: nil, details: nil))
                return
        }

        self.voIPCenter.callKitCenter.unansweredIncomingCall()

        if (skipLocalNotification) {
            result(nil)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = args["missedCallTitle"] as? String ?? "Missed Call"
        content.body = args["missedCallBody"] as? String ?? "There was a call"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2,
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "unansweredIncomingCall",
                                            content: content,
                                            trigger: trigger)
        self.notificationCenter.add(request) { (error) in
            if let error = error {
                print("❌ unansweredIncomingCall local notification error: \(error.localizedDescription)")
            }
        }

        result(nil)
    }

    private func callConnected(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.voIPCenter.callKitCenter.callConnected()
        result(nil)
    }

    public func requestAuthLocalNotification(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        notificationCenter.requestAuthorization(options: options) { granted, error in
            if let error = error {
                result(["granted": granted, "error": error.localizedDescription])
            } else {
                result(["granted": granted])
            }
        }
    }
    
    public func getLocalNotificationsSettings(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        notificationCenter.getNotificationSettings { settings in
            result(settings)
        }
    }
    
    private func testIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let uuid = args["uuid"] as? String,
            let callerId = args["callerId"] as? String,
            let callerName = args["callerName"] as? String else {
                result(FlutterError(code: "InvalidArguments testIncomingCall", message: nil, details: nil))
                return
        }

        self.voIPCenter.callKitCenter.incomingCall(call: Call(uuid: uuid, callId: 0, callerId: callerId, callerName: callerName)) { (error) in
            if let error = error {
                print("❌ testIncomingCall error: \(error.localizedDescription)")
                result(FlutterError(code: "testIncomingCall",
                                    message: error.localizedDescription,
                                    details: nil))
                return
            }
            result(nil)
        }
    }
    
    private func enableVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        checkPermission(type: .video, call: call, result: result)
    }

    private func enableAudio(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        checkPermission(type: .audio, call: call, result: result)
    }
    
    private func checkPermission(type: AVMediaType, call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch AVCaptureDevice.authorizationStatus(for: type) {
            case .authorized:
                result(nil)
            case .denied:
                result(FlutterError(code: "checkPermission denied \(type.rawValue)",
                    message: nil,
                    details: nil))
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: type) { check in
                    print("get \(type.rawValue) permission: \(check)")
                    result(nil)
                }
            case .restricted:
                result(FlutterError(code: "checkPermission restricted \(type.rawValue)",
                    message: nil,
                    details: nil))
            @unknown default:
                result(FlutterError(code: "checkPermission unknown \(type.rawValue)",
                    message: nil,
                    details: nil))
                break
        }
    }
}

extension SwiftGmoCallkitServicePlugin: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
}

extension SwiftGmoCallkitServicePlugin: FlutterPlugin {

    private enum MethodChannel: String {
        case getCurrentCall
        case setConfig
        case getIncomingCallerName
        case startCall
        case endCall
        case acceptIncomingCall
        case unansweredIncomingCall
        case callConnected
        case testIncomingCall
        case getLocalNotificationsSettings
        case enableVideo
        case enableAudio
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = MethodChannel(rawValue: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        switch method {
            case .getCurrentCall:
                self.getCurrentCall(call, result: result)
            case .setConfig:
                self.setConfig(call, result: result)
            case .getIncomingCallerName:
                self.getIncomingCallerName(call, result: result)
            case .startCall:
                self.startCall(call, result: result)
            case .endCall:
                self.endCall(call, result: result)
            case .acceptIncomingCall:
                self.acceptIncomingCall(call, result: result)
            case .unansweredIncomingCall:
                self.unansweredIncomingCall(call, result: result)
            case .callConnected:
                self.callConnected(call, result: result)
            case .getLocalNotificationsSettings:
                self.getLocalNotificationsSettings(call, result: result)
            case .enableVideo:
                self.enableVideo(call, result: result)
            case .enableAudio:
                self.enableAudio(call, result: result)
            case .testIncomingCall:
                self.testIncomingCall(call, result: result)
        }
    }
}
