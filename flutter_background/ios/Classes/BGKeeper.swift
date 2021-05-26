//
//  BGKeeper.swift
//  flutter_background
//
//  Created by Cao Gia Hieu on 5/26/21.
//

import Foundation

struct BGKeeper {
    
    private static let userDefaults = UserDefaults(suiteName: "BGKeeper")!
    
    enum Key {
        case callbackHandle
        var stringValue: String {
            return "(self)"
        }
    }
    static func storeCallbackHandle(_ handle: Int64) {
       store(handle, key: .callbackHandle)
    }

    static func getStoredCallbackHandle() -> Int64? {
        return getValue(for: .callbackHandle)
    }
    
    private static func store<T>(_ value: T, key: Key) {
        userDefaults.setValue(value, forKey: key.stringValue)
    }

    private static func getValue<T>(for key: Key) -> T? {
        return userDefaults.value(forKey: key.stringValue) as? T
    }
    
}
