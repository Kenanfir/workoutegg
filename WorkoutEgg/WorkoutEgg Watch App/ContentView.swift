//
//  ContentView.swift
//  WorkoutEgg Watch App
//
//  Created by Alif Dimasius on 20/05/25.
//

import SwiftUI
import HealthKit
import SpriteKit
import SwiftData

// MARK: - Views

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Header1")
                .font(.title3)
                .bold()
                .padding(.top, 40)
            
            Text("Header2")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                hasCompletedOnboarding = true
            }) {
                Text("Get Started")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

struct WorkoutStatsView: View {
    @Bindable var petData: PetData
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Calories
            VStack {
                Image(systemName: "flame.fill")
                    .imageScale(.large)
                    .foregroundStyle(.orange)
                
                Text("\(displayCalories)")
                    .font(.system(size: 32, weight: .bold))
                
                Text(caloriesLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private var displayCalories: Int {
        // Simulate 300 KCal for testing
        return 300
    }
    
    private var caloriesLabel: String {
        return "simulated calories (testing)"
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
    static let tapYOffset: CGFloat = -5.0 // Adjust this value to move tap detection up/down
}

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @Query private var pets: [PetData]
    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Get the current pet (or create one if none exists)
    private var currentPet: PetData {
        if let pet = pets.first {
            return pet
        } else {
            let newPet = PetData()
            context.insert(newPet)
            try? context.save()
            return newPet
        }
    }
    
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
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                TabView(selection: $selectedTab) {
                    // Status View (Left)
                    StatusView(petData: currentPet)
                        .tag(0)
                    
                    // Egg Scene View (Middle - Main Screen)
                    GeometryReader { geoProxy in
                        let tap = getTap(geoProxy)
                        
                        SpriteView(scene: gameScene)
                            .gesture(tap)
                            .ignoresSafeArea(.all)
                            .overlay(alignment: .bottom) {
                                // Development/Testing Button Overlay
                                VStack(spacing: 8) {
                                    Text("Current Stage: \(currentPet.stage.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(6)
                                    
                                    Button {
                                        currentPet.forceEvolveToNextStage()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.circle.fill")
                                            Text("Evolve Pet")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(currentPet.stage == .elder || currentPet.isDead)
                                }
                                .padding(.bottom, 20)
                            }
                    }
                    .frame(width: 300, height: 300)
                    .tag(1)
                    
                    // Progress Scene View
                    GeometryReader { geoProxy in
                        SpriteView(scene: progressScene)
                            .onAppear {
                                let newSize = geoProxy.size
                                progressScene.size = CGSize(width: newSize.width, height: newSize.height)
                                progressScene.scaleMode = .resizeFill
                                updateProgressDisplay()
                            }
                            .onChange(of: healthKitManager.cumulativeCalories) { _ in
                                updateProgressDisplay()
                            }
                            .onChange(of: healthKitManager.caloriesBurned) { _ in
                                updateProgressDisplay()
                            }
                            .ignoresSafeArea()
                            .overlay(alignment: .bottom) {
                                // Debug/Testing Button Overlay
                                VStack(spacing: 8) {
                                    Button {
                                        updateProgressDisplay()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.clockwise.circle.fill")
                                            Text("Update Food")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                    }
                                    
                                    Text("300 KCal (Simulated)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(6)
                                }
                                .padding(.bottom, 20)
                            }
                    }
                    .frame(width: 300, height: 300)
                    .tag(2)
                }
                .tabViewStyle(.page)
            }
        }
        .onAppear {
            // Set up the connection between HealthKitManager and PetData
            healthKitManager.setPetData(currentPet)
            
            // Set up the connection between GameScene and PetData
            gameScene.setPetData(currentPet)
            
            // Set up the connection between ProgressScene and PetData
            progressScene.setPetData(currentPet)
            
            // Check for missed workouts when app opens
            currentPet.checkMissedFed()
        }
        .onChange(of: currentPet.stage) { oldValue, newValue in
            // Update GameScene when pet stage changes
            gameScene.updatePetDisplay()
        }
    }
    
    private func updateProgressDisplay() {
        // Simulate 300 KCal instead of using HealthKit data
        let displayCalories = 700
        
        // Print debug info for currentDayFeedCount
        let currentFoodCount = currentPet.getCurrentDayFeedCount()
        print("🍎 Current Day Feed Count: \(currentFoodCount)")
        print("📊 Display Calories: \(displayCalories)")
        
        progressScene.updateProgress(current: displayCalories)
    }
    
    // Get tap gesture with coordinate conversion
    func getTap(_ geoProxy: GeometryProxy) -> some Gesture {
        return SpatialTapGesture(coordinateSpace: .local)
            .onEnded { tapValue in
                let pScene = getScenePosition(tapValue.location, geoProxy)
                gameScene.onTap(pScene)
                
                // Store the previous stage
                let previousStage = currentPet.stage
                
                // Update pet data when interacting with the egg
                currentPet.updateAfterFed()
                
                // Update GameScene display if stage changed
                if previousStage != currentPet.stage {
                    gameScene.updatePetDisplay()
                }
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
}

#Preview {
    ContentView()
}
