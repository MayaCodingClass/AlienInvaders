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
        
        return scene
    }
    
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let all: UInt32 = UInt32.max
        static let alien: UInt32 = 0x1 << 1
        static let laser: UInt32 = 0x1 << 2
        static let defender: UInt32 = 0x1 << 3
    }
    
    var defender: SKSpriteNode!
    var aliens: [SKSpriteNode] = []
    var laserFiringAction: SKAction!
    var isFiringLaser = false
    var currentTouchLocation: CGPoint?
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        setupDefender()
        setupAliens()
        startAlienMovement() // Start continuous movement for aliens
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
        let rows = 4
        let cols = 5
        let alienSize = CGSize(width: 40, height: 40)
        let spacing = CGSize(width: 20, height: 20)
        let totalWidth = CGFloat(cols) * alienSize.width + CGFloat(cols - 1) * spacing.width
        let startX = -totalWidth / 2
        
        for row in 0..<rows {
            for col in 0..<cols {
                let alien = SKSpriteNode(color: .green, size: alienSize)
                let xOffset = CGFloat(col) * (alienSize.width + spacing.width)
                let yOffset = CGFloat(row) * (alienSize.height + spacing.height)
                alien.position = CGPoint(
                    x: alienSize.width / 2 + startX + xOffset,
                    y:  -alienSize.height / 2 + self.size.height / 2 - 100 - yOffset)
                alien.physicsBody = SKPhysicsBody(rectangleOf: alienSize)
                alien.physicsBody?.isDynamic = true
                alien.physicsBody?.categoryBitMask = PhysicsCategory.alien
                alien.physicsBody?.contactTestBitMask = PhysicsCategory.laser
                alien.physicsBody?.collisionBitMask = PhysicsCategory.none
                addChild(alien)
                aliens.append(alien)
            }
        }
    }
    
    func startAlienMovement() {
        let alienBoxWidth: CGFloat = 40 * 5 + 20 * (5 - 1)
        let widthMinusAliensWithPadding = self.size.width - alienBoxWidth - 20

        let moveRight = SKAction.moveBy(x: widthMinusAliensWithPadding / 2, y: 0, duration: 2)
        let moveLeft = SKAction.moveBy(x: -widthMinusAliensWithPadding, y: 0, duration: 4)
        let moveDown = SKAction.moveBy(x: 0, y: -60, duration: 0.25)
        let moveRight2 = SKAction.moveBy(x: widthMinusAliensWithPadding / 2, y: 0, duration: 2)
        let moveSequence = SKAction.sequence([moveRight, moveDown, moveLeft, moveDown, moveRight2])
        let repeatMovement = SKAction.repeatForever(moveSequence)
        
        for alien in aliens {
            alien.run(repeatMovement)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentTouchLocation = touch.location(in: self)
        moveDefender(to: currentTouchLocation!)
        startFiringLaser()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentTouchLocation = touch.location(in: self)
        moveDefender(to: currentTouchLocation!)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopFiringLaser()
    }
    
    func moveDefender(to position: CGPoint) {
        let moveAction = SKAction.moveTo(x: position.x, duration: 0.2)
        defender.run(moveAction)
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
        let laser = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 20))
        laser.position = CGPoint(x: defender.position.x, y: defender.position.y + defender.size.height / 2 + laser.size.height / 2)
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.isDynamic = true
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.alien
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none
        laser.physicsBody?.usesPreciseCollisionDetection = true
        addChild(laser)
        
        let moveAction = SKAction.moveTo(y: self.size.height / 2 + laser.size.height, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        laser.run(SKAction.sequence([moveAction, removeAction]))
        
        run(SKAction.playSoundFileNamed("laser.m4a", waitForCompletion: false))
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
            if let alien = firstBody.node as? SKSpriteNode, let laser = secondBody.node as? SKSpriteNode {
                laserDidCollideWithAlien(laser: laser, alien: alien)
            }
        }
    }
    
    func laserDidCollideWithAlien(laser: SKSpriteNode, alien: SKSpriteNode) {
        laser.removeFromParent()
        alien.removeFromParent()
        
        run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
    }
}
