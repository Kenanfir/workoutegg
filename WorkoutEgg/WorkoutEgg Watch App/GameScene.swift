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
        // ngefix background X
        let background = SKSpriteNode(imageNamed: "background/bg-sky-blue")
        if background.texture == nil {
            print("Failed to load background image: background/bg-sky-blue")
        } else {
            print("Successfully loaded background image")
            print("Background size: \(background.size)")
        }
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = -1 // Place it behind other elements
        
        background.setScale(0.75)
        
        addChild(background)
        isUserInteractionEnabled = true
        scaleMode = .aspectFit // Make the scene fill the entire screen
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Set anchor point to center
        setupEgg()
    }
    
    private func setupEgg() {
        print("Setting up egg") // Debug print
        // Create the egg sprite
        let egg = SKSpriteNode(imageNamed: "Egg/egg-2-wo-normal")
        
        // Debug print to check if image was loaded
        if egg.texture == nil {
            print("Failed to load egg image")
        } else {
            print("Egg image loaded successfully")
            print("Egg size: \(egg.size)")
        }
        
        // Keep original size but scale it down to fit
        let scale: CGFloat = 0.6 // Scale down to half size
        egg.size = CGSize(width: egg.size.width * scale, height: egg.size.height * scale)
        
        // Set the anchor point to the bottom center
        egg.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        
        // Position the egg at the center (0,0 since we set anchorPoint to center)
        egg.position = CGPoint(x: 0, y: -15) // Moved up by 50 points
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
    
    func wiggleEgg(_ egg: SKSpriteNode) {
        // Create a sequence of actions for the wiggle
        let rotateRight = SKAction.rotate(toAngle: .pi / 20, duration: 0.2)
        let rotateLeft = SKAction.rotate(toAngle: -.pi / 20, duration: 0.2)
        let wiggle = SKAction.sequence([rotateRight, rotateLeft])
        let repeatWiggle = SKAction.repeat(wiggle, count: 2) // Wiggle twice and stop
        let returnToCenter = SKAction.rotate(toAngle: 0, duration: 0.2)
        
        // Combine all actions into one sequence
        let fullAnimation = SKAction.sequence([repeatWiggle, returnToCenter])
        
        // Run the animation
        egg.run(fullAnimation)
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
                wiggleEgg(egg)
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
}
