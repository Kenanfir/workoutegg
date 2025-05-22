//
//  GameScene.swift
//  WorkoutEgg Watch App
//
//  Created by Alif Dimasius on 21/05/25.
//

import SpriteKit
import WatchKit

class GameScene: SKScene {
    
    // Debug flag to show hit area
    let showHitArea = false
    
    override func sceneDidLoad() {
        print("Scene did load") // Debug print
        backgroundColor = .white
        isUserInteractionEnabled = true
        scaleMode = .resizeFill // Make the scene fill the entire screen
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Set anchor point to center
        setupEgg()
    }
    
    private func setupEgg() {
        print("Setting up egg") // Debug print
        // Create the egg sprite
        let egg = SKSpriteNode(imageNamed: "EggSampleOne")
        
        // Debug print to check if image was loaded
        if egg.texture == nil {
            print("Failed to load egg image")
        } else {
            print("Egg image loaded successfully")
            print("Egg size: \(egg.size)")
        }
        
        // Keep original size but scale it down to fit
        let scale: CGFloat = 1 // Scale down to half size
        egg.size = CGSize(width: egg.size.width * scale, height: egg.size.height * scale)
        
        // Position the egg at the center (0,0 since we set anchorPoint to center)
        egg.position = CGPoint(x: 0, y: 0)
        print("Egg position: \(egg.position)") // Debug print
        print("Scene frame: \(frame)") // Debug print
        
        // Name
        egg.name = "egg"
        
        // Add the egg to the scene
        addChild(egg)
        
        // Visualize the hit area if debug flag is enabled
        if showHitArea {
            let hitAreaNode = SKShapeNode(rect: egg.frame)
            hitAreaNode.strokeColor = .green
            hitAreaNode.lineWidth = 0.5
            hitAreaNode.alpha = 0.4
            addChild(hitAreaNode)
            print("Added hit area visualization: \(egg.frame)")
        }
    }
    
    // Method to handle tap points from SwiftUI
    func onTap(_ point: CGPoint) {
        print("Received tap at: \(point)") // Debug tap position
        
        if let egg = childNode(withName: "egg") as? SKSpriteNode {
            let eggFrame = egg.frame
            print("Egg position: \(egg.position), frame: \(eggFrame)")
            
            // Create visual indicators
            let marker = SKShapeNode(circleOfRadius: 3)
            
            // Use the exact egg frame for hit detection
            if eggFrame.contains(point) {
                print("Egg tapped!")
                marker.fillColor = .green // Green for successful tap
                bounceEgg(egg)
            } else {
                print("Tap missed egg. Distance from egg center: \(distance(from: point, to: egg.position))")
                marker.fillColor = .red // Red for missed tap
            }
            
            // Show tap position marker
            marker.position = point
            marker.alpha = 0.6
            addChild(marker)
            
            // Remove marker after a delay
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            marker.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), fadeOut, remove]))
        }
    }
    
    // Helper to calculate distance between points
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx*dx + dy*dy)
    }
    
    func bounceEgg (_ egg: SKSpriteNode) {
        // Create a sequence of actions for the bounce
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let bounce = SKAction.sequence([scaleUp, scaleDown])
    
        // Run the animation
        egg.run(bounce)
    }
}
