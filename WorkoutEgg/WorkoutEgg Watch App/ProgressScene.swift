import SpriteKit
import SwiftUI
import UserNotifications

class ProgressScene: SKScene {
    private let barAssetName = "IconsAndLabels/progress-bar-full"
    private let emptyBarAssetName = "IconsAndLabels/progress-bar"
    private var emptyPlate = "food-plate"
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

    private let barScale: CGFloat = 2
    
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
        self.petData = petData
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
        background.setScale(2.2)
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

        emptyBar = SKSpriteNode(texture: emptyBarTexture)
        emptyBar!.size = CGSize(width: barWidth, height: barHeight)
        emptyBar!.position = CGPoint(x: 0, y: 30)
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
        cropNode!.position = CGPoint(x: 0, y: 30)
        cropNode!.zPosition = 1
        addChild(cropNode!)
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
        emptyPlateSprite!.setScale(2.5) // Same scale as progress bar
        addChild(emptyPlateSprite!)
    }

    private func setupCaloriesLabel() {
        caloriesLabel = SKLabelNode(fontNamed: "VCROSDMono")
        caloriesLabel!.fontSize = 16
        caloriesLabel!.fontColor = UIColor(Color("Light1"))
        caloriesLabel!.position = CGPoint(x: 0, y: 60)
        caloriesLabel!.text = "0 / 400 KCal"
        caloriesLabel!.zPosition = 1
        addChild(caloriesLabel!)
        
        // Add stage indicator
        stageLabel = SKLabelNode(fontNamed: "VCROSDMono")
        stageLabel!.fontSize = 12
        stageLabel!.fontColor = UIColor(Color("Light1")).withAlphaComponent(0.8)
        stageLabel!.position = CGPoint(x: 0, y: 80)
        stageLabel!.text = "Stage 1 of 3"
        stageLabel!.zPosition = 1
        addChild(stageLabel!)
    }
    
    private func setupFoodRendered(currentCalories: Int, currentFoodCount: Int) {
        // Remove existing food sprites
        for foodSprite in foodSprites {
            foodSprite.removeFromParent()
        }
        foodSprites.removeAll()
        
        var foodStagesToRender: [Int] = []
        
        // Fix the logical operators - use && instead of ||
        if currentCalories > 200 && currentCalories <= 400 {
            if currentFoodCount == 0 {
                foodStagesToRender = [1]
            } else {
                foodStagesToRender = []
            }
        } else if currentCalories > 400 && currentCalories <= 600 {
            if currentFoodCount == 0 {
                foodStagesToRender = [1, 2]
            } else if currentFoodCount == 1 {
                foodStagesToRender = [2]
            } else {
                foodStagesToRender = []
            }
        } else if currentCalories > 600 {
            if currentFoodCount == 0 {
                foodStagesToRender = [1, 2, 3]
            } else if currentFoodCount == 1 {
                foodStagesToRender = [2, 3]
            } else if currentFoodCount == 2 {
                foodStagesToRender = [3]
            } else {
                foodStagesToRender = []
            }
        }
        
        // Actually render the food sprites
        for (index, stage) in foodStagesToRender.enumerated() {
            let foodTexture = SKTexture(imageNamed: "Food/food-stage-\(stage)")
            if foodTexture.size() != CGSize.zero {
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
                
                foodSprite.position = CGPoint(x: xOffset, y: -60 + yOffset)
                foodSprite.zPosition = 0
                foodSprite.setScale(2) // Scale food smaller than the plate
                
                // Give the food sprite a name for identification
                foodSprite.name = "food-stage-\(stage)"
                
                // Enable user interaction on the food sprite
                foodSprite.isUserInteractionEnabled = false // We'll handle it at scene level
                
                addChild(foodSprite)
                foodSprites.append(foodSprite)
            } else {
                DebugConfig.debugPrint("Failed to load food texture: food-stage-\(stage)")
            }
        }
    }

    // Helper function to get current target based on calories
    private func getCurrentTarget(for calories: Int) -> Int {
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
        
        // Update label with current target
        let currentTarget = getCurrentTarget(for: currentCalories)
        let currentStage = getCurrentStage(for: currentCalories)
        
        caloriesLabel?.text = "\(currentCalories) / \(currentTarget) KCal"
        stageLabel?.text = "Stage \(currentStage) of 3"
        
        // Calculate progress for current stage
        let progress = min(max(getStageProgress(for: currentCalories), 0.0), 1.0)
        if let mask = maskNode {
            mask.size.width = barWidth * progress
        }
        
        // Update food display based on current calories and pet's food count
        let currentFoodCount = petData?.getCurrentDayFeedCount() ?? 0
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
