//
//  GameScene.swift
//  AlienInvaders Shared
//
//  Created by Doug on 8/23/24.
//

import SpriteKit
import AVFoundation

struct PhysicsCategory: OptionSet {
    let rawValue: UInt32
    
    static let none       = PhysicsCategory([])
    static let all        = PhysicsCategory(rawValue: UInt32.max)
    static let defender   = PhysicsCategory(rawValue: 1 << 0)
    static let alien      = PhysicsCategory(rawValue: 1 << 1)
    static let laser      = PhysicsCategory(rawValue: 1 << 2)
    static let edge       = PhysicsCategory(rawValue: 1 << 3)
    
    static func physicsBody(
        size: CGSize,
        categoryBitMask: PhysicsCategory,
        contactTestBitMask: PhysicsCategory = .none,
        isDynamic: Bool = false,
        usesPreciseCollisionDetection: Bool = true
    ) -> SKPhysicsBody {
        let body = SKPhysicsBody(rectangleOf: size)
        body.categoryBitMask = categoryBitMask.rawValue
        body.contactTestBitMask = contactTestBitMask.rawValue
        body.collisionBitMask = PhysicsCategory.none.rawValue
        body.isDynamic = isDynamic
        body.usesPreciseCollisionDetection = usesPreciseCollisionDetection
        return body
    }
}

struct AlienConfig {
    let rows: Int
    let columns: Int
    let size: CGSize
    let spacing: CGSize
    
    var types: [Alien.Type] = [RedAlien.self, RobotAlien.self, TealAlien.self, SpiderAlien.self]
    
    var totalWidth : CGFloat {
        return CGFloat(columns) * size.width + CGFloat(columns - 1) * spacing.width
    }
    
    func offset(col: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(col) * size.width + CGFloat(col) * spacing.width,
            y: CGFloat(row) * size.height + CGFloat(row) * spacing.height
        )
    }
}

class GameScene: SKScene {
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        scene.configure()
        return scene
    }
    
    static let alienConfig = AlienConfig(
        rows: 4,
        columns: 5,
        size: CGSize(width: 40, height: 40),
        spacing: CGSize(width: 20, height: 20)
    )
    
    let audio = Audio()
    
    var gameStarted = false
    var defender: SKSpriteNode!
    var laserFiringAction: SKAction!
    var isFiringLaser = false
    var isTouching = false
    var tryingToStartKillingAliens = false
    var shotAtAnAlienForThisTouch = false
    var targetDefenderPosition: CGPoint = .zero
    
    func configure() {
        scaleMode = .aspectFill
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure and activate audio session: \(error)")
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        setupDefender()
        let aliens = setupAliens()
        
        audio.playAudio(name: "ui-glitch")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.gameStarted = true
            self.startMoving(aliens: aliens)
        }
    }
    
    func setupDefender() {
        defender = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 20))
        defender.position = CGPoint(x: 0, y: -self.size.height / 2 + defender.size.height + 20)
        defender.physicsBody = PhysicsCategory.physicsBody(
            size: defender.size,
            categoryBitMask: .defender
        )
        addChild(defender)
    }
    
    func setupAliens() -> [Alien] {
        let config = GameScene.alienConfig
        var aliens: [Alien] = []
        let startX = -config.totalWidth / 2
        let startY = self.size.height / 2 - 100

        for row in 0..<config.rows {
            for col in 0..<config.columns {
                let alien = config.types[row].init()
                let offset = config.offset(col: col, row: row)

                alien.node.position = CGPoint(
                    x: config.size.width / 2 + startX + offset.x,
                    y: -config.size.height / 2 + startY - offset.y
                )
                
                addChild(alien.node)
                aliens.append(alien)
            }
        }
        
        return aliens
    }
    
    func initialAlienMovement() -> SKAction {
        let config = GameScene.alienConfig
        let alienBoxWidth: CGFloat =
            config.size.width * CGFloat(config.rows) +
            config.spacing.width * CGFloat(config.rows - 1)
        
        let widthMinusAliensWithPadding = self.size.width - alienBoxWidth - 20
        let acrossTime = self.size.width / 400.0

        let moveRight = SKAction.moveBy(x: widthMinusAliensWithPadding / 2, y: 0, duration: acrossTime / 2)
        let moveLeft = SKAction.moveBy(x: -widthMinusAliensWithPadding, y: 0, duration: acrossTime)
        let moveDown = SKAction.moveBy(x: 0, y: -60, duration: 0.25)
        let moveRight2 = SKAction.moveBy(x: widthMinusAliensWithPadding / 2, y: 0, duration: acrossTime / 2)
        let moveSequence = SKAction.sequence([moveRight, moveDown, moveLeft, moveDown, moveRight2])

        return SKAction.repeatForever(moveSequence)
    }
    
    func startMoving(aliens: [Alien]) {
        let movement = initialAlienMovement()
        for alien in aliens {
            alien.node.run(movement)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted else { return }
        guard let touch = touches.first else { return }
        isTouching = true
        tryingToStartKillingAliens = true
        shotAtAnAlienForThisTouch = false
        moveDefender(to: touch.location(in: self))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted else { return }
        guard let touch = touches.first else { return }
        isTouching = true
        tryingToStartKillingAliens = true
        moveDefender(to: touch.location(in: self))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted else { return }
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
        laser.position = CGPoint(
            x: defender.position.x,
            y: defender.position.y + defender.size.height / 2 + laser.size.height / 2
        )
        laser.physicsBody = PhysicsCategory.physicsBody(
            size: laser.size,
            categoryBitMask: .laser,
            contactTestBitMask: .alien,
            isDynamic: true,
            usesPreciseCollisionDetection: true
        )
        addChild(laser)
        
        let moveAction = SKAction.moveTo(y: self.size.height / 2 + laser.size.height, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        laser.run(SKAction.sequence([moveAction, removeAction]))
        
        audio.playAudio(name: "laser")
    }
}

extension GameScene: SKPhysicsContactDelegate {
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
        
        if firstBody.categoryBitMask == PhysicsCategory.alien.rawValue &&
           secondBody.categoryBitMask == PhysicsCategory.laser.rawValue {
            if let alienNode = firstBody.node as? SKSpriteNode,
               let laserNode = secondBody.node as? SKSpriteNode {
                laserDidCollideWithAlien(laser: laserNode, alienNode: alienNode)
            }
        }
    }
    
    func laserDidCollideWithAlien(laser: SKSpriteNode, alienNode: SKSpriteNode) {
        laser.removeFromParent()
        if let alien = alienNode.userData?["alien"] as? Alien {
            alien.wasHit()
        }
        audio.playAudio(name: "splat")
    }
}
