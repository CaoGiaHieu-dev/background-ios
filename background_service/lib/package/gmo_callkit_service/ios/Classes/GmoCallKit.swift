//
//  GmoCallKit.swift
//  gmo_background_service
//
//  Created by Cao Gia Hieu on 6/1/21.
//

import AVFoundation
import CallKit
import UIKit

struct Call {
    var uuid: String
    var callId: Int
    var callerId: String
    var callerName: String
}

extension Call {
    func toJson() -> NSDictionary! {
        let json: NSMutableDictionary! = NSMutableDictionary();
        
        json["uuid"] = self.uuid
        json["callId"] = self.callId
        json["callerId"] = self.callerId
        json["callerName"] = self.callerName
        
        return json
    }
    
    static func fromJson(json: [String: Any]!) -> Call! {
        return Call(
            uuid: json?["uuid"] as! String,
            callId: json?["call_id"] as! Int,
            callerId: json?["incoming_caller_id"] as! String,
            callerName: json?["incoming_caller_name"] as! String
        )
    }
}

class GmoCallKit : NSObject {
    private let controller = CXCallController()
    private let iconName: String
    private let localizedName: String
    private let supportVideo: Bool
    private let skipRecallScreen: Bool
    private var provider: CXProvider?
    private var uuid = UUID()
    private(set) var call: Call?
    private var isReceivedIncomingCall: Bool = false
    private var isCallConnected: Bool = false
    private var maximumCallGroups: Int = 1
    var answerCallAction: CXAnswerCallAction?
    var IsCallConnected: Bool {
        get {return isCallConnected}
    }

    var isCalleeBeforeAcceptIncomingCall: Bool {
        return self.isReceivedIncomingCall && !self.isCallConnected
    }
    override init() {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let plist = NSDictionary(contentsOfFile: path)
            self.iconName = plist?["FIVKIconName"] as? String ?? "AppIcon-VoIPKit"
            self.localizedName = plist?["FIVKLocalizedName"] as? String ?? "App Name"
            self.supportVideo = plist?["FIVKSupportVideo"] as? Bool ?? false
            self.skipRecallScreen = plist?["FIVKSkipRecallScreen"] as? Bool ?? false
            self.maximumCallGroups = plist?["FIVKMaximumCallGroups"] as? Int ?? 1
        } else {
            self.iconName = "AppIcon-VoIPKit"
            self.localizedName = "Free Calling"
            self.supportVideo = false
            self.skipRecallScreen = false
        }
        super.init()
    }
    func setup(delegate: CXProviderDelegate) {
        let providerConfiguration = CXProviderConfiguration(localizedName: self.localizedName)
        providerConfiguration.supportsVideo = self.supportVideo
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = maximumCallGroups
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.iconTemplateImageData = UIImage(named: self.iconName)?.pngData()
        providerConfiguration.ringtoneSound = UserDefaults.standard.string(forKey: Constants.ringtoneSound.rawValue)
        self.provider = CXProvider(configuration: providerConfiguration)
        self.provider?.setDelegate(delegate, queue: nil)
    }
    func startCall(uuidString: String, targetName: String, hasVideo: Bool?) {
        self.uuid = UUID(uuidString: uuidString)!
        let handle = CXHandle(type: .generic, value: targetName)
        let startCallAction = CXStartCallAction(call: self.uuid, handle: handle)
        startCallAction.isVideo = hasVideo ?? self.supportVideo
        let transaction = CXTransaction(action: startCallAction)
        self.controller.request(transaction) { error in
            if let error = error {
                print("❌ CXStartCallAction error: \(error.localizedDescription)")
            }
        }
    }

    func incomingCall(call: Call, completion: @escaping (Error?) -> Void) {
        self.call = call
        self.isReceivedIncomingCall = true

        self.uuid = UUID(uuidString: call.uuid)!
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: call.callerName)
        update.hasVideo = self.supportVideo
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = true
        self.provider?.reportNewIncomingCall(with: self.uuid, update: update, completion: { error in
            if (error == nil) {
                self.connectedOutgoingCall()
            }

            completion(error)
        })
    }

    func acceptIncomingCall(alreadyEndCallerReason: CXCallEndedReason?, isFromFlutter: Bool?) {
        guard alreadyEndCallerReason == nil else {
            self.skipRecallScreen ? self.answerCallAction?.fulfill() : self.answerCallAction?.fail()
            self.answerCallAction = nil
            return
        }

        self.answerCallAction?.fulfill()
        self.answerCallAction = nil
        callApi(query: "mutation { acceptCall (callId:\(self.call?.callId ?? 0) ) }")
        callConnected()
    }
    func unansweredIncomingCall() {
        self.disconnected(reason: .unanswered)
    }

    func endCall() {
        print("🔚 CallkitCenter endCall")
        let endCallAction = CXEndCallAction(call: self.uuid)
        let transaction = CXTransaction(action: endCallAction)
        self.controller.request(transaction) { error in
            if let error = error {
                print("❌ CXEndCallAction error: \(error.localizedDescription)")
            }
        }
        disconnected(reason: .declinedElsewhere)
    }

    func callConnected() {
        self.isCallConnected = true
    }

    func connectingOutgoingCall() {
        self.provider?.reportOutgoingCall(with: self.uuid, startedConnectingAt: nil)
    }

    private func connectedOutgoingCall() {
        self.provider?.reportOutgoingCall(with: self.uuid, connectedAt: nil)
    }

    func disconnected(reason: CXCallEndedReason) {
        print("💔 CallkitCenter disconnect.")
        self.call = nil
        self.answerCallAction = nil
        self.isReceivedIncomingCall = false
        self.isCallConnected = false

        self.provider?.reportCall(with: self.uuid, endedAt: nil, reason: reason)
    }
}
