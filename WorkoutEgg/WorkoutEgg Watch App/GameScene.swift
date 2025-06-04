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
        
        background.setScale(1)
        
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
        
        // Create new pet sprite with current image/animation
        setupPet()
        
        // Update evolution button visibility
        updateEvolutionButton()
    }
    
    /// Update only the pet animation frames (for emotion changes)
    func updatePetAnimation() {
        guard let petData = self.petData,
              let pet = childNode(withName: "pet") as? SKSpriteNode else { return }
        
        // Only update animation for non-egg pets
        if petData.stage != .egg {
            // Stop current animation
            pet.removeAction(forKey: "idleAnimation")
            
            // Load new animation frames
            let animationFrames = petData.petAnimationFrames
            var textures: [SKTexture] = []
            for framePath in animationFrames {
                let texture = SKTexture(imageNamed: framePath)
                if texture.size() != CGSize.zero {
                    textures.append(texture)
                }
            }
            
            // Start new animation if we have frames
            if textures.count > 1 {
                let idleAnimation = SKAction.animate(with: textures, timePerFrame: 0.5)
                let repeatForever = SKAction.repeatForever(idleAnimation)
                pet.run(repeatForever, withKey: "idleAnimation")
                DebugConfig.debugPrint("Updated idle animation for emotion: \(petData.emotion.displayName)")
            } else if !textures.isEmpty {
                // Set static texture if only one frame
                pet.texture = textures[0]
            }
        }
    }
    
    private func setupPet() {
        DebugConfig.debugPrint("Setting up pet")
        
        // Get the current pet data, fallback to default if no pet data
        guard let petData = self.petData else {
            // Fallback to egg if no pet data
            let pet = SKSpriteNode(imageNamed: "Egg/egg-2-wo-normal")
            configurePetSprite(pet, imageName: "Egg/egg-2-wo-normal")
            return
        }
        
        // Check if this is an egg or an animated pet
        if petData.stage == .egg {
            // Create static egg sprite
            let imageName = petData.petImageName
            let pet = SKSpriteNode(imageNamed: imageName)
            configurePetSprite(pet, imageName: imageName)
        } else {
            // Create animated pet sprite
            createAnimatedPet(petData: petData)
        }
    }
    
    /// Creates an animated pet using the animation frames
    private func createAnimatedPet(petData: PetData) {
        let animationFrames = petData.petAnimationFrames
        
        // Create textures from animation frame paths
        var textures: [SKTexture] = []
        for framePath in animationFrames {
            let texture = SKTexture(imageNamed: framePath)
            if texture.size() != CGSize.zero {
                textures.append(texture)
                DebugConfig.debugPrint("Loaded animation frame: \(framePath)")
            } else {
                DebugConfig.debugPrint("Failed to load animation frame: \(framePath)")
            }
        }
        
        // Create sprite with first frame or fallback to static image
        let pet: SKSpriteNode
        if !textures.isEmpty {
            pet = SKSpriteNode(texture: textures[0])
            
            // Create idle animation if we have multiple frames
            if textures.count > 1 {
                let idleAnimation = SKAction.animate(with: textures, timePerFrame: 0.5) // 0.5 seconds per frame
                let repeatForever = SKAction.repeatForever(idleAnimation)
                pet.run(repeatForever, withKey: "idleAnimation")
                DebugConfig.debugPrint("Started idle animation with \(textures.count) frames")
            }
        } else {
            // Fallback to static image if animation frames fail to load
            let fallbackImageName = petData.petImageName
            pet = SKSpriteNode(imageNamed: fallbackImageName)
            DebugConfig.debugPrint("Using fallback static image: \(fallbackImageName)")
        }
        
        configurePetSprite(pet, imageName: animationFrames.first ?? petData.petImageName)
    }
    
    /// Configures the pet sprite with common properties
    private func configurePetSprite(_ pet: SKSpriteNode, imageName: String) {
        // Debug print to check if image was loaded
        if pet.texture == nil {
            DebugConfig.debugPrint("Failed to load pet image: \(imageName)")
        } else {
            DebugConfig.debugPrint("Pet image loaded successfully: \(imageName)")
            DebugConfig.debugPrint("Pet size: \(pet.size)")
        }
        
        // Keep original size but scale it down to fit
        let scale: CGFloat = 0.2 // Scale down to fit
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
    
    // Function to render evolution button
    private func setupEvolutionButton() {
        // Create evolution button using image asset
        evolutionButton = SKSpriteNode(imageNamed: "evo-btn")
        evolutionButton!.position = CGPoint(x: 0, y: -25)
        evolutionButton!.zPosition = 10
        evolutionButton!.name = "evolution_button"
        
        // Scale the button if needed (adjust this value to make it larger/smaller)
        evolutionButton!.setScale(1)
        
        addChild(evolutionButton!)
        
        // Initially hide the button
        evolutionButton!.isHidden = true
        
        DebugConfig.debugPrint("Evolution button created and hidden")
    }
    
    func updateEvolutionButton() {
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
        
        // Check if this is an egg evolution to play special hatch animation
        if petData.stage == .egg && petData.isReadyToEvolve() {
            playEggHatchAnimation {
                // Complete the evolution after animation
                self.completeEvolution()
            }
        } else {
            // For other stages, evolve normally
            completeEvolution()
        }
    }
    
    private func playEggHatchAnimation(completion: @escaping () -> Void) {
        guard let pet = childNode(withName: "pet") as? SKSpriteNode else {
            completion()
            return
        }
        
        DebugConfig.debugPrint("🥚 Playing egg hatch animation")
        
        // Create animation frames
        let frame1 = SKTexture(imageNamed: "Egg/egg-2-wo-cracked1")
        let frame2 = SKTexture(imageNamed: "Egg/egg-2-wo-cracked2")
        let frames = [frame1, frame2]
        
        // Create animation action
        let animateAction = SKAction.animate(with: frames, timePerFrame: 0.3)
        let repeatAnimation = SKAction.repeat(animateAction, count: 2) // Play twice
        
        // Create completion action
        let completionAction = SKAction.run {
            completion()
        }
        
        // Combine animation and completion
        let sequence = SKAction.sequence([repeatAnimation, completionAction])
        
        // Run the animation on the pet sprite
        pet.run(sequence)
    }
    
    private func completeEvolution() {
        guard let petData = self.petData else { return }
        
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
