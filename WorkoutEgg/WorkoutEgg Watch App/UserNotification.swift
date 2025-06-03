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
        DebugConfig.debugPrint("=== Starting Notification Permission Check ===")
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DebugConfig.debugPrint("Current notification settings: \(settings.authorizationStatus.rawValue)")
            DebugConfig.debugPrint("Alert setting: \(settings.alertSetting.rawValue)")
            DebugConfig.debugPrint("Sound setting: \(settings.soundSetting.rawValue)")
            
            // Only request if not determined
            if settings.authorizationStatus == .notDetermined {
                DebugConfig.debugPrint("Status is not determined, requesting authorization...")
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            DebugConfig.debugPrint("✅ Notification permission granted successfully")
                            // Register notification categories
                            registerNotificationCategories()
                            // Schedule the reminder notification
                            sendReminderNotification()
                        } else {
                            if let error = error {
                                DebugConfig.debugPrint("❌ Notification permission denied with error: \(error.localizedDescription)")
                            } else {
                                DebugConfig.debugPrint("❌ Notification permission denied without specific error")
                            }
                        }
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                DebugConfig.debugPrint("✅ Notification permission already granted")
                // Register notification categories and schedule
                registerNotificationCategories()
                sendReminderNotification()
            } else {
                DebugConfig.debugPrint("❌ Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    static func registerNotificationCategories() {
        DebugConfig.debugPrint("Registering notification categories...")
        
        // Define categories if needed (for action buttons)
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([workoutCategory])
        DebugConfig.debugPrint("Notification categories registered")
    }
    
    static func sendReminderNotification() {
        // Cancel any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "🥚 Your pet is waiting!"
        content.body = "Don't forget to exercise and feed your virtual pet today. Keep your streak alive!"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        
        DebugConfig.debugPrint("Scheduling daily reminder notification...")
        
        // Schedule for 8:00 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 20  // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    DebugConfig.debugPrint("❌ Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    DebugConfig.debugPrint("✅ Daily notification scheduled successfully for 8:00 PM")
                    
                    // Debug: Print pending notifications
                    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                        DebugConfig.debugPrint("Currently scheduled notifications: \(requests.count)")
                        for request in requests {
                            DebugConfig.debugPrint("Notification ID: \(request.identifier)")
                            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                                DebugConfig.debugPrint("Next trigger date: \(trigger.nextTriggerDate()?.description ?? "unknown")")
                            }
                        }
                    }
                }
            }
        }
    }
    
    static func getCustomizedMessage(calories: Int) {
        currentCalories = calories
        
        var encouragementMessage: String
        
        if calories < 100 {
            encouragementMessage = "🐣 Your egg is waiting! Every step counts toward hatching your pet."
        } else if calories < 200 {
            encouragementMessage = "🥚 Great start! Your pet is getting stronger with each calorie burned."
        } else if calories < 400 {
            encouragementMessage = "🔥 You're on fire! Your pet is almost ready for the next stage."
        } else {
            encouragementMessage = "⭐ Amazing work! Your pet is thriving thanks to your dedication."
        }
        
        // You can use this message for immediate notifications or store it for later use
        // For now, we'll just update the stored message
    }
}
