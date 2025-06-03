//
//  PetData.swift
//  WorkoutEgg
//
//  Created by Kenan Firmansyah on 01/06/25.
//

import SwiftUI
import SwiftData

// MARK: - Data Models

enum PetSpecies: String, CaseIterable, Codable {
    case fufufafa = "FUFUFAFA"
    case kikimora = "KIKIMORA"
    case bubbles = "BUBBLES"
    case sparkle = "SPARKLE"
    
    var displayName: String {
        return rawValue
    }
}

enum PetEmotion: String, CaseIterable, Codable {
    case happy = "HAPPY"
    case sad = "SAD"
    case angry = "ANGRY"
    case excited = "EXCITED"
    case sleepy = "SLEEPY"
    case tantrum = "TANTRUM"
    case content = "CONTENT"
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .happy: return .green
        case .sad: return .blue
        case .angry: return .red
        case .excited: return .yellow
        case .sleepy: return .purple
        case .tantrum: return .orange
        case .content: return .mint
        }
    }
}

enum PetStage: Int, CaseIterable, Codable {
    case egg = 0
    case baby = 1
    case child = 2
    case teen = 3
    case adult = 4
    case elder = 5
    
    var displayName: String {
        switch self {
        case .egg: return "EGG"
        case .baby: return "BABY"
        case .child: return "CHILD"
        case .teen: return "TEEN"
        case .adult: return "ADULT"
        case .elder: return "ELDER"
        }
    }
}

@Model
class PetData {
    var age: Int
    var streak: Int
    var evoPoints: Int
    var species: PetSpecies
    var stage: PetStage
    var emotion: PetEmotion
    var lastFedDate: Date
    var cumulativeCalories: Double
    var lastCalorieResetDate: Date
    var totalCaloriesConsumed: Double
    var isActive: Bool
    var createdDate: Date
    var isDead: Bool // New: Track if pet has died
    var missedDaysCount: Int // New: Track consecutive missed days
    var currentDayCalories: Double // New: Track current day's calories from HealthKit
    var currentDayFeedCount: Int // New: Track current day's feed interactions
    var lastFeedResetDate: Date // New: Track when feed count was last reset
    
    // Computed properties
    var ageInDays: String {
        return "\(age) DAYS"
    }
    
    var streakInDays: String {
        return "\(streak) DAYS"
    }
    
    var totalCaloriesString: String {
        if totalCaloriesConsumed >= 1000 {
            return String(format: "%.0fK KCAL", totalCaloriesConsumed / 1000)
        } else {
            return String(format: "%.0f KCAL", totalCaloriesConsumed)
        }
    }
    
    var petImageName: String {
        switch stage {
        case .egg:
            return "Egg/egg-2-wo-normal"
        case .baby:
            return "Pet-Test/baby-\(species.rawValue.lowercased())"
        case .child:
            return "Pet-Test/child-\(species.rawValue.lowercased())"
        case .teen:
            return "Pet-Test/teen-\(species.rawValue.lowercased())"
        case .adult:
            return "Pet-Test/adult-\(species.rawValue.lowercased())"
        case .elder:
            return "Pet-Test/elder-\(species.rawValue.lowercased())"
        }
    }
    
    init(age: Int = 0, streak: Int = 0, evoPoints: Int = 0, species: PetSpecies = .fufufafa,
         stage: PetStage = .egg, emotion: PetEmotion = .content, lastFedDate: Date = Date(),
         cumulativeCalories: Double = 0, lastCalorieResetDate: Date = Date(),
         totalCaloriesConsumed: Double = 0, isActive: Bool = true, createdDate: Date = Date(),
         isDead: Bool = false, missedDaysCount: Int = 0) {
        self.age = age
        self.streak = streak
        self.evoPoints = evoPoints
        self.species = species
        self.stage = stage
        self.emotion = emotion
        self.lastFedDate = lastFedDate
        self.cumulativeCalories = cumulativeCalories
        self.lastCalorieResetDate = lastCalorieResetDate
        self.totalCaloriesConsumed = totalCaloriesConsumed
        self.isActive = isActive
        self.createdDate = createdDate
        self.isDead = isDead
        self.missedDaysCount = missedDaysCount
        self.currentDayCalories = 0 // Initialize to 0
        self.currentDayFeedCount = 0 // Initialize to 0
        self.lastFeedResetDate = Date() // Initialize to current date
    }
    
    func updateAfterFed() {
        let calendar = Calendar.current
        let today = Date()
        
        // Only increment age and streak if the pet hasn't been fed today
        if !calendar.isDate(lastFedDate, inSameDayAs: today) {
            streak += 1
            age += 1
            lastFedDate = today
            missedDaysCount = 0
        }
        
        // Always increment today's feed count (for UI feedback)
        incrementTodayFeedCount()
        
        // Update emotion based on streak
        updateEmotion()
        
    }
    
    func calculateEvoPoints() -> Int {
        return 0
    }
    
    func addCaloriesConsumed(_ calories: Double) {
        totalCaloriesConsumed += calories
    }
    
    func checkMissedFed() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate how many days since last fed
        let daysSinceLastFed = calendar.dateComponents([.day], from: lastFedDate, to: today).day ?? 0
        
        if daysSinceLastFed > 0 {
            missedDaysCount = daysSinceLastFed
            
            if daysSinceLastFed >= 3 {
                // Pet dies after 3 days of neglect
                isDead = true
                emotion = .sad
                return true // Indicates pet died
            } else {
                // Pet is sad but still alive
                streak = 0
                emotion = .sad
            }
        }
        
        return false
    }
    
    func checkOldAge() -> Bool {
        // Pet dies of old age after reaching a certain age
        if age >= 1000 {
            isDead = true
            emotion = .sleepy
            return true
        }
        return false
    }
    
    func updateCumulativeCalories(todayCalories: Double) {
        // Store the current day's calories
        self.currentDayCalories = todayCalories
        
        let calendar = Calendar.current
        let today = Date()
        
        if !calendar.isDate(lastCalorieResetDate, inSameDayAs: today) {
            if stage == .egg {
                lastCalorieResetDate = today
            } else {
                cumulativeCalories = 0
                lastCalorieResetDate = today
            }
        }
        
        if stage == .egg {
            cumulativeCalories = getCumulativeCaloriesSinceEgg() + todayCalories
        } else {
            cumulativeCalories = todayCalories
        }
    }
    
    private func getCumulativeCaloriesSinceEgg() -> Double {
        let calendar = Calendar.current
        if calendar.isDate(lastCalorieResetDate, inSameDayAs: Date()) {
            return max(0, cumulativeCalories - getCurrentDayCalories())
        }
        return cumulativeCalories
    }
    
    private func getCurrentDayCalories() -> Double {
        return currentDayCalories
    }

    // SAMPLE CODE IMPLEMENTATION INVOLVES SWIFTDATA
    func getCurrentDayFeedCount() -> Int {
        resetFeedCountIfNewDay()
        return currentDayFeedCount
    }
    
    /// Increments the feed count for today, resetting if it's a new day
    func incrementTodayFeedCount() {
        resetFeedCountIfNewDay()
        currentDayFeedCount += 1
    }
    
    /// Resets feed count if it's a new day
    private func resetFeedCountIfNewDay() {
        let calendar = Calendar.current
        let today = Date()
        
        if !calendar.isDate(lastFeedResetDate, inSameDayAs: today) {
            currentDayFeedCount = 0
            lastFeedResetDate = today
        }
    }
    
    private func updateEmotion() {
        // Don't change emotion if pet is dead
        if isDead { return }
        
        switch streak {
        case 0...5:
            emotion = .sad
        case 6...20:
            emotion = .content
        case 21...50:
            emotion = .happy
        case 51...100:
            emotion = .excited
        default:
            emotion = .tantrum
        }
    }
    
    private func isReadyToEvolve() -> Bool {
        
        switch stage {
        case .egg:
            if cumulativeCalories >= 200 {
                return true
            }
        case .baby:
            if age >= 10 {
                return true
            }
        case .child:
            if age >= 30{
                return true
            }
        case .teen:
            if age >= 60{
                return true
            }
        case .adult:
            if age >= 100 {
                return true
            }
        case .elder:
            break
        }
        return false
    }
    
//    Commented out as I honestly don't know what this is for - Alif
//    private func checkStageEvolution() {
//        // Don't evolve if pet is dead
//        if isDead { return }
//        
//        // Check if ready to evolve and update stage accordingly
//        // Commented out for now to avoid evolving automatically
//        // if isReadyToEvolve() {
//        //     switch stage {
//        //     case .egg:
//        //         stage = .baby
//        //     case .baby:
//        //         stage = .child
//        //     case .child:
//        //         stage = .teen
//        //     case .teen:
//        //         stage = .adult
//        //     case .adult:
//        //         stage = .elder
//        //     case .elder:
//        //         // Already at max stage
//        //         break
//        //     }
//        // }
//    }
    
    // MARK: - Development/Testing Methods
    
    /// Forces the pet to evolve to the next stage by setting age to the minimum required
    /// This is for development/testing purposes
    func forceEvolveToNextStage() {
        // Don't evolve if pet is dead
        if isDead { return }
        
        let previousStage = stage
        
        // Force evolution to next stage (bypassing normal requirements)
        switch stage {
        case .egg:
            stage = .baby
            // Set minimum age for baby stage
            age = max(age, 11)
        case .baby:
            stage = .child
            // Set minimum age for child stage
            age = max(age, 51)
        case .child:
            stage = .teen
            // Set minimum age for teen stage
            age = max(age, 151)
        case .teen:
            stage = .adult
            // Set minimum age for adult stage
            age = max(age, 301)
        case .adult:
            stage = .elder
            // Set minimum age for elder stage
            age = max(age, 501)
        case .elder:
            // Already at max stage, do nothing
            DebugConfig.debugPrint("🦴 Pet is already at elder stage (max)")
            return
        }
        
        // Update emotion based on current streak
        updateEmotion()
        
        DebugConfig.debugPrint("🚀 Force evolved from \(previousStage.displayName) to \(stage.displayName)")
        DebugConfig.debugPrint("📅 Age set to: \(age)")
    }
}

@Model
class LongestLivedPetData {
    var age: Int
    var species: PetSpecies
    var stage: PetStage
    var emotion: PetEmotion
    var totalCaloriesConsumed: Double
    var finalStreak: Int
    var createdDate: Date
    var diedDate: Date
    var causeOfDeath: String // "evolved", "neglected", "old_age", etc.
    
    // Computed properties
    var ageInDays: String {
        return "\(age) DAYS"
    }
    
    var totalCaloriesString: String {
        if totalCaloriesConsumed >= 1000 {
            return String(format: "%.0fK KCAL", totalCaloriesConsumed / 1000)
        } else {
            return String(format: "%.0f KCAL", totalCaloriesConsumed)
        }
    }
    
    var petImageName: String {
        switch stage {
        case .egg:
            return "Egg/egg-2-wo-normal"
        case .baby:
            return "Pet/baby-\(species.rawValue.lowercased())"
        case .child:
            return "Pet/child-\(species.rawValue.lowercased())"
        case .teen:
            return "Pet/teen-\(species.rawValue.lowercased())"
        case .adult:
            return "Pet/adult-\(species.rawValue.lowercased())"
        case .elder:
            return "Pet/elder-\(species.rawValue.lowercased())"
        }
    }
    
    var lifespan: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: createdDate)) - \(formatter.string(from: diedDate))"
    }
    
    init(age: Int, species: PetSpecies, stage: PetStage, emotion: PetEmotion,
         totalCaloriesConsumed: Double, finalStreak: Int, createdDate: Date,
         diedDate: Date = Date(), causeOfDeath: String = "unknown") {
        self.age = age
        self.species = species
        self.stage = stage
        self.emotion = emotion
        self.totalCaloriesConsumed = totalCaloriesConsumed
        self.finalStreak = finalStreak
        self.createdDate = createdDate
        self.diedDate = diedDate
        self.causeOfDeath = causeOfDeath
    }
    
    // Create from current PetData
    convenience init(from petData: PetData, causeOfDeath: String = "unknown") {
        self.init(
            age: petData.age,
            species: petData.species,
            stage: petData.stage,
            emotion: petData.emotion,
            totalCaloriesConsumed: petData.totalCaloriesConsumed,
            finalStreak: petData.streak,
            createdDate: petData.createdDate,
            diedDate: Date(),
            causeOfDeath: causeOfDeath
        )
    }
}

