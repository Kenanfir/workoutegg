//
//  UserNotification.swift
//  WorkoutEgg
//
//  Created by Putu Swami Indira Dewi on 31/05/25.
//

import Foundation
import UserNotifications

// MARK: - Notification Delegate (Required for foreground notifications)

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // This method is called when a notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when app is in foreground
        completionHandler([.banner, .sound])
        DebugConfig.debugPrint(
            "📬 Notification shown in foreground: \(notification.request.identifier)")
    }

    // This method is called when user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DebugConfig.debugPrint(
            "👆 User tapped notification: \(response.notification.request.identifier)")
        completionHandler()
    }
}

// MARK: - Notification Manager

class NotificationManager {
    static var currentCalories: Int = 0

    // MARK: - Permission & Setup

    static func requestPermission() {
        // Set up delegate first - required for foreground notifications
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        DebugConfig.debugPrint("=== Starting Notification Permission Check ===")
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DebugConfig.debugPrint(
                "Current notification settings: \(settings.authorizationStatus.rawValue)")

            if settings.authorizationStatus == .notDetermined {
                DebugConfig.debugPrint("Status is not determined, requesting authorization...")
                UNUserNotificationCenter.current().requestAuthorization(options: [
                    .alert, .sound, .badge,
                ]) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            DebugConfig.debugPrint("✅ Notification permission granted successfully")
                            registerNotificationCategories()
                            sendDailyReminderNotification()
                        } else {
                            DebugConfig.debugPrint(
                                "❌ Notification permission denied: \(error?.localizedDescription ?? "unknown")"
                            )
                        }
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                DebugConfig.debugPrint("✅ Notification permission already granted")
                registerNotificationCategories()
                sendDailyReminderNotification()
            } else {
                DebugConfig.debugPrint(
                    "❌ Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }

    /// Sends a test notification immediately (3 seconds delay) to verify notifications work
    static func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "If you see this, notifications are working!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint("❌ Test notification failed: \(error.localizedDescription)")
            } else {
                DebugConfig.debugPrint("✅ Test notification scheduled (3 seconds)")
            }
        }
    }

    static func registerNotificationCategories() {
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(
                identifier: "WORKOUT_REMINDER", actions: [], intentIdentifiers: [],
                options: .customDismissAction),
            UNNotificationCategory(
                identifier: "EVOLUTION_READY", actions: [], intentIdentifiers: [],
                options: .customDismissAction),
            UNNotificationCategory(
                identifier: "NEGLECT_WARNING", actions: [], intentIdentifiers: [],
                options: .customDismissAction),
            UNNotificationCategory(
                identifier: "PET_DEATH", actions: [], intentIdentifiers: [],
                options: .customDismissAction),
            UNNotificationCategory(
                identifier: "STREAK_MILESTONE", actions: [], intentIdentifiers: [],
                options: .customDismissAction),
            UNNotificationCategory(
                identifier: "CALORIE_MILESTONE", actions: [], intentIdentifiers: [],
                options: .customDismissAction),
        ]
        UNUserNotificationCenter.current().setNotificationCategories(categories)
        DebugConfig.debugPrint("Notification categories registered")
    }

    // MARK: - Daily Reminder (8 PM)

    static func sendDailyReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🥚 Your pet is waiting!"
        content.body =
            "Don't forget to exercise and feed your virtual pet today. Keep your streak alive!"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = 20  // 8 PM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint(
                    "❌ Failed to schedule daily reminder: \(error.localizedDescription)")
            } else {
                DebugConfig.debugPrint("✅ Daily reminder scheduled for 8:00 PM")
            }
        }
    }

    // MARK: - Evolution Ready Notification

    static func sendEvolutionReadyNotification(currentStage: String) {
        let content = UNMutableNotificationContent()
        content.title = "🌟 Evolution Ready!"
        content.body =
            "Your \(currentStage) pet is ready to evolve! Open the app to witness the transformation!"
        content.sound = .default
        content.categoryIdentifier = "EVOLUTION_READY"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "evolution_ready_\(Date().timeIntervalSince1970)", content: content,
            trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint(
                    "❌ Failed to send evolution notification: \(error.localizedDescription)")
            } else {
                DebugConfig.debugPrint("✅ Evolution ready notification sent")
            }
        }
    }

    // MARK: - Neglect Warning Notifications

    static func sendNeglectWarningNotification(daysMissed: Int) {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "NEGLECT_WARNING"
        content.sound = .default

        switch daysMissed {
        case 1:
            content.title = "😟 Your pet misses you!"
            content.body = "It's been a day since you last fed your pet. They're getting hungry!"
        case 2:
            content.title = "🚨 Your pet is weak!"
            content.body = "It's been 2 days! Feed your pet soon or they might not make it..."
        default:
            return  // Only send for day 1 and 2
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "neglect_warning_day\(daysMissed)_\(Date().timeIntervalSince1970)",
            content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint(
                    "❌ Failed to send neglect warning: \(error.localizedDescription)")
            } else {
                DebugConfig.debugPrint("✅ Neglect warning (Day \(daysMissed)) notification sent")
            }
        }
    }

    // MARK: - Pet Death Notification

    static func sendPetDeathNotification(causeOfDeath: String, petAge: Int) {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "PET_DEATH"
        content.sound = .default

        if causeOfDeath == "neglected" {
            content.title = "💔 Your pet has passed away"
            content.body =
                "Your pet lived for \(petAge) days but died from neglect. Start fresh with a new egg!"
        } else {
            content.title = "🌈 Your pet lived a full life"
            content.body =
                "Your pet lived an amazing \(petAge) days! Time to raise a new companion."
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pet_death_\(Date().timeIntervalSince1970)", content: content,
            trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint(
                    "❌ Failed to send death notification: \(error.localizedDescription)")
            } else {
                DebugConfig.debugPrint("✅ Pet death notification sent")
            }
        }
    }

    // MARK: - Streak Milestone Notification

    static func sendStreakMilestoneNotification(streak: Int) {
        let milestones = [7, 14, 30, 50, 100, 200, 365]
        guard milestones.contains(streak) else { return }

        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak Milestone!"
        content.body = "Amazing! You've maintained a \(streak)-day streak! Your pet is thriving!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_MILESTONE"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_milestone_\(streak)_\(Date().timeIntervalSince1970)",
            content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint(
                    "❌ Failed to send streak notification: \(error.localizedDescription)")
            } else {
                DebugConfig.debugPrint("✅ Streak milestone (\(streak) days) notification sent")
            }
        }
    }

    // MARK: - Calorie Milestone Notification

    static func sendCalorieMilestoneNotification(calories: Int, isEgg: Bool) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "CALORIE_MILESTONE"

        if isEgg {
            if calories >= 200 {
                content.title = "🥚 Your egg is ready to hatch!"
                content.body = "You've burned \(calories) calories! Open the app to hatch your pet!"
            } else if calories >= 100 {
                content.title = "🥚 Your egg is wiggling!"
                content.body = "You've burned \(calories) calories! Keep going to hatch your pet!"
            } else {
                return  // Don't notify for low calories
            }
        } else {
            if calories >= 600 {
                content.title = "🔥 All food unlocked!"
                content.body = "You've burned \(calories)+ calories! Your pet has a feast waiting!"
            } else if calories >= 400 {
                content.title = "🔥 More food available!"
                content.body =
                    "You've burned \(calories) calories! 2 food items are ready for your pet!"
            } else if calories >= 200 {
                content.title = "🍎 Food is ready!"
                content.body = "You've burned \(calories) calories! Your pet has food waiting!"
            } else {
                return
            }
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "calorie_milestone_\(calories)_\(Date().timeIntervalSince1970)",
            content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint(
                    "❌ Failed to send calorie notification: \(error.localizedDescription)")
            } else {
                DebugConfig.debugPrint("✅ Calorie milestone (\(calories) kcal) notification sent")
            }
        }
    }

    // MARK: - Evolution Completed Notification

    static func sendEvolutionCompletedNotification(newStage: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Evolution Complete!"
        content.body =
            "Congratulations! Your pet has evolved to \(newStage)! Keep up the great work!"
        content.sound = .default
        content.categoryIdentifier = "EVOLUTION_READY"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "evolution_completed_\(Date().timeIntervalSince1970)", content: content,
            trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugConfig.debugPrint(
                    "❌ Failed to send evolution completed notification: \(error.localizedDescription)"
                )
            } else {
                DebugConfig.debugPrint("✅ Evolution completed notification sent")
            }
        }
    }
}
