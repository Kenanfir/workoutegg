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
    
    // Pet data reference
    private var petData: PetData?
    
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
        setupPet()
    }
    
    /// Set the pet data reference and update the display
    func setPetData(_ petData: PetData) {
        self.petData = petData
        updatePetDisplay()
    }
    
    /// Update the pet display when stage or species changes
    func updatePetDisplay() {
        guard let petData = self.petData else { return }
        
        // Remove existing pet sprite
        childNode(withName: "pet")?.removeFromParent()
        
        // Create new pet sprite with current image
        setupPet()
    }
    
    private func setupPet() {
        print("Setting up pet") // Debug print
        
        // Get the current pet image name, fallback to egg if no pet data
        let imageName = petData?.petImageName ?? "Egg/egg-2-wo-normal"
        
        // Create the pet sprite
        let pet = SKSpriteNode(imageNamed: imageName)
        
        // Debug print to check if image was loaded
        if pet.texture == nil {
            print("Failed to load pet image: \(imageName)")
        } else {
            print("Pet image loaded successfully: \(imageName)")
            print("Pet size: \(pet.size)")
        }
        
        // Keep original size but scale it down to fit
        let scale: CGFloat = 0.6 // Scale down to fit
        pet.size = CGSize(width: pet.size.width * scale, height: pet.size.height * scale)
        
        // Set the anchor point to the bottom center
        pet.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        
        // Position the pet at the center (0,0 since we set anchorPoint to center)
        pet.position = CGPoint(x: 0, y: -15) // Moved up by 50 points
        print("Pet position: \(pet.position)") // Debug print
        print("Scene frame: \(frame)") // Debug print
        
        // Name (changed from "egg" to "pet" to be more generic)
        pet.name = "pet"
        
        // Add the pet to the scene
        addChild(pet)
        
        // Visualize the hit area if debug flag is enabled
        if showHitArea {
            let hitAreaNode = SKShapeNode(rect: pet.frame)
            hitAreaNode.strokeColor = .green
            hitAreaNode.lineWidth = 0.5
            hitAreaNode.alpha = 0.4
            addChild(hitAreaNode)
            print("Added hit area visualization: \(pet.frame)")
        }
    }
    
    func wigglePet(_ pet: SKSpriteNode) {
        // Create a sequence of actions for the wiggle
        let rotateRight = SKAction.rotate(toAngle: .pi / 20, duration: 0.2)
        let rotateLeft = SKAction.rotate(toAngle: -.pi / 20, duration: 0.2)
        let wiggle = SKAction.sequence([rotateRight, rotateLeft])
        let repeatWiggle = SKAction.repeat(wiggle, count: 2) // Wiggle twice and stop
        let returnToCenter = SKAction.rotate(toAngle: 0, duration: 0.2)
        
        // Combine all actions into one sequence
        let fullAnimation = SKAction.sequence([repeatWiggle, returnToCenter])
        
        // Run the animation
        pet.run(fullAnimation)
    }
    
    // Method to handle tap points from SwiftUI
    func onTap(_ point: CGPoint) {
        print("Received tap at: \(point)") // Debug tap position
        
        if let pet = childNode(withName: "pet") as? SKSpriteNode {
            let petFrame = pet.frame
            print("Pet position: \(pet.position), frame: \(petFrame)")
            
            // Create visual indicators
            let marker = SKShapeNode(circleOfRadius: 3)
            
            // Use the exact pet frame for hit detection
            if petFrame.contains(point) {
                print("Pet tapped!")
                marker.fillColor = .green // Green for successful tap
                wigglePet(pet)
            } else {
                print("Tap missed pet. Distance from pet center: \(distance(from: point, to: pet.position))")
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
