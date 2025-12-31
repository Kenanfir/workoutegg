//
//  ContentView.swift
//  WorkoutEgg Watch App
//
//  Created by Alif Dimasius on 20/05/25.
//

import HealthKit
import SpriteKit
import SwiftData
import SwiftUI

// MARK: - Views

// MARK: - Views

// OnboardingView moved to separate file

struct WorkoutStatsView: View {
    let caloriesBurned: Double

    var body: some View {
        VStack(spacing: 12) {
            // Calories
            VStack {
                Image(systemName: "flame.fill")
                    .imageScale(.large)
                    .foregroundStyle(.orange)

                Text("\(Int(caloriesBurned))")
                    .font(.system(size: 32, weight: .bold))

                Text("calories today")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// Extensions for the coordinate conversion utilities
extension CGSize {
    func unpack() -> (CGFloat, CGFloat) {
        return (width, height)
    }
}

extension CGPoint {
    func invertY() -> CGPoint {
        return CGPoint(x: x, y: -y)
    }

    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

extension CGVector {
    init(_ dx: CGFloat, _ dy: CGFloat) {
        self.init(dx: dx, dy: dy)
    }
}

extension CGPoint {
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

// Constants for scene size
enum Constants {
    static let sceneSize = CGSize(width: 100, height: 100)
    static let tapYOffset: CGFloat = -5.0  // Adjust this value to move tap detection up/down
}

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @Query private var pets: [PetData]
    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // PetManager will be initialized in onAppear with the real context
    @State private var petManager: PetManager?

    // Change currentPet from computed property to @State variable
    @State private var currentPet: PetData?

    // State for longest lived pet
    @State private var longestLivedPet: LongestLivedPetData?

    @State private var selectedTab = 1
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        scene.size = Constants.sceneSize
        scene.scaleMode = .aspectFit
        return scene
    }()

    @State private var progressScene: ProgressScene = {
        let scene = ProgressScene(petData: nil)
        scene.size = CGSize(width: 300, height: 300)
        scene.scaleMode = .resizeFill
        return scene
    }()

    // Helper to get or create current pet
    private func getCurrentPet() -> PetData {
        if let pet = currentPet {
            return pet
        }

        // Try to get existing pet from database
        if let existingPet = pets.first {
            currentPet = existingPet
            return existingPet
        }

        // Create new pet if none exists
        let newPet = PetData()
        context.insert(newPet)
        do {
            try context.save()
            currentPet = newPet
            DebugConfig.debugPrint("✅ Created new pet and saved to SwiftData")
        } catch {
            DebugConfig.debugPrint("❌ Failed to save new pet: \(error)")
        }
        return newPet
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                mainTabView
            }
        }
        .onAppear {
            // Initialize petManager with the real context
            petManager = PetManager(context: context)

            // Initialize notification system
            NotificationManager.requestPermission()

            // Initialize currentPet first
            let pet = getCurrentPet()

            // Fetch longest lived pet
            longestLivedPet = petManager?.getLongestLivedPet()

            // Set up the callback for when HealthKit data is loaded
            healthKitManager.onDataLoaded = { [weak gameScene] in
                DispatchQueue.main.async {
                    // Update evolution button and progress when HealthKit data is actually loaded
                    gameScene?.updateEvolutionButton()
                    updateProgressDisplay()
                }
            }

            // Set up the connection between HealthKitManager and PetData
            healthKitManager.requestAuthorization()
            healthKitManager.setPetData(pet)

            // Set up the connection between GameScene and PetData
            gameScene.setPetData(pet)

            // Set up the connection between ProgressScene and PetData
            progressScene.setPetData(pet)

            // Set up save callback for ProgressScene
            progressScene.onSaveRequired = {
                do {
                    try context.save()
                    DebugConfig.debugPrint("💾 Saved context after feeding")
                } catch {
                    DebugConfig.debugPrint("❌ Failed to save context: \(error)")
                }
            }

            // Force refresh HealthKit data (callback will handle evolution button update)
            healthKitManager.fetchTodayCalories()

            // Defer state-modifying operations to avoid "Modifying state during view update" warning
            DispatchQueue.main.async {
                // Check for missed workouts when app opens
                pet.runAtStartOfApp()

                // CRITICAL: Check if pet should be dead from neglect or old age
                petManager?.checkPetHealth()

                // If pet died, handle it
                if pet.isDead {
                    handlePetDeath()
                }
            }
        }
        .onChange(of: pets) { oldValue, newValue in
            // Update currentPet when pets query changes
            if let pet = newValue.first {
                currentPet = pet
            }
        }
        .onChange(of: currentPet?.stage) { oldValue, newValue in
            // Update GameScene when pet stage changes
            gameScene.updatePetDisplay()
            updateProgressDisplay()
        }
        .onChange(of: currentPet?.age) { oldValue, newValue in
            // Update displays when pet age changes (indicates feeding occurred)
            updateProgressDisplay()
            gameScene.updatePetDisplay()
        }
        .onChange(of: currentPet?.streak) { oldValue, newValue in
            // Update displays when pet streak changes (indicates feeding occurred)
            updateProgressDisplay()
        }
        .onChange(of: currentPet?.emotion) { oldValue, newValue in
            // Update pet animation when emotion changes (affects which animation frames to use)
            if oldValue != newValue {
                DebugConfig.debugPrint(
                    "🎭 Pet emotion changed from \(oldValue?.displayName ?? "nil") to \(newValue?.displayName ?? "nil")"
                )
                gameScene.updatePetAnimation()
            }
        }
        .onChange(of: currentPet?.isDead) { oldValue, newValue in
            // Handle pet death state change
            if newValue == true && oldValue != true {
                DebugConfig.debugPrint("💀 Pet died! Handling death...")
                handlePetDeath()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .petEvolved)) { notification in
            // Handle pet evolution notification from GameScene
            if let petData = notification.object as? PetData {
                DebugConfig.debugPrint("📢 Received pet evolution notification")

                // Save the context
                do {
                    try context.save()
                    DebugConfig.debugPrint("✅ SwiftData context saved after evolution notification")
                    DebugConfig.debugPrint("🔍 Pet stage after save: \(petData.stage.displayName)")
                    DebugConfig.debugPrint(
                        "🔍 Total calories consumed: \(petData.totalCaloriesConsumed)")
                } catch {
                    DebugConfig.debugPrint("❌ Failed to save SwiftData context: \(error)")
                }

                // Update displays
                updateProgressDisplay()
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            statusTab
            gameSceneTab
            progressSceneTab
        }
        .tabViewStyle(.page)
    }

    private var statusTab: some View {
        Group {
            if let pet = currentPet {
                ScrollableStatusView(currentPet: pet, longestLivedPet: longestLivedPet)
            } else {
                StatusView(petData: getCurrentPet())
            }
        }
        //        .containerBackground(backgroundImage("background/bg-brown"), for: .tabView)
        .tag(0)
    }

    private var gameSceneTab: some View {
        GeometryReader { geoProxy in
            let tap = getTap(geoProxy)

            SpriteView(scene: gameScene)
                .gesture(tap)
                .ignoresSafeArea(.all)
                .overlay(alignment: .bottom) {
                    if DebugConfig.shouldShowDebugUI {
                        gameSceneOverlay
                    }
                }
                .onAppear {
                    // Force refresh HealthKit data when GameScene appears
                    healthKitManager.fetchTodayCalories()
                    // Evolution button will be updated via the onDataLoaded callback
                }
        }
        .frame(width: 300, height: 300)
        .containerBackground(for: .tabView) {
            EmptyView()
        }
        .tag(1)
    }

    private var gameSceneOverlay: some View {
        VStack(spacing: 8) {
            Text("Current Stage: \(getCurrentPet().stage.displayName)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(6)

            // Show current animation info
            if DebugConfig.shouldShowDebugUI {
                Text("Idle: \(getCurrentPet().petAnimationFrames.first ?? "None")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)

                Text("Tapped: \(getCurrentPet().petTappedAnimationFrames.first ?? "None")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)

                Text("Emotion: \(getCurrentPet().emotion.displayName)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)
            }

            // Debug Force Evolution Button (only in debug mode)
            if DebugConfig.shouldShowDebugUI {
                Button {
                    getCurrentPet().forceEvolveToNextStage()

                    // Explicitly save the context to ensure changes persist
                    do {
                        try context.save()
                        DebugConfig.debugPrint("✅ SwiftData context saved after force evolution")
                        DebugConfig.debugPrint(
                            "🔍 Pet stage after save: \(getCurrentPet().stage.displayName)")
                    } catch {
                        DebugConfig.debugPrint("❌ Failed to save SwiftData context: \(error)")
                    }

                    // Force UI updates
                    gameScene.updatePetDisplay()
                    updateProgressDisplay()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Force Evolve")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(getCurrentPet().stage == .elder || getCurrentPet().isDead)
            }
        }
        .padding(.bottom, 20)
    }

    private var progressSceneTab: some View {
        Group {
            if let petManager = petManager {
                GeometryReader { geoProxy in
                    let progressTap = getProgressTap(geoProxy)

                    SpriteView(scene: progressScene)
                        .gesture(progressTap)
                        .onAppear {
                            let newSize = geoProxy.size
                            progressScene.size = CGSize(
                                width: newSize.width, height: newSize.height)
                            progressScene.scaleMode = .resizeFill

                            // Force refresh HealthKit data when ProgressScene appears
                            healthKitManager.fetchTodayCalories()
                            updateProgressDisplay()
                        }
                        .onChange(of: healthKitManager.cumulativeCalories) { _ in
                            updateProgressDisplay()
                            gameScene.updateEvolutionButton()
                        }
                        .onChange(of: healthKitManager.caloriesBurned) { _ in
                            updateProgressDisplay()
                            gameScene.updateEvolutionButton()
                        }
                        .ignoresSafeArea()
                }
                .frame(width: 300, height: 300)
            } else {
                // Show loading or placeholder while petManager initializes
                Text("Loading...")
                    .frame(width: 300, height: 300)
            }
        }
        .tag(2)
    }

    private func updateProgressDisplay() {
        // Ensure pet data is updated with current HealthKit values first
        let pet = getCurrentPet()

        // Update pet's internal calories data for evolution checks
        if pet.stage == .egg {
            // For eggs: use both today's calories and cumulative calories
            pet.updateCumulativeCalories(
                todayCalories: healthKitManager.caloriesBurned,
                cumulativeCalories: healthKitManager.cumulativeCalories)
        } else {
            // For other stages: use only today's calories
            pet.updateCumulativeCalories(todayCalories: healthKitManager.caloriesBurned)
        }

        // Use real HealthKit data for display
        let displayCalories =
            pet.stage == .egg
            ? Int(healthKitManager.cumulativeCalories) : Int(healthKitManager.caloriesBurned)

        // Debug info for currentDayFeedCount
        let currentFoodCount = pet.getCurrentDayFeedCount()
        DebugConfig.debugPrint("🍎 Current Day Feed Count: \(currentFoodCount)")
        DebugConfig.debugPrint("📊 Display Calories: \(displayCalories)")

        // Debug HealthKit data
        DebugConfig.debugPrint("🔥 HealthKit Debug:")
        DebugConfig.debugPrint("   - Pet Stage: \(pet.stage.displayName)")
        DebugConfig.debugPrint("   - HealthKit caloriesBurned: \(healthKitManager.caloriesBurned)")
        DebugConfig.debugPrint(
            "   - HealthKit cumulativeCalories: \(healthKitManager.cumulativeCalories)")
        DebugConfig.debugPrint("   - Pet currentDayCalories: \(pet.currentDayCalories)")
        DebugConfig.debugPrint("   - Pet cumulativeCalories: \(pet.cumulativeCalories)")
        DebugConfig.debugPrint(
            "   - Final displayCalories sent to ProgressScene: \(displayCalories)")

        progressScene.updateProgress(current: displayCalories)
    }

    // Get tap gesture with coordinate conversion
    func getTap(_ geoProxy: GeometryProxy) -> some Gesture {
        return SpatialTapGesture(coordinateSpace: .local)
            .onEnded { tapValue in
                let pScene = getScenePosition(tapValue.location, geoProxy)
                gameScene.onTap(pScene)

            }
    }

    // Convert tap position to scene position
    func getScenePosition(_ tapPosition: CGPoint, _ geoProxy: GeometryProxy) -> CGPoint {
        let viewSize = geoProxy.size
        let normalizedX = tapPosition.x / viewSize.width
        let normalizedY = tapPosition.y / viewSize.height
        let sceneX = (normalizedX - 0.5) * Constants.sceneSize.width
        let sceneY = (0.5 - normalizedY) * Constants.sceneSize.height
        let pScene = CGPoint(x: sceneX, y: sceneY)
        return pScene
    }

    // Get progress tap gesture with coordinate conversion
    func getProgressTap(_ geoProxy: GeometryProxy) -> some Gesture {
        return SpatialTapGesture(coordinateSpace: .local)
            .onEnded { tapValue in
                let pScene = getProgressScenePosition(tapValue.location, geoProxy)
                progressScene.onTap(pScene)

            }
    }

    // Convert tap position to scene position for progress scene
    func getProgressScenePosition(_ tapPosition: CGPoint, _ geoProxy: GeometryProxy) -> CGPoint {
        let viewSize = geoProxy.size
        let normalizedX = tapPosition.x / viewSize.width
        let normalizedY = tapPosition.y / viewSize.height

        // ProgressScene uses a 300x300 size, so use that for conversion
        let progressSceneSize = CGSize(width: 300, height: 300)
        let sceneX = (normalizedX - 0.5) * progressSceneSize.width
        let sceneY = (0.5 - normalizedY) * progressSceneSize.height
        let pScene = CGPoint(x: sceneX, y: sceneY)
        return pScene
    }

    private func backgroundImage(_ imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }

    /// Handles pet death: refreshes leaderboard, creates new pet, updates all scenes
    private func handlePetDeath() {
        DebugConfig.debugPrint("☠️ handlePetDeath called")

        // Refresh longest lived pet record
        longestLivedPet = petManager?.getLongestLivedPet()
        DebugConfig.debugPrint("🏆 Refreshed longest lived pet record")

        // Get or create new pet (PetManager.getCurrentPet() will auto-create if needed)
        if let manager = petManager {
            let newPet = manager.getCurrentPet()
            currentPet = newPet

            // Update HealthKitManager with new pet
            healthKitManager.setPetData(newPet)

            // Update scenes with new pet
            gameScene.setPetData(newPet)
            progressScene.setPetData(newPet)

            // Save context
            do {
                try context.save()
                DebugConfig.debugPrint("✅ SwiftData context saved after death handling")
            } catch {
                DebugConfig.debugPrint("❌ Failed to save SwiftData context: \(error)")
            }

            DebugConfig.debugPrint("🥚 New pet created and all scenes updated")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PetData.self, LongestLivedPetData.self])
}
