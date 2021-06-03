//
//  Notification.swift
//  flutter_background
//
//  Created by Cao Gia Hieu on 5/26/21.
//

import UserNotifications

@available(iOS 10.0, *)
class LocalNotificationManager
{
    var notifications = [Notification]()
    struct Notification {
        var id:String
        var title:String
        var datetime:DateComponents
    }
    public func initNotification(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                self.localNotification()
            } else if let error = error {
                print(error.localizedDescription)
                self.getNotificationSettings()
            }
        }
    }
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
          }
    }
    public func localNotification()
    {
        let content = UNMutableNotificationContent()
        content.title = "Feed the cat"
        content.subtitle = "It looks hungry"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:1, repeats: false)

        let request = UNNotificationRequest(identifier: "MyNotification", content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
}



