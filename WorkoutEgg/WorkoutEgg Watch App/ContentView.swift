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
        return petData.stage == .egg ?
            Int(healthKitManager.cumulativeCalories) :
            Int(healthKitManager.caloriesBurned)
    }
    
    private var caloriesLabel: String {
        return petData.stage == .egg ?
            "total calories (egg stage)" :
            "calories today"
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
        let scene = ProgressScene()
        scene.size = CGSize(width: 300, height: 300)
        scene.scaleMode = .resizeFill
        return scene
    }()
    
    var body: some View {
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
                }
                .frame(width: 300, height: 300)
                .tag(2)
            }
            .tabViewStyle(.page)
            .onAppear {
                // Set up the connection between HealthKitManager and PetData
                healthKitManager.setPetData(currentPet)
                
                // Check for missed workouts when app opens
                currentPet.checkMissedFed()
            }
        }
    }
    
    private func updateProgressDisplay() {
        let displayCalories = currentPet.stage == .egg ?
            Int(healthKitManager.cumulativeCalories) :
            Int(healthKitManager.caloriesBurned)
        
        progressScene.updateProgress(current: displayCalories)
    }
    
    // Get tap gesture with coordinate conversion
    func getTap(_ geoProxy: GeometryProxy) -> some Gesture {
        return SpatialTapGesture(coordinateSpace: .local)
            .onEnded { tapValue in
                let pScene = getScenePosition(tapValue.location, geoProxy)
                gameScene.onTap(pScene)
                
                // Update pet data when interacting with the egg
                currentPet.updateAfterFed()
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
