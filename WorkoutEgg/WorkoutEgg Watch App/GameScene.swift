//
//  GameScene.swift
//  WorkoutEgg Watch App
//
//  Created by Alif Dimasius on 21/05/25.
//

import SpriteKit
import WatchKit
import SwiftData

class GameScene: SKScene {
    
    // Pet data reference
    private var petData: PetData?
    
    // Evolution button
    private var evolutionButton: SKSpriteNode?
    private var evolutionLabel: SKLabelNode?
    
    override func sceneDidLoad() {
        DebugConfig.debugPrint("Scene did load")
        // ngefix background X
        let background = SKSpriteNode(imageNamed: "background/bg-sky-blue")
        if background.texture == nil {
            DebugConfig.debugPrint("Failed to load background image: background/bg-sky-blue")
        } else {
            DebugConfig.debugPrint("Successfully loaded background image")
            DebugConfig.debugPrint("Background size: \(background.size)")
        }
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = -1 // Place it behind other elements
        
        background.setScale(0.75)
        
        addChild(background)
        isUserInteractionEnabled = true
        scaleMode = .aspectFit // Make the scene fill the entire screen
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Set anchor point to center
        setupPet()
        setupEvolutionButton()
    }
    
    /// Set the pet data reference and update the display
    func setPetData(_ petData: PetData) {
        self.petData = petData
        updatePetDisplay()
        updateEvolutionButton()
    }
    
    /// Update the pet display when stage or species changes
    func updatePetDisplay() {
        guard let petData = self.petData else { return }
        
        // Remove existing pet sprite
        childNode(withName: "pet")?.removeFromParent()
        
        // Create new pet sprite with current image
        setupPet()
        
        // Update evolution button visibility
        updateEvolutionButton()
    }
    
    private func setupPet() {
        DebugConfig.debugPrint("Setting up pet")
        
        // Get the current pet image name, fallback to egg if no pet data
        let imageName = petData?.petImageName ?? "Egg/egg-2-wo-normal"
        
        // Create the pet sprite
        let pet = SKSpriteNode(imageNamed: imageName)
        
        // Debug print to check if image was loaded
        if pet.texture == nil {
            DebugConfig.debugPrint("Failed to load pet image: \(imageName)")
        } else {
            DebugConfig.debugPrint("Pet image loaded successfully: \(imageName)")
            DebugConfig.debugPrint("Pet size: \(pet.size)")
        }
        
        // Keep original size but scale it down to fit
        let scale: CGFloat = 0.6 // Scale down to fit
        pet.size = CGSize(width: pet.size.width * scale, height: pet.size.height * scale)
        
        // Set the anchor point to the bottom center
        pet.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        
        // Position the pet at the center (0,0 since we set anchorPoint to center)
        pet.position = CGPoint(x: 0, y: -15) // Moved up by 50 points
        DebugConfig.debugPrint("Pet position: \(pet.position)")
        DebugConfig.debugPrint("Scene frame: \(frame)")
        
        // Name (changed from "egg" to "pet" to be more generic)
        pet.name = "pet"
        
        // Add the pet to the scene
        addChild(pet)
        
        // Visualize the hit area if debug flag is enabled
        if DebugConfig.shouldShowHitArea {
            let hitAreaNode = SKShapeNode(rect: pet.frame)
            hitAreaNode.strokeColor = .green
            hitAreaNode.lineWidth = 0.5
            hitAreaNode.alpha = 0.4
            addChild(hitAreaNode)
            DebugConfig.debugPrint("Added hit area visualization: \(pet.frame)")
        }
    }
    
    private func setupEvolutionButton() {
        // Create evolution button background
        evolutionButton = SKSpriteNode(color: .green, size: CGSize(width: 60, height: 20))
        evolutionButton!.position = CGPoint(x: 0, y: 30)
        evolutionButton!.zPosition = 10
        evolutionButton!.name = "evolution_button"
        
        // Create evolution button label
        evolutionLabel = SKLabelNode(fontNamed: "VCROSDMono")
        evolutionLabel!.text = "EVOLVE!"
        evolutionLabel!.fontSize = 8
        evolutionLabel!.fontColor = .white
        evolutionLabel!.position = CGPoint(x: 0, y: -3) // Slightly offset for centering
        evolutionLabel!.zPosition = 11
        evolutionLabel!.name = "evolution_label"
        
        evolutionButton!.addChild(evolutionLabel!)
        addChild(evolutionButton!)
        
        // Initially hide the button
        evolutionButton!.isHidden = true
        
        DebugConfig.debugPrint("Evolution button created and hidden")
    }
    
    private func updateEvolutionButton() {
        guard let petData = self.petData,
              let button = evolutionButton else { return }
        
        let shouldShow = petData.isReadyToEvolve() && !petData.isDead
        button.isHidden = !shouldShow
        
        DebugConfig.debugPrint("Evolution button visibility: \(shouldShow ? "visible" : "hidden")")
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
        DebugConfig.debugPrint("Received tap at: \(point)")
        
        // Check if evolution button was tapped
        if let button = evolutionButton,
           !button.isHidden,
           button.contains(point) {
            handleEvolutionButtonTap()
            return
        }
        
        // Check if pet was tapped
        if let pet = childNode(withName: "pet") as? SKSpriteNode,
           pet.contains(point) {
            handlePetTap(pet, at: point)
            return
        }
        
        // Show miss indicator if nothing was tapped
        showTapIndicator(at: point, success: false)
    }
    
    private func handleEvolutionButtonTap() {
        guard let petData = self.petData else { return }
        
        DebugConfig.debugPrint("🌟 Evolution button tapped!")
        
        if petData.tryNaturalEvolution() {
            // Evolution successful
            DebugConfig.debugPrint("✅ Evolution successful!")
            
            // Update the pet display
            updatePetDisplay()
            
            // Add evolution effect
            showEvolutionEffect()
            
            // Notify observers (ContentView) about the evolution
            NotificationCenter.default.post(name: .petEvolved, object: petData)
        } else {
            DebugConfig.debugPrint("❌ Evolution failed - requirements not met")
            showTapIndicator(at: evolutionButton!.position, success: false)
        }
    }
    
    private func handlePetTap(_ pet: SKSpriteNode, at location: CGPoint) {
        guard let petData = self.petData else { return }
        
        // Don't allow feeding if pet is dead
        if petData.isDead {
            showTapIndicator(at: location, success: false)
            return
        }
        
        // Call the feeding method
        petData.updateAfterFed()
        
        // Show success indicator
        showTapIndicator(at: location, success: true)
        
        // Wiggle the pet
        wigglePet(pet)
        
        // Update evolution button in case pet became ready to evolve
        updateEvolutionButton()
        
        DebugConfig.debugPrint("🍎 Pet fed! Age: \(petData.age), Streak: \(petData.streak)")
    }
    
    private func showEvolutionEffect() {
        // Create sparkle effect at pet position
        let sparkle = SKSpriteNode(color: .yellow, size: CGSize(width: 10, height: 10))
        sparkle.position = CGPoint(x: 0, y: 0)
        sparkle.zPosition = 15
        
        let scaleUp = SKAction.scale(to: 3.0, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([
            SKAction.group([scaleUp, fadeOut]),
            remove
        ])
        
        sparkle.run(sequence)
        addChild(sparkle)
        
        DebugConfig.debugPrint("✨ Evolution effect played")
    }
    
    private func showTapIndicator(at location: CGPoint, success: Bool) {
        // Only show tap indicators in debug mode
        guard DebugConfig.shouldShowTapIndicators else { return }
        
        let indicator = SKShapeNode(circleOfRadius: 4)
        indicator.fillColor = success ? .green : .red
        indicator.strokeColor = .white
        indicator.lineWidth = 1
        indicator.position = location
        indicator.alpha = 0.8
        indicator.zPosition = 100
        
        addChild(indicator)
        
        // Animate the indicator
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.5, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([
            scaleUp,
            scaleDown,
            SKAction.wait(forDuration: 0.2),
            fadeOut,
            remove
        ])
        
        indicator.run(sequence)
    }
}

// Extension for notification handling
extension Notification.Name {
    static let petEvolved = Notification.Name("petEvolved")
}
