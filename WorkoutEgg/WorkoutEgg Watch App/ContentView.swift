//
//  ContentView.swift
//  WorkoutEgg Watch App
//
//  Created by Alif Dimasius on 20/05/25.
//

import SwiftUI
import HealthKit
import SpriteKit

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
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        scene.size = Constants.sceneSize
        scene.scaleMode = .aspectFit
        print("Scene created with size: \(scene.size)") // Debug print
        return scene
    }()
    
    var body: some View {
        TabView {
            // Egg Scene View
            GeometryReader { geoProxy in
                let tap = getTap(geoProxy)
                
                SpriteView(scene: gameScene)
                    .gesture(tap)
                    .onAppear {
                        print("SpriteView appeared") // Debug print
                    }
                    .ignoresSafeArea(.all)
            }
            .frame(width: 300, height: 300)
            .tag(0)
//            .ignoresSafeArea(.all)
            
            // Calories View
            VStack {
                Image(systemName: "flame.fill")
                    .imageScale(.large)
                    .foregroundStyle(.orange)
                Text("\(Int(healthKitManager.caloriesBurned))")
                    .font(.system(size: 40, weight: .bold))
                Text("calories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .tag(1)
        }
        .tabViewStyle(.page)
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
    
    // Get view size including safe areas
    func getViewSize(_ geoProxy: GeometryProxy) -> CGSize {
        // Unpack safe area size and surrounding insets
        let (wSafe, hSafe) = geoProxy.size.unpack()
        let insets = geoProxy.safeAreaInsets
        let (top, bottom) = (insets.top, insets.bottom)
        let (left, right) = (insets.leading, insets.trailing)
        
        // Add insets to safe area size
        let wView = wSafe + left + right
        let hView = hSafe + top + bottom
        return CGSize(width: wView, height: hView)
    }
}

#Preview {
    ContentView()
}
