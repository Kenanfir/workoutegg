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
    var species: PetSpecies
    var stage: PetStage
    var emotion: PetEmotion
    var lastFedDate: Date
    
    // Computed properties remain the same
    var ageInDays: String {
        return "\(age) DAYS"
    }
    
    var streakInDays: String {
        return "\(streak) DAYS"
    }
    
    init(age: Int = 500, streak: Int = 400, species: PetSpecies = .fufufafa,
         stage: PetStage = .baby, emotion: PetEmotion = .tantrum, lastFedDate: Date = Date()) {
        self.age = age
        self.streak = streak
        self.species = species
        self.stage = stage
        self.emotion = emotion
        self.lastFedDate = lastFedDate
    }
    
    // Methods remain exactly the same
    func updateAfterFed() {
        streak += 1
        age += 1
        lastFedDate = Date()
        
        // Update emotion based on streak
        updateEmotion()
        
        // Check for stage evolution
        checkStageEvolution()
    }
    
    func checkMissedFed() {
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
            if lastFedDate < yesterday {
                streak = 0
                emotion = .sad
            }
        }
    }
    
    private func updateEmotion() {
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
            emotion = .tantrum // When streak is very high, they get demanding!
        }
    }
    
    private func checkStageEvolution() {
        switch age {
        case 0...10:
            stage = .egg
        case 11...50:
            stage = .baby
        case 51...150:
            stage = .child
        case 151...300:
            stage = .teen
        case 301...500:
            stage = .adult
        default:
            stage = .elder
        }
    }
}

// MARK: - Views

struct StatusView: View {
    @Bindable var petData: PetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            HStack {
                Spacer()
                Text("STATUS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Status Items
            StatusRow(label: "AGE", value: petData.ageInDays)
            StatusRow(label: "STREAK", value: petData.streakInDays)
            StatusRow(label: "SPECIES", value: petData.species.displayName)
            StatusRow(label: "STAGE", value: "\(petData.stage.rawValue)")
            
            // Emotion with color indicator
            HStack {
                Text("EMOTION")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .leading)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(petData.emotion.color)
                        .frame(width: 6, height: 6)
                    
                    Text(petData.emotion.displayName)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
        .cornerRadius(8)
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.vertical, 2)
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
                Text("\(Int(healthKitManager.caloriesBurned))")
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
    static let tapYOffset: CGFloat = -5.0 // Adjust this value to move tap detection up/down
}

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @Query private var pets: [PetData]
    @Environment(\.modelContext) private var context
    
    // Get the current pet (or create one if none exists)
    private var currentPet: PetData {
        if let pet = pets.first {
            return pet
        } else {
            let newPet = PetData()
            context.insert(newPet)
            try? context.save() // Explicitly save if needed
            return newPet
        }
    }
    @State private var selectedTab = 1 // Start on the egg screen (middle)
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        scene.size = Constants.sceneSize
        scene.scaleMode = .aspectFit
        print("Scene created with size: \(scene.size)") // Debug print
        return scene
    }()
    
    @State private var progressScene: ProgressScene = {
        let scene = ProgressScene()
        scene.size = CGSize(width: 300, height: 300) // Match your view size
        scene.scaleMode = .resizeFill
        return scene
    }()
    
    var body: some View {
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
            .tag(0)
            
            // Progress Scene View
            GeometryReader { geoProxy in
                SpriteView(scene: progressScene)
                    .onAppear {
                        let newSize = geoProxy.size
                        progressScene.size = CGSize(width: newSize.width, height: newSize.height)
                        progressScene.scaleMode = .resizeFill
                        progressScene.updateProgress(current: Int(healthKitManager.caloriesBurned))
                    }
                    .onChange(of: healthKitManager.caloriesBurned) { newValue in
                        progressScene.updateProgress(current: Int(newValue))
                    }
                    .ignoresSafeArea(.all)
            }
            .frame(width: 300, height: 300)
            .tag(1)
            
            // Calories View
            VStack {
                Image(systemName: "flame.fill")
                    .imageScale(.large)
                    .foregroundStyle(.orange)
                Text("\(Int(healthKitManager.caloriesBurned))")
                    .font(.system(size: 40, weight: .bold))
                Text("calories")
                    .font(.custom("VCROSDMono", size: 18))
                    .foregroundStyle(.light1)
            }
            .padding()
            .tag(2)

            // Workout Stats View (Right)
            WorkoutStatsView(petData: currentPet, healthKitManager: healthKitManager)
                .tag(2)
          
        }
        .tabViewStyle(.page)
        .onAppear {
            // Check for missed workouts when app opens
            currentPet.checkMissedFed()
        }
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
        // Get the actual size of our view
        let viewSize = geoProxy.size
        
        // Calculate the normalized position (0-1) within the view
        // This removes any scaling effects
        let normalizedX = tapPosition.x / viewSize.width
        let normalizedY = tapPosition.y / viewSize.height
        
        // Now map this 0-1 value directly to the scene coordinates
        // For watchOS SpriteKit scene with center at (0,0)
        // - Convert X from [0...1] to [-halfWidth...halfWidth]
        // - Convert Y from [0...1] to [halfHeight...-halfHeight] (flip Y)
        
        let sceneX = (normalizedX - 0.5) * Constants.sceneSize.width
        let sceneY = (0.5 - normalizedY) * Constants.sceneSize.height
        
        // Create the final scene point
        let pScene = CGPoint(x: sceneX, y: sceneY)
        
        // Log the conversion details
        print("Tap at (\(tapPosition.x), \(tapPosition.y)) in view size \(viewSize)")
        print("Normalized: (\(normalizedX), \(normalizedY))")
        print("Scene coords: \(pScene)")
        
        return pScene
    }
}

#Preview {
    ContentView()
}
