import SpriteKit
import SwiftUI
import UserNotifications

class ProgressScene: SKScene {
    private let barAssetName = "IconsAndLabels/progress-bar-full"
    private let emptyBarAssetName = "IconsAndLabels/progress-bar"
    private var emptyPlate = "Food/food-plate"
    private var caloriesLabel: SKLabelNode?
    private var stageLabel: SKLabelNode?
    private let maxCalories: Int = 600 // Maximum achievable calories
    private var currentCalories: Int = 0
    private var petData: PetData? // Reference to pet data

    private var cropNode: SKCropNode?
    private var maskNode: SKSpriteNode?
    private var filledBar: SKSpriteNode?
    private var barWidth: CGFloat = 0
    private var emptyBar: SKSpriteNode?
    private var emptyPlateSprite: SKSpriteNode?
    private var foodSprites: [SKSpriteNode] = []

    private let barScale: CGFloat = 0.5
    
    // Initialize with PetData
    init(petData: PetData?) {
        self.petData = petData
        super.init(size: CGSize.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Method to update pet data reference
    func setPetData(_ petData: PetData?) {
        let previousStage = self.petData?.stage
        self.petData = petData
        
        // If stage changed, update positioning
        if let newStage = petData?.stage, newStage != previousStage {
            updateElementPositions()
        }
    }

    /// Updates the positions of UI elements based on the current pet stage
    private func updateElementPositions() {
        guard let petData = self.petData else { return }
        
        let isEgg = petData.stage == .egg
        let progressBarY: CGFloat = isEgg ? -10 : 30
        let caloriesLabelY: CGFloat = isEgg ? 20 : 60
        let stageLabelY: CGFloat = isEgg ? 40 : 80
        
        // Update progress bar positions
        emptyBar?.position = CGPoint(x: 0, y: progressBarY)
        cropNode?.position = CGPoint(x: 0, y: progressBarY)
        
        // Update label positions
        caloriesLabel?.position = CGPoint(x: 0, y: caloriesLabelY)
        stageLabel?.position = CGPoint(x: 0, y: stageLabelY)
        
        DebugConfig.debugPrint("🔄 Updated element positions for stage: \(petData.stage.displayName)")
        DebugConfig.debugPrint("   - Progress bar: y=\(progressBarY)")
        DebugConfig.debugPrint("   - Calories label: y=\(caloriesLabelY)")
        DebugConfig.debugPrint("   - Stage label: y=\(stageLabelY)")
    }

    override func sceneDidLoad() {
        removeAllChildren()

        // Background
        let background = SKSpriteNode(imageNamed: "background/bg-field")
        if background.texture == nil {
            DebugConfig.debugPrint("Failed to load background image: background/bg-field")
        } else {
            DebugConfig.debugPrint("Successfully loaded background image")
            DebugConfig.debugPrint("Background size: \(background.size)")
        }
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = -1
        background.setScale(0.5)
        addChild(background)

        isUserInteractionEnabled = true
        scaleMode = .aspectFit
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupCaloriesLabel()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // Remove old bar and mask if they exist
        cropNode?.removeFromParent()
        emptyPlateSprite?.removeFromParent()
        filledBar = nil
        maskNode = nil
        cropNode = nil
        emptyPlateSprite = nil
        
        setupProgressBar()
        if let petData = petData, petData.stage != .egg {
            setupEmptyPlate()
        } else {
            DebugConfig.debugPrint("🥚 Egg stage detected - skipping empty plate setup")
        }
        
        // Use pet data's current food count
        let currentFoodCount = petData?.getCurrentDayFeedCount() ?? 0
        setupFoodRendered(currentCalories: currentCalories, currentFoodCount: currentFoodCount)
        updateProgress(current: currentCalories)
    }

    private func setupProgressBar() {
        let emptyBarTexture = SKTexture(imageNamed: emptyBarAssetName)
        let originalBarWidth = emptyBarTexture.size().width
        let originalBarHeight = emptyBarTexture.size().height
        self.barWidth = originalBarWidth * barScale
        let barHeight = originalBarHeight * barScale

        // Position progress bar based on pet stage
        let progressBarY: CGFloat = (petData?.stage == .egg) ? -10 : 30

        emptyBar = SKSpriteNode(texture: emptyBarTexture)
        emptyBar!.size = CGSize(width: barWidth, height: barHeight)
        emptyBar!.position = CGPoint(x: 0, y: progressBarY)
        emptyBar!.zPosition = 0
        addChild(emptyBar!)

        // Filled bar (foreground, masked)
        let filledBarTexture = SKTexture(imageNamed: barAssetName)
        filledBar = SKSpriteNode(texture: filledBarTexture)
        filledBar!.size = CGSize(width: barWidth, height: barHeight)
        filledBar!.anchorPoint = CGPoint(x: 0, y: 0.5)
        filledBar!.position = CGPoint(x: -barWidth / 2, y: 0)
        filledBar!.zPosition = 1

        maskNode = SKSpriteNode(color: .white, size: CGSize(width: barWidth, height: barHeight))
        maskNode!.anchorPoint = CGPoint(x: 0, y: 0.5)
        maskNode!.position = CGPoint(x: -barWidth / 2, y: 0)

        cropNode = SKCropNode()
        cropNode!.maskNode = maskNode
        cropNode!.addChild(filledBar!)
        cropNode!.position = CGPoint(x: 0, y: progressBarY)
        cropNode!.zPosition = 1
        addChild(cropNode!)
        
        DebugConfig.debugPrint("🎯 Progress bar positioned at y: \(progressBarY) for stage: \(petData?.stage.displayName ?? "unknown")")
    }

    private func setupEmptyPlate() {
        // Only create empty plate if asset path is provided
        guard !emptyPlate.isEmpty else { return }
        
        let plateTexture = SKTexture(imageNamed: emptyPlate)
        if plateTexture.size() == CGSize.zero {
            DebugConfig.debugPrint("Failed to load empty plate image: \(emptyPlate)")
            return
        }
        
        emptyPlateSprite = SKSpriteNode(texture: plateTexture)
        emptyPlateSprite!.position = CGPoint(x: 0, y: -60) // Position under the progress bar
        emptyPlateSprite!.zPosition = -0.5 // Behind progress bar but in front of background
        emptyPlateSprite!.setScale(0.2) // Same scale as progress bar
        addChild(emptyPlateSprite!)
    }

    private func setupCaloriesLabel() {
        // Position labels based on pet stage
        let caloriesLabelY: CGFloat = (petData?.stage == .egg) ? 20 : 60
        let stageLabelY: CGFloat = (petData?.stage == .egg) ? 40 : 80

        caloriesLabel = SKLabelNode(fontNamed: "VCROSDMono")
        caloriesLabel!.fontSize = 16
        caloriesLabel!.fontColor = UIColor(Color("Light1"))
        caloriesLabel!.position = CGPoint(x: 0, y: caloriesLabelY)
        caloriesLabel!.text = "0 / 200 KCal"
        caloriesLabel!.zPosition = 1
        addChild(caloriesLabel!)
        
        // Add stage indicator
        stageLabel = SKLabelNode(fontNamed: "VCROSDMono")
        stageLabel!.fontSize = 12
        stageLabel!.fontColor = UIColor(Color("Light1")).withAlphaComponent(0.8)
        stageLabel!.position = CGPoint(x: 0, y: stageLabelY)
        stageLabel!.text = "Stage 1 of 3"
        stageLabel!.zPosition = 1
        
        // Hide stage label for eggs, show for normal pets
        if let petData = self.petData, petData.stage == .egg {
            stageLabel!.isHidden = true
        } else {
            stageLabel!.isHidden = false
        }
        
        addChild(stageLabel!)
        
        DebugConfig.debugPrint("🏷️ Labels positioned - Calories: y=\(caloriesLabelY), Stage: y=\(stageLabelY) for stage: \(petData?.stage.displayName ?? "unknown")")
    }
    
    private func setupFoodRendered(currentCalories: Int, currentFoodCount: Int) {
        // Remove existing food sprites
        for foodSprite in foodSprites {
            foodSprite.removeFromParent()
        }
        foodSprites.removeAll()
        
        DebugConfig.debugPrint("🍎 setupFoodRendered called:")
        DebugConfig.debugPrint("   - currentCalories: \(currentCalories)")
        DebugConfig.debugPrint("   - currentFoodCount: \(currentFoodCount)")
        DebugConfig.debugPrint("   - petData exists: \(petData != nil)")
        DebugConfig.debugPrint("   - pet stage: \(petData?.stage.displayName ?? "nil")")
        
        // Don't render food stages for eggs
        guard let petData = self.petData, petData.stage != .egg else {
            DebugConfig.debugPrint("🥚 Egg stage detected - skipping food rendering")
            return
        }
        
        var foodStagesToRender: [Int] = []
        
        DebugConfig.debugPrint("🍎 Determining food stages to render...")
        
        // Fix the logical operators - use && instead of ||
        if currentCalories > 200 && currentCalories <= 400 {
            DebugConfig.debugPrint("   - Calories range: 201-400")
            if currentFoodCount == 0 {
                foodStagesToRender = [1]
                DebugConfig.debugPrint("   - Feed count 0: showing stage 1")
            } else {
                foodStagesToRender = []
                DebugConfig.debugPrint("   - Feed count \(currentFoodCount): showing no food")
            }
        } else if currentCalories > 400 && currentCalories <= 600 {
            DebugConfig.debugPrint("   - Calories range: 401-600")
            if currentFoodCount == 0 {
                foodStagesToRender = [1, 2]
                DebugConfig.debugPrint("   - Feed count 0: showing stages 1,2")
            } else if currentFoodCount == 1 {
                foodStagesToRender = [2]
                DebugConfig.debugPrint("   - Feed count 1: showing stage 2")
            } else {
                foodStagesToRender = []
                DebugConfig.debugPrint("   - Feed count \(currentFoodCount): showing no food")
            }
        } else if currentCalories > 600 {
            DebugConfig.debugPrint("   - Calories range: 600+")
            if currentFoodCount == 0 {
                foodStagesToRender = [1, 2, 3]
                DebugConfig.debugPrint("   - Feed count 0: showing stages 1,2,3")
            } else if currentFoodCount == 1 {
                foodStagesToRender = [2, 3]
                DebugConfig.debugPrint("   - Feed count 1: showing stages 2,3")
            } else if currentFoodCount == 2 {
                foodStagesToRender = [3]
                DebugConfig.debugPrint("   - Feed count 2: showing stage 3")
            } else {
                foodStagesToRender = []
                DebugConfig.debugPrint("   - Feed count \(currentFoodCount): showing no food")
            }
        } else {
            DebugConfig.debugPrint("   - Calories \(currentCalories) <= 200: no food stages")
        }
        
        DebugConfig.debugPrint("🍎 Final food stages to render: \(foodStagesToRender)")
        
        // Actually render the food sprites
        for (index, stage) in foodStagesToRender.enumerated() {
            let foodTextureName = "Food/food-stage-\(stage)"
            DebugConfig.debugPrint("🍎 Attempting to load: \(foodTextureName)")
            
            let foodTexture = SKTexture(imageNamed: foodTextureName)
            if foodTexture.size() != CGSize.zero {
                DebugConfig.debugPrint("✅ Successfully loaded \(foodTextureName), size: \(foodTexture.size())")
                
                let foodSprite = SKSpriteNode(texture: foodTexture)
                
                // Position food items on the plate - first item is always centered
                let spacing: CGFloat = 30
                var xOffset: CGFloat = 0
                var yOffset: CGFloat = 0
                
                if index == 0 {
                    // First item is always centered
                    xOffset = 0
                    yOffset = 0
                } else if index == 1 {
                    // Second item goes to the right
                    xOffset = spacing
                    yOffset = 10
                } else if index == 2 {
                    // Third item goes to the left
                    xOffset = -spacing
                    yOffset = 10
                }
                
                let finalPosition = CGPoint(x: xOffset, y: -60 + yOffset)
                foodSprite.position = finalPosition
                foodSprite.zPosition = 0
                foodSprite.setScale(0.2) // Scale food smaller than the plate
                
                DebugConfig.debugPrint("🍎 Positioned food stage \(stage) at: \(finalPosition), scale: 2")
                
                // Give the food sprite a name for identification
                foodSprite.name = "food-stage-\(stage)"
                
                // Enable user interaction on the food sprite
                foodSprite.isUserInteractionEnabled = false // We'll handle it at scene level
                
                addChild(foodSprite)
                foodSprites.append(foodSprite)
                
                DebugConfig.debugPrint("✅ Successfully added food sprite \(stage) to scene")
            } else {
                DebugConfig.debugPrint("❌ Failed to load food texture: \(foodTextureName) - texture size is zero")
            }
        }
        
        DebugConfig.debugPrint("🍎 Food rendering complete. Total food sprites: \(foodSprites.count)")
        DebugConfig.debugPrint("🍎 Food sprites in scene: \(foodSprites.map { $0.name ?? "unnamed" })")
    }

    // Helper function to get current target based on calories
    private func getCurrentTarget(for calories: Int) -> Int {
        // For eggs, the target is always 400 KCal (evolution requirement)
        if let petData = self.petData, petData.stage == .egg {
            return 200
        }
        
        // For normal pets, use the progressive system
        if calories <= 200 {
            return 200
        } else if calories <= 400 {
            return 400
        } else {
            return 600
        }
    }
    
    // Helper function to calculate progress for current stage
    private func getStageProgress(for calories: Int) -> CGFloat {
        // For eggs, progress is simply calories/200 (updated evolution requirement)
        if let petData = self.petData, petData.stage == .egg {
            return min(CGFloat(calories) / 200.0, 1.0)
        }
        
        // For normal pets, use the stage-based system
        if calories <= 0 {
            return 0.0
        } else if calories <= 200 {
            // Stage 1: 0 to 200
            return CGFloat(calories) / 200.0
        } else if calories <= 400 {
            // Stage 2: 201 to 400 (show progress from 0 to 100% for this stage)
            return CGFloat(calories - 200) / 200.0
        } else if calories <= 600 {
            // Stage 3: 401 to 600 (show progress from 0 to 100% for this stage)
            return CGFloat(calories - 400) / 200.0
        } else {
            // Max reached
            return 1.0
        }
    }

    // Helper function to get current stage number
    private func getCurrentStage(for calories: Int) -> Int {
        if calories <= 200 {
            return 1
        } else if calories <= 400 {
            return 2
        } else {
            return 3
        }
    }

    // Call this to update the bar and label
    func updateProgress(current: Int) {
        currentCalories = current
        
        DebugConfig.debugPrint("📊 updateProgress called with: \(current) calories")
        
        // Update label with current target
        let currentTarget = getCurrentTarget(for: currentCalories)
        
        caloriesLabel?.text = "\(currentCalories) / \(currentTarget) KCal"
        
        // Only show stage label for non-egg pets
        if let petData = self.petData, petData.stage == .egg {
            stageLabel?.isHidden = true
            DebugConfig.debugPrint("🥚 Hiding stage label for egg")
        } else {
            let currentStage = getCurrentStage(for: currentCalories)
            stageLabel?.text = "Stage \(currentStage) of 3"
            stageLabel?.isHidden = false
        }
        
        // Calculate progress for current stage
        let progress = min(max(getStageProgress(for: currentCalories), 0.0), 1.0)
        if let mask = maskNode {
            mask.size.width = barWidth * progress
        }
        
        // Update food display based on current calories and pet's food count
        let currentFoodCount = petData?.getCurrentDayFeedCount() ?? 0
        DebugConfig.debugPrint("📊 About to call setupFoodRendered with calories: \(currentCalories), feedCount: \(currentFoodCount)")
        setupFoodRendered(currentCalories: currentCalories, currentFoodCount: currentFoodCount)
        
        // Update notification with current calories
        NotificationManager.getCustomizedMessage(calories: currentCalories)
    }
    
    // MARK: - Touch Handling
    
    // Method to handle tap points from SwiftUI (similar to GameScene)
    func onTap(_ point: CGPoint) {
        DebugConfig.debugPrint("Received tap at: \(point)")
        
        // Check if any food sprite was tapped
        for foodSprite in foodSprites {
            if foodSprite.contains(point) {
                handleFoodTap(foodSprite, at: point)
                return
            }
        }
        
        // Show miss indicator if no food was tapped
        showTapIndicator(at: point, success: false)
    }
    
    private func handleFoodTap(_ foodSprite: SKSpriteNode, at location: CGPoint) {
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
        
        // Add feeding animation to the food sprite
        animateFoodConsumption(foodSprite)
        
        // Update the display after feeding
        let displayCalories = petData.stage == .egg ?
            Int(petData.cumulativeCalories) :
            Int(petData.currentDayCalories)
        updateProgress(current: displayCalories)
        
        DebugConfig.debugPrint("🍎 Pet fed! New feed count: \(petData.getCurrentDayFeedCount())")
        DebugConfig.debugPrint("📈 Pet age: \(petData.age), streak: \(petData.streak)")
    }
    
    private func showTapIndicator(at location: CGPoint, success: Bool) {
        // Only show tap indicators in debug mode
        guard DebugConfig.shouldShowTapIndicators else { return }
        
        let indicator = SKShapeNode(circleOfRadius: 8)
        indicator.fillColor = success ? .green : .red
        indicator.strokeColor = .white
        indicator.lineWidth = 2
        indicator.position = location
        indicator.alpha = 0.8
        indicator.zPosition = 100
        
        addChild(indicator)
        
        // Animate the indicator
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
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
    
    private func animateFoodConsumption(_ foodSprite: SKSpriteNode) {
        // Create a "consumption" animation for the food
        let scaleDown = SKAction.scale(to: 0.7, duration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        let rotation = SKAction.rotate(byAngle: .pi / 8, duration: 0.1)
        let rotateBack = SKAction.rotate(byAngle: -.pi / 8, duration: 0.1)
        
        let wiggle = SKAction.sequence([rotation, rotateBack])
        let scale = SKAction.sequence([scaleDown, scaleUp])
        
        let group = SKAction.group([wiggle, scale])
        foodSprite.run(group)
    }
}
