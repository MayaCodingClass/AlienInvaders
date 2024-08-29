//
//  GameScene.swift
//  AlienInvaders Shared
//
//  Created by Doug on 8/23/24.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        scene.configureAudioSession()
        return scene
    }
    
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure and activate audio session: \(error)")
        }
    }

    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let all: UInt32 = UInt32.max
        static let alien: UInt32 = 0x1 << 1
        static let laser: UInt32 = 0x1 << 2
        static let defender: UInt32 = 0x1 << 3
    }
    
    struct Layout {
        let rows: Int
        let columns: Int
        let size: CGSize
        let spacing: CGSize
        
        var totalWidth : CGFloat {
            return CGFloat(columns) * size.width + CGFloat(columns - 1) * spacing.width
        }
        
        func offset(col: Int, row: Int) -> CGPoint {
            return CGPoint(
                x: CGFloat(col) * self.size.width + CGFloat(col) * self.spacing.width,
                y: CGFloat(row) * self.size.height + CGFloat(row) * self.spacing.height
            )
        }
    }
    
    static let AlienLayout = Layout(
        rows: 4,
        columns: 5,
        size: CGSize(width: 40, height: 40),
        spacing: CGSize(width: 20, height: 20)
    )
    
    let audio = Audio()
    
    var defender: SKSpriteNode!
    var laserFiringAction: SKAction!
    var isFiringLaser = false
    var isTouching = false
    var tryingToStartKillingAliens = false
    var shotAtAnAlienForThisTouch = false
    var targetDefenderPosition: CGPoint = .zero
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        setupDefender()
        setupAliens()
    }
    
    func setupDefender() {
        defender = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 20))
        defender.position = CGPoint(x: 0, y: -self.size.height / 2 + defender.size.height + 20) // Very near the bottom
        defender.physicsBody = SKPhysicsBody(rectangleOf: defender.size)
        defender.physicsBody?.isDynamic = false
        defender.physicsBody?.categoryBitMask = PhysicsCategory.defender
        addChild(defender)
    }
    
    func setupAliens() {
        let rows = GameScene.AlienLayout.rows
        let cols = GameScene.AlienLayout.columns
        let totalWidth = GameScene.AlienLayout.totalWidth
        let startX = -totalWidth / 2
        let startY = self.size.height / 2 - 100
        let movement = initialAlienMovement()

        for row in 0..<rows {
            for col in 0..<cols {
                let alien: Alien
                switch row {
                case 0:
                    alien = RedAlien()
                case 1:
                    alien = RobotAlien()
                case 2:
                    alien = TealAlien()
                default:
                    alien = SpiderAlien()
                }
                let offset = GameScene.AlienLayout.offset(col: col, row: row)
                alien.node.position = CGPoint(
                    x: GameScene.AlienLayout.size.width / 2 + startX + offset.x,
                    y: -GameScene.AlienLayout.size.height / 2 + startY - offset.y)

                do {
                    let body = SKPhysicsBody(rectangleOf: GameScene.AlienLayout.size)
                    body.isDynamic = true
                    body.categoryBitMask = PhysicsCategory.alien
                    body.contactTestBitMask = PhysicsCategory.laser
                    body.collisionBitMask = PhysicsCategory.none
                    alien.node.physicsBody = body
                }
                
                addChild(alien.node)
                alien.node.run(movement)
            }
        }
    }
    
    func initialAlienMovement() -> SKAction {
        let alienBoxWidth: CGFloat = 40 * 5 + 20 * (5 - 1)
        let widthMinusAliensWithPadding = self.size.width - alienBoxWidth - 20
        let acrossTime = self.size.width / 400.0

        let moveRight = SKAction.moveBy(x: widthMinusAliensWithPadding / 2, y: 0, duration: acrossTime / 2)
        let moveLeft = SKAction.moveBy(x: -widthMinusAliensWithPadding, y: 0, duration: acrossTime)
        let moveDown = SKAction.moveBy(x: 0, y: -60, duration: 0.25)
        let moveRight2 = SKAction.moveBy(x: widthMinusAliensWithPadding / 2, y: 0, duration: acrossTime / 2)
        let moveSequence = SKAction.sequence([moveRight, moveDown, moveLeft, moveDown, moveRight2])

        return SKAction.repeatForever(moveSequence)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isTouching = true
        tryingToStartKillingAliens = true
        shotAtAnAlienForThisTouch = false
        moveDefender(to: touch.location(in: self))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isTouching = true
        tryingToStartKillingAliens = true
        moveDefender(to: touch.location(in: self))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        stopFiringLaser()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard tryingToStartKillingAliens else { return }

        let distance = abs(defender.position.x - targetDefenderPosition.x)
        
        if distance <= 30 {
            tryingToStartKillingAliens = false
            if isTouching {
                startFiringLaser()
            } else if !shotAtAnAlienForThisTouch {
                fireLaser()
            }
        }
    }

    func moveDefender(to position: CGPoint) {
        targetDefenderPosition = position
        let distance = abs(defender.position.x - position.x)
        defender.run(SKAction.moveTo(x: position.x, duration: min(0.2, CGFloat(distance / 800))))
    }
    
    func startFiringLaser() {
        guard !isFiringLaser else { return }
        isFiringLaser = true
        
        laserFiringAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { self.fireLaser() },
                SKAction.wait(forDuration: 0.3)
            ])
        )
        run(laserFiringAction, withKey: "firingLaser")
    }
    
    func stopFiringLaser() {
        isFiringLaser = false
        removeAction(forKey: "firingLaser")
    }
    
    func fireLaser() {
        shotAtAnAlienForThisTouch = true
        let laser = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 20))
        laser.position = CGPoint(x: defender.position.x, y: defender.position.y + defender.size.height / 2 + laser.size.height / 2)
        
        do {
            let body = SKPhysicsBody(rectangleOf: laser.size)
            body.isDynamic = true
            body.categoryBitMask = PhysicsCategory.laser
            body.contactTestBitMask = PhysicsCategory.alien
            body.collisionBitMask = PhysicsCategory.none
            body.usesPreciseCollisionDetection = true
            laser.physicsBody = body
        }
        
        addChild(laser)
        let moveAction = SKAction.moveTo(y: self.size.height / 2 + laser.size.height, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        laser.run(SKAction.sequence([moveAction, removeAction]))
        
        audio.playAudio(name: "laser")
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody
        let secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.alien && secondBody.categoryBitMask == PhysicsCategory.laser {
            if let alienNode = firstBody.node as? SKSpriteNode, let laser = secondBody.node as? SKSpriteNode {
                laserDidCollideWithAlien(laser: laser, alienNode: alienNode)
            }
        }
    }
    
    func laserDidCollideWithAlien(laser: SKSpriteNode, alienNode: SKSpriteNode) {
        laser.removeFromParent()
        (alienNode.userData!["alien"] as! Alien).wasHit()
        audio.playAudio(name: "splat")
    }
}
