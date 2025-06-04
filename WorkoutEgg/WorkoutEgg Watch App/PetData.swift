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
    case kikimora = "KIKIMORA"
    case fufufafa = "FUFUFAFA"
    case bubbles = "BUBBLES"
    case sparkle = "SPARKLE"
    
    var displayName: String {
        return rawValue
    }
    
    var camelCaseName: String {
        switch self {
        case .kikimora: return "Kikimora"
        case .fufufafa: return "Fufufafa"
        case .bubbles: return "Bubbles"
        case .sparkle: return "Sparkle"
        }
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
    
    var camelCaseName: String {
        switch self {
        case .happy: return "Happy"
        case .sad: return "Sad"
        case .angry: return "Angry"
        case .excited: return "Excited"
        case .sleepy: return "Sleepy"
        case .tantrum: return "Tantrum"
        case .content: return "Content"
        }
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
    
    var camelCaseName: String {
        switch self {
        case .egg: return "Egg"
        case .baby: return "Baby"
        case .child: return "Child"
        case .teen: return "Teen"
        case .adult: return "Adult"
        case .elder: return "Elder"
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
        case .baby, .child, .teen, .adult, .elder:
            // For animated pets, return frame 1 as the default static image
            return "Pet/\(species.camelCaseName)\(stage.camelCaseName)\(emotion.camelCaseName)IdleFr1"
        }
    }
    
    /// Returns all animation frame paths for the current pet state (for idle animation)
    var petAnimationFrames: [String] {
        switch stage {
        case .egg:
            // Eggs don't have animation frames, return single static image
            return ["Egg/egg-2-wo-normal"]
        case .baby, .child, .teen, .adult, .elder:
            // Return all 4 animation frames for idle animation
            return (1...4).map { frameNumber in
                "Pet/\(species.camelCaseName)\(stage.camelCaseName)\(emotion.camelCaseName)IdleFr\(frameNumber)"
            }
        }
    }
    
    /// Returns all tapped animation frame paths for the current pet state
    var petTappedAnimationFrames: [String] {
        switch stage {
        case .egg:
            // Eggs don't have tapped animation frames, return single static image
            return ["Egg/egg-2-wo-normal"]
        case .baby, .child, .teen, .adult, .elder:
            // Return all 4 animation frames for tapped animation
            return (1...4).map { frameNumber in
                "Pet/\(species.camelCaseName)\(stage.camelCaseName)\(emotion.camelCaseName)TappedFr\(frameNumber)"
            }
        }
    }
    
    /// Returns a specific animation frame for the current pet state
    func getPetAnimationFrame(_ frameNumber: Int) -> String {
        switch stage {
        case .egg:
            return "Egg/egg-2-wo-normal"
        case .baby, .child, .teen, .adult, .elder:
            let clampedFrame = max(1, min(4, frameNumber)) // Ensure frame is between 1-4
            return "Pet/\(species.camelCaseName)\(stage.camelCaseName)\(emotion.camelCaseName)IdleFr\(clampedFrame)"
        }
    }
    
    /// Returns a specific tapped animation frame for the current pet state
    func getPetTappedAnimationFrame(_ frameNumber: Int) -> String {
        switch stage {
        case .egg:
            return "Egg/egg-2-wo-normal"
        case .baby, .child, .teen, .adult, .elder:
            let clampedFrame = max(1, min(4, frameNumber)) // Ensure frame is between 1-4
            return "Pet/\(species.camelCaseName)\(stage.camelCaseName)\(emotion.camelCaseName)TappedFr\(clampedFrame)"
        }
    }
    
    init(age: Int = 1, streak: Int = 0, evoPoints: Int = 0, species: PetSpecies = .kikimora,
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
                // Pet missed some days but still alive - reset streak and update emotion based on new streak
                streak = 0
                updateEmotion() // Use the emotion logic based on current streak
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
    
    func updateCumulativeCalories(todayCalories: Double, cumulativeCalories: Double? = nil) {
        // Store the current day's calories
        self.currentDayCalories = todayCalories
        
        let calendar = Calendar.current
        let today = Date()
        
        DebugConfig.debugPrint("🔄 PetData updateCumulativeCalories:")
        DebugConfig.debugPrint("   - Stage: \(stage.displayName)")
        DebugConfig.debugPrint("   - todayCalories: \(todayCalories)")
        DebugConfig.debugPrint("   - cumulativeCalories param: \(cumulativeCalories ?? -1)")
        DebugConfig.debugPrint("   - Current pet cumulativeCalories: \(self.cumulativeCalories)")
        DebugConfig.debugPrint("   - Current totalCaloriesConsumed: \(self.totalCaloriesConsumed)")
        DebugConfig.debugPrint("   - Setting currentDayCalories to: \(todayCalories)")
        
        if !calendar.isDate(lastCalorieResetDate, inSameDayAs: today) {
            if stage == .egg {
                lastCalorieResetDate = today
            } else {
                self.cumulativeCalories = 0
                lastCalorieResetDate = today
            }
        }
        
        if stage == .egg {
            // For egg stage, use the cumulative calories directly from HealthKit if provided
            // BUT do NOT update totalCaloriesConsumed until the pet actually evolves
            if let cumulativeCalories = cumulativeCalories {
                self.cumulativeCalories = cumulativeCalories
                DebugConfig.debugPrint("   - Egg stage: Using HealthKit cumulative calories: \(cumulativeCalories)")
                DebugConfig.debugPrint("   - Egg stage: totalCaloriesConsumed remains at: \(self.totalCaloriesConsumed) (will update on evolution)")
            } else {
                // Fallback to previous logic if cumulative calories not provided
                self.cumulativeCalories = getCumulativeCaloriesSinceEgg() + todayCalories
                DebugConfig.debugPrint("   - Egg stage: Using fallback calculation: \(self.cumulativeCalories)")
                DebugConfig.debugPrint("   - Egg stage: totalCaloriesConsumed remains at: \(self.totalCaloriesConsumed) (will update on evolution)")
            }
        } else {
            // For other stages, use only today's calories
            self.cumulativeCalories = todayCalories
            DebugConfig.debugPrint("   - Non-egg stage: Using today's calories: \(todayCalories)")
        }
        
        DebugConfig.debugPrint("   - Final pet cumulativeCalories: \(self.cumulativeCalories)")
        DebugConfig.debugPrint("   - Final currentDayCalories: \(self.currentDayCalories)")
        DebugConfig.debugPrint("   - Final totalCaloriesConsumed: \(self.totalCaloriesConsumed)")
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
        case 3...5:
            emotion = .sad
        case 6...20:
            emotion = .sleepy
        case 21...50:
            emotion = .happy
        case 51...100:
            emotion = .excited
        case 101...150:
            emotion = .tantrum
        default :
            emotion = .content
        }
    }
    
    // Evolution Condition (Requirements)
    func isReadyToEvolve() -> Bool {
        DebugConfig.debugPrint("🔍 Checking evolution readiness:")
        DebugConfig.debugPrint("   - Current stage: \(stage.displayName)")
        DebugConfig.debugPrint("   - Current age: \(age) days")
        DebugConfig.debugPrint("   - Current cumulativeCalories: \(cumulativeCalories)")
        DebugConfig.debugPrint("   - Current currentDayCalories: \(currentDayCalories)")
        
        let readyToEvolve: Bool
        
        switch stage {
        case .egg:
            readyToEvolve = currentDayCalories >= 200
            DebugConfig.debugPrint("   - Egg evolution check: \(currentDayCalories) >= 200 = \(readyToEvolve)")
            return readyToEvolve
        case .baby:
            readyToEvolve = age >= 7  // 7 days as baby
            DebugConfig.debugPrint("   - Baby evolution check: \(age) >= 7 = \(readyToEvolve)")
            return readyToEvolve
        case .child:
            readyToEvolve = age >= 15  // 15 days total (8 more days as child)
            DebugConfig.debugPrint("   - Child evolution check: \(age) >= 15 = \(readyToEvolve)")
            return readyToEvolve
        case .teen:
            readyToEvolve = age >= 25  // 25 days total (10 more days as teen)
            DebugConfig.debugPrint("   - Teen evolution check: \(age) >= 25 = \(readyToEvolve)")
            return readyToEvolve
        case .adult:
            readyToEvolve = age >= 40  // 40 days total (15 more days as adult)
            DebugConfig.debugPrint("   - Adult evolution check: \(age) >= 40 = \(readyToEvolve)")
            return readyToEvolve
        case .elder:
            DebugConfig.debugPrint("   - Elder stage: cannot evolve further")
            break
        }
        
        DebugConfig.debugPrint("   - Final result: NOT ready to evolve (elder stage or no valid check)")
        return false
    }
    
    // MARK: - Evolution Methods
    
    /// Attempts to evolve the pet naturally based on current requirements
    /// Returns true if evolution occurred, false if requirements not met
    func tryNaturalEvolution() -> Bool {
        guard !isDead else { return false }
        guard isReadyToEvolve() else { return false }
        
        let previousStage = stage
        let previousCumulativeCalories = cumulativeCalories
        
        // Perform the evolution
        switch stage {
        case .egg:
            stage = .baby
            // Transfer accumulated calories to totalCaloriesConsumed when hatching
            totalCaloriesConsumed += cumulativeCalories
            DebugConfig.debugPrint("🥚➡️🐣 Egg hatched! Transferred \(cumulativeCalories) calories to totalCaloriesConsumed")
        case .baby:
            stage = .child
        case .child:
            stage = .teen
        case .teen:
            stage = .adult
        case .adult:
            stage = .elder
        case .elder:
            return false // Already at max stage
        }
        
        // Update emotion based on current streak
        updateEmotion()
        
        DebugConfig.debugPrint("🌟 Natural evolution: \(previousStage.displayName) → \(stage.displayName)")
        DebugConfig.debugPrint("📅 Age remains: \(age) days (actual days alive)")
        DebugConfig.debugPrint("🔥 Total calories consumed: \(totalCaloriesConsumed)")
        
        return true
    }
    
    // MARK: - Development/Testing Methods
    
    /// Forces the pet to evolve to the next stage by setting age to the minimum required
    /// This is for development/testing purposes
    func forceEvolveToNextStage() {
        // Don't evolve if pet is dead
        if isDead { return }
        
        let previousStage = stage
        let previousCumulativeCalories = cumulativeCalories
        
        // Force evolution to next stage (bypassing normal requirements)
        switch stage {
        case .egg:
            stage = .baby
            // Transfer accumulated calories to totalCaloriesConsumed when hatching (even for force evolution)
            totalCaloriesConsumed += cumulativeCalories
            DebugConfig.debugPrint("🥚➡️🐣 Force hatched! Transferred \(cumulativeCalories) calories to totalCaloriesConsumed")
        case .baby:
            stage = .child
        case .child:
            stage = .teen
        case .teen:
            stage = .adult
        case .adult:
            stage = .elder
        case .elder:
            // Already at max stage, do nothing
            DebugConfig.debugPrint("🦴 Pet is already at elder stage (max)")
            return
        }
        
        // Update emotion based on current streak
        updateEmotion()
        
        DebugConfig.debugPrint("🚀 Force evolved from \(previousStage.displayName) to \(stage.displayName)")
        DebugConfig.debugPrint("📅 Age remains: \(age) days (actual days alive)")
        DebugConfig.debugPrint("🔥 Total calories consumed: \(totalCaloriesConsumed)")
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
        case .baby, .child, .teen, .adult, .elder:
            // For animated pets, return frame 1 as the default static image
            return "Pet/\(species.camelCaseName)\(stage.camelCaseName)\(emotion.camelCaseName)IdleFr1"
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

