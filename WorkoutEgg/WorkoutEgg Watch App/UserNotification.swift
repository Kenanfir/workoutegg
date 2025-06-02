//
//  UserNotification.swift
//  WorkoutEgg
//
//  Created by Putu Swami Indira Dewi on 31/05/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static var currentCalories: Int = 0
    
    static func requestPermission(){
        print("=== Starting Notification Permission Check ===")
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Current notification settings: \(settings.authorizationStatus.rawValue)")
            print("Alert setting: \(settings.alertSetting.rawValue)")
            print("Sound setting: \(settings.soundSetting.rawValue)")
            
            // Only request if not determined
            if settings.authorizationStatus == .notDetermined {
                print("Status is not determined, requesting authorization...")
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            print("✅ Notification permission granted successfully")
                            // Register notification categories
                            registerNotificationCategories()
                            // Schedule the reminder notification
                            sendReminderNotification()
                        } else {
                            if let error = error {
                                print("❌ Notification permission denied with error: \(error.localizedDescription)")
                            } else {
                                print("❌ Notification permission denied without specific error")
                            }
                        }
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                print("✅ Notification permission already granted")
                registerNotificationCategories()
                sendReminderNotification()
            } else {
                print("❌ Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    private static func registerNotificationCategories() {
        print("Registering notification categories...")
        let category = UNNotificationCategory(
            identifier: "CALORIE_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("Notification categories registered")
    }
    
    static func getCustomizedMessage(calories: Int) -> String {
        currentCalories = calories  // Update the stored calories
        if calories >= 400 {
            return "Hey! I get hungry, there are some foods on the next screen!"
        } else {
            return "Grrrr, I'm hungry!"
        }
    }
    
    static func sendReminderNotification() {
        print("Scheduling daily reminder notification...")
        let content = UNMutableNotificationContent()
        content.title = "Fufufafa need you"
        content.body = getCustomizedMessage(calories: currentCalories)
        content.sound = .default
        content.categoryIdentifier = "CALORIE_REMINDER"
        content.interruptionLevel = .timeSensitive
        
        // Create date components for daily notification
        var dateComponents = DateComponents()
        dateComponents.hour = 16  // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyCalorieReminder", content: content, trigger: trigger)
        
        // First, remove any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Daily notification scheduled successfully for 8:00 PM")
                
                // Verify the notification was scheduled
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("Currently scheduled notifications: \(requests.count)")
                    for request in requests {
                        print("Notification ID: \(request.identifier)")
                        if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                            print("Next trigger date: \(trigger.nextTriggerDate()?.description ?? "unknown")")
                        }
                    }
                }
            }
        }
    }
}
