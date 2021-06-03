//
//  GmoVoIPCenter.swift
//  gmo_background_service
//
//  Created by Cao Gia Hieu on 6/1/21.
//

import Foundation
import Flutter
import PushKit
import CallKit
import AVFoundation

extension String {
    internal init(deviceToken: Data) {
        self = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
    }
}

class GmoVoIPCenter: NSObject {
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    private enum EventChannel: String {
        case onDidReceiveIncomingPush
        case onDidAcceptIncomingCall
        case onDidRejectIncomingCall
        
        case onDidEndCall
        case onDidUpdatePushToken
        case onDidActivateAudioSession
        case onDidDeactivateAudioSession
        case onOtherUserDidJoinRoom
        case onOtherUserDidLeftRoom
        case onDidJoinRoom
    }
    private let didUpdateTokenKey = "Did_Update_VoIP_Device_Token"
    private let pushRegistry: PKPushRegistry

    var token: String? {
        if let didUpdateDeviceToken = UserDefaults.standard.data(forKey: didUpdateTokenKey) {
            let token = String(deviceToken: didUpdateDeviceToken)
            print("🎈 VoIP didUpdateDeviceToken: \(token)")
            return token
        }

        guard let cacheDeviceToken = self.pushRegistry.pushToken(for: .voIP) else {
            print("❌ VoIP null token")
            return nil
        }

        let token = String(deviceToken: cacheDeviceToken)
        print("🎈 VoIP cacheDeviceToken: \(token)")
        return token
    }
    let callKitCenter: GmoCallKit
    fileprivate var audioSessionMode: AVAudioSession.Mode
    fileprivate let ioBufferDuration: TimeInterval
    fileprivate let audioSampleRate: Double

    init(eventChannel: FlutterEventChannel) {
        self.eventChannel = eventChannel
        self.pushRegistry = PKPushRegistry(queue: .main)
        self.pushRegistry.desiredPushTypes = [.voIP]
        self.callKitCenter = GmoCallKit()
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"), let plist = NSDictionary(contentsOfFile: path) {
            self.audioSessionMode = ((plist["FIVKAudioSessionMode"] as? String) ?? "audio") == "video" ? .videoChat : .voiceChat
            self.ioBufferDuration = plist["FIVKIOBufferDuration"] as? TimeInterval ?? 0.005
            self.audioSampleRate = plist["FIVKAudioSampleRate"] as? Double ?? 44100.0
        } else {
            self.audioSessionMode = .voiceChat
            self.ioBufferDuration = TimeInterval(0.005)
            self.audioSampleRate = 44100.0
        }
        
        super.init()
        self.eventChannel.setStreamHandler(self)
        self.pushRegistry.delegate = self
        self.callKitCenter.setup(delegate: self)
    }
}

extension GmoVoIPCenter: PKPushRegistryDelegate {
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("🎈 VoIP didUpdate pushCredentials")
        UserDefaults.standard.set(pushCredentials.token, forKey: didUpdateTokenKey)
        
        self.eventSink?(["event": EventChannel.onDidUpdatePushToken.rawValue,
                         "token": pushCredentials.token])
    }
    @available(iOS 11.0, *)
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("🎈 VoIP didReceiveIncomingPushWith completion: \(payload.dictionaryPayload)")
        
        if (self.isEndCall(payload: payload)) {
            if(!self.callKitCenter.IsCallConnected) {
                self.callKitCenter.unansweredIncomingCall()
            } else {
                self.endCall()
            }
        } else {
            let call = self.fromJson(payload: payload)
            self.callKitCenter.incomingCall(call: call!) { error in
                if let error = error {
                    print("❌ reportNewIncomingCall error: \(error.localizedDescription)")
                    return
                }
                self.eventSink?(["event": EventChannel.onDidReceiveIncomingPush.rawValue,
                                 "call": call?.toJson() as Any])
                completion()
            }
            waitForReportMissingCall()
        }
    }
    
    @available(iOS 10.0, *)
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("🎈 VoIP didReceiveIncomingPushWith: \(payload.dictionaryPayload)")

        if (self.isEndCall(payload: payload)) {
            if(!self.callKitCenter.IsCallConnected) {
                self.callKitCenter.unansweredIncomingCall()
            } else {
                self.endCall()
            }
        } else {
            let call = self.fromJson(payload: payload)
            self.callKitCenter.incomingCall(call: call!) { error in
                if let error = error {
                    print("❌ reportNewIncomingCall error: \(error.localizedDescription)")
                    return
                }
                self.eventSink?(["event": EventChannel.onDidReceiveIncomingPush.rawValue,
                                 "call": call?.toJson() as Any])
            }
            waitForReportMissingCall()
        }
    }
    
    public func endCall() {
        let call = self.callKitCenter.call;
        self.callKitCenter.endCall();
        self.eventSink?(["event": EventChannel.onDidEndCall.rawValue,
                         "call": call?.toJson() as Any])
    }
    
    private func waitForReportMissingCall() {
        let ringingTimeout = UserDefaults.standard.integer(forKey: Constants.ringingTimeout.rawValue);
        let dispatchAfter = DispatchTimeInterval.seconds((ringingTimeout > 0 ? ringingTimeout : defaultConfigs.ringingTimeout) / 1000)
        DispatchQueue.main.asyncAfter(deadline: .now() + dispatchAfter, execute: {
            if(!self.callKitCenter.IsCallConnected) {
                print("❌ ringing timeout: \(ringingTimeout)")
                self.callKitCenter.unansweredIncomingCall()
            }
        })
    }
    
    private func fromJson(payload: PKPushPayload) -> Call? {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload.dictionaryPayload, options: .prettyPrinted)
            let info = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return Call.fromJson(json: info)
        } catch let error as NSError {
            print("❌ VoIP fromJson parsePayload: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func isEndCall(payload: PKPushPayload) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload.dictionaryPayload, options: .prettyPrinted)
            let info = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return info?["end_call_id"] != nil
        } catch let error as NSError {
            print("❌ VoIP isEndCall parsePayload: \(error.localizedDescription)")
            return false
        }
    }
}

extension GmoVoIPCenter: CXProviderDelegate {
    public func providerDidReset(_ provider: CXProvider) {
        print("🚫 VoIP providerDidReset")
    }
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("🤙 VoIP CXStartCallAction")
        self.callKitCenter.connectingOutgoingCall()
        action.fulfill()
    }
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("✅ VoIP CXAnswerCallAction")
        self.callKitCenter.answerCallAction = action
        self.configureAudioSession()
        self.callKitCenter.acceptIncomingCall(alreadyEndCallerReason: nil, isFromFlutter: false)
        self.eventSink?(["event": EventChannel.onDidAcceptIncomingCall.rawValue,
                         "call": self.callKitCenter.call?.toJson() as Any])
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("❎ VoIP CXEndCallAction")
        if (self.callKitCenter.isCalleeBeforeAcceptIncomingCall) {
            self.eventSink?(["event": EventChannel.onDidRejectIncomingCall.rawValue,
                             "call": self.callKitCenter.call?.toJson() as Any])
        }
        
        self.callKitCenter.disconnected(reason: .remoteEnded)
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        self.eventSink?(["event": EventChannel.onDidActivateAudioSession.rawValue])
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("🔇 VoIP didDeactivate audioSession")
        self.eventSink?(["event": EventChannel.onDidDeactivateAudioSession.rawValue])
    }
    
    // This is a workaround for known issue, when audio doesn't start from lockscreen call
    // https://stackoverflow.com/questions/55391026/no-sound-after-connecting-to-webrtc-when-app-is-launched-in-background-using-pus
    private func configureAudioSession() {
        let sharedSession = AVAudioSession.sharedInstance()
        do {
            try sharedSession.setCategory(.playAndRecord,
                                          options: [AVAudioSession.CategoryOptions.allowBluetooth,
                                                    AVAudioSession.CategoryOptions.defaultToSpeaker])
            try sharedSession.setMode(audioSessionMode)
            try sharedSession.setPreferredIOBufferDuration(ioBufferDuration)
            try sharedSession.setPreferredSampleRate(audioSampleRate)
        } catch {
            print("❌ VoIP Failed to configure `AVAudioSession`")
        }
    }
}

extension GmoVoIPCenter: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
