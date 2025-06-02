import SpriteKit
import SwiftUI
import UserNotifications

class ProgressScene: SKScene {
    private let barAssetName = "IconsAndLabels/progress-bar-full"
    private let emptyBarAssetName = "IconsAndLabels/progress-bar"
    private var caloriesLabel: SKLabelNode?
    private let targetCalories: Int = 400
    private var currentCalories: Int = 0

    private var cropNode: SKCropNode?
    private var maskNode: SKSpriteNode?
    private var filledBar: SKSpriteNode?
    private var barWidth: CGFloat = 0
    private var emptyBar: SKSpriteNode?

    private let barScale: CGFloat = 2

    override func sceneDidLoad() {
        print("ProgressScene did load")
        removeAllChildren()

        // Background
        let background = SKSpriteNode(imageNamed: "background/bg-field")
        if background.texture == nil {
            print("Failed to load background image: background/bg-field")
        } else {
            print("Successfully loaded background image")
            print("Background size: \(background.size)")
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
        filledBar = nil
        maskNode = nil
        cropNode = nil
        setupProgressBar()
        updateProgress(current: currentCalories)
    }

    private func setupProgressBar() {
        let emptyBarTexture = SKTexture(imageNamed: emptyBarAssetName)
        print("Empty bar texture size: \(emptyBarTexture.size())")
        let originalBarWidth = emptyBarTexture.size().width
        let originalBarHeight = emptyBarTexture.size().height
        self.barWidth = originalBarWidth * barScale
        let barHeight = originalBarHeight * barScale

        emptyBar = SKSpriteNode(texture: emptyBarTexture)
        emptyBar!.size = CGSize(width: barWidth, height: barHeight)
        emptyBar!.position = CGPoint(x: 0, y: 0)
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
        cropNode!.position = CGPoint(x: 0, y: 0)
        cropNode!.zPosition = 1
        addChild(cropNode!)
    }

    private func setupCaloriesLabel() {
        caloriesLabel = SKLabelNode(fontNamed: "VCROSDMono")
        caloriesLabel!.fontSize = 16
        caloriesLabel!.fontColor = UIColor(Color("Light1"))
        caloriesLabel!.position = CGPoint(x: 0, y: 40)
        caloriesLabel!.text = "0 / \(targetCalories) KCal"
        caloriesLabel!.zPosition = 1
        addChild(caloriesLabel!)
    }

    // Call this to update the bar and label
    func updateProgress(current: Int) {
        currentCalories = current
        caloriesLabel?.text = "\(currentCalories) / \(targetCalories) KCal"
        let progress = min(max(CGFloat(currentCalories) / CGFloat(targetCalories), 0.0), 1.0)
        if let mask = maskNode {
            mask.size.width = barWidth * progress
        }
        
        // Update notification with current calories
        NotificationManager.getCustomizedMessage(calories: currentCalories)
    }
}
