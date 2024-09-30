//
//  GameScene.swift
//  AlienInvaders Shared
//
//  Created by Doug on 8/23/24.
//

import Combine
import SpriteKit
import AVFoundation

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var lives: Int = 3
}

struct PhysicsCategory: OptionSet {
    let rawValue: UInt32
    
    static let none       = PhysicsCategory([])
    static let all        = PhysicsCategory(rawValue: UInt32.max)
    static let defender   = PhysicsCategory(rawValue: 1 << 0)
    static let alien      = PhysicsCategory(rawValue: 1 << 1)
    static let laser      = PhysicsCategory(rawValue: 1 << 2)
    static let edge       = PhysicsCategory(rawValue: 1 << 3)
    
    static func createPhysicsBody(
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
    
    var types: [Alien.Type] = [ TealInvader.self, RedWithHatInvader.self, SpiderInvader.self, RobotInvader.self, Invisivader.self ]
    
    var totalWidth: CGFloat {
        return CGFloat(columns) * size.width + CGFloat(columns - 1) * spacing.width
    }
    
    func calculateOffset(forColumn col: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(col) * (size.width + spacing.width),
            y: CGFloat(row) * (size.height + spacing.height)
        )
    }
}

class GameScene: SKScene {
    
    class func loadNewGameScene() -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        scene.configureScene()
        return scene
    }
    
    static let alienConfig = AlienConfig(
        rows: 5,
        columns: 6,
        size: CGSize(width: 40, height: 40),
        spacing: CGSize(width: 20, height: 20)
    )
    
    let audio = Audio()
    
    var gameState: GameState = GameState()
    private var cancellables = Set<AnyCancellable>()

    var scoreLabel: SKLabelNode!
    var livesLabel: SKLabelNode!

    var gameStarted = false
    var defender: Defender!
    var laserFiringAction: SKAction!
    var isFiringLaser = false
    var isTouching = false
    var tryingToStartKillingAliens = false
    var shotAtAnAlienForThisTouch = false
    var targetDefenderPosition: CGPoint = .zero
//    var edgePhysicsBody: SKPhysicsBody!
    
    func configureScene() {
        scaleMode = .aspectFill
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure and activate audio session: \(error)")
        }
    }
    
    override func didMove(to view: SKView) {
        setupLabels()
        setupPhysicsWorld()
        setupDefender()

        let aliens = setupAliens()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.gameStarted = true
            self.startAlienMovement(aliens: aliens)
        }
        
        audio.playAudio(name: "ui-glitch")
    }

    private func setupLabels() {
        scoreLabel = createRedLabel()
        scoreLabel.position = CGPoint(x: -size.width/2 + 15, y: size.height/2 - 60)
        scoreLabel.horizontalAlignmentMode = .left
        gameState.$score
            .map { "\($0)" }
            .assign(to: \.text, on: scoreLabel)
            .store(in: &cancellables)
        addChild(scoreLabel)

        livesLabel = createRedLabel()
        livesLabel.position = CGPoint(x: size.width/2 - 15, y: size.height/2 - 60)
        livesLabel.horizontalAlignmentMode = .right
        gameState.$lives
            .map { String(repeating: "❤️", count: $0) }
            .assign(to: \.text, on: livesLabel)
            .store(in: &cancellables)
        addChild(livesLabel)
    }
    
    private func createRedLabel() -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial")
        label.fontSize = 24
        label.fontColor = .red
        label.zPosition = 1
        return label
    }
    
    private func setupPhysicsWorld() {
        let body = SKPhysicsBody(edgeLoopFrom: self.frame)
        body.categoryBitMask = PhysicsCategory.edge.rawValue
        body.contactTestBitMask = PhysicsCategory.alien.rawValue
        body.collisionBitMask = 0
        body.isDynamic = true
        body.usesPreciseCollisionDetection = true
        self.physicsBody = body

        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    private func setupDefender() {
        defender = Defender(gameState: gameState)
        defender.node = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 20))
        defender.node.position = CGPoint(x: 0, y: -size.height / 2 + defender.node.size.height + 20)
        defender.node.physicsBody = PhysicsCategory.createPhysicsBody(
            size: defender.node.size,
            categoryBitMask: .defender
        )
        addChild(defender.node)
    }
    
    private func setupAliens() -> [Alien] {
        let config = GameScene.alienConfig
        var aliens: [Alien] = []
        let startX = -config.totalWidth / 2
        let startY = size.height / 2 - 100

        for row in 0..<config.rows {
            for col in 0..<config.columns {
                let alien = config.types[row].init(gameState: gameState, size: config.size)
                let offset = config.calculateOffset(forColumn: col, row: row)

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
    
    private func createInitialAlienMovement() -> SKAction {
        let config = GameScene.alienConfig
        let alienBoxWidth: CGFloat = config.size.width * CGFloat(config.columns) + config.spacing.width * CGFloat(config.columns - 1)
        
        let movementDistance = size.width - alienBoxWidth - 20
        let movementTime = size.width / 200.0

        let moveRight = SKAction.moveBy(x: movementDistance / 2, y: 0, duration: movementTime / 2)
        let moveLeft = SKAction.moveBy(x: -movementDistance, y: 0, duration: movementTime)
        let moveDown = SKAction.moveBy(x: 0, y: -60, duration: 0.25)
        let moveSequence = SKAction.sequence([moveRight, moveDown, moveLeft, moveDown, moveRight])

        return SKAction.repeatForever(moveSequence)
    }
    
    private func startAlienMovement(aliens: [Alien]) {
        let movement = createInitialAlienMovement()
        aliens.forEach { $0.node.run(movement) }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted else { return }
        isTouching = true
        tryingToStartKillingAliens = true
        shotAtAnAlienForThisTouch = false
        moveDefender(to: touches.first!.location(in: self))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted else { return }
        moveDefender(to: touches.first!.location(in: self))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted else { return }
        isTouching = false
        stopFiringLaser()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard tryingToStartKillingAliens else { return }
        
        if abs(defender.node.position.x - targetDefenderPosition.x) <= 30 {
            tryingToStartKillingAliens = false
            if isTouching {
                startFiringLaser()
            } else if !shotAtAnAlienForThisTouch {
                fireLaser()
            }
        }
    }
    
    private func moveDefender(to position: CGPoint) {
        targetDefenderPosition = position
        let distance = abs(defender.node.position.x - position.x)
        defender.node.run(SKAction.moveTo(x: position.x, duration: min(0.2, CGFloat(distance / 800))))
    }
    
    private func startFiringLaser() {
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
    
    private func stopFiringLaser() {
        isFiringLaser = false
        removeAction(forKey: "firingLaser")
    }
    
    private func fireLaser() {
        shotAtAnAlienForThisTouch = true

        let laser = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 20))
        laser.position = CGPoint(
            x: defender.node.position.x,
            y: defender.node.position.y + defender.node.size.height / 2 + laser.size.height / 2
        )
        laser.physicsBody = PhysicsCategory.createPhysicsBody(
            size: laser.size,
            categoryBitMask: .laser,
            contactTestBitMask: .alien,
            isDynamic: true,
            usesPreciseCollisionDetection: true
        )
        addChild(laser)
        
        let moveAction = SKAction.moveTo(y: size.height / 2 + laser.size.height, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        laser.run(SKAction.sequence([moveAction, removeAction]))
        
        audio.playAudio(name: "laser")
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let (firstBody, secondBody) = sortedPhysicsBodies(contact.bodyA, contact.bodyB)

        if isMatch(firstCategory: .alien, secondCategory: .laser, firstBody: firstBody, secondBody: secondBody) {
            if let alienNode = firstBody.node as? SKSpriteNode,
               let laserNode = secondBody.node as? SKSpriteNode {
                handleLaserCollision(with: laserNode, hitting: alienNode)
            }
        } else if isMatch(firstCategory: .alien, secondCategory: .edge, firstBody: firstBody, secondBody: secondBody) {
            if let alienNode = firstBody.node as? SKSpriteNode {
                handleAlienCollisionWithEdge(contactPoint: contact.contactPoint, alienNode: alienNode)
            }
        }
    }
    
    private func sortedPhysicsBodies(_ bodyA: SKPhysicsBody, _ bodyB: SKPhysicsBody) -> (SKPhysicsBody, SKPhysicsBody) {
        return bodyA.categoryBitMask < bodyB.categoryBitMask ? (bodyA, bodyB) : (bodyB, bodyA)
    }

    private func isMatch(firstCategory: PhysicsCategory, secondCategory: PhysicsCategory, firstBody: SKPhysicsBody, secondBody: SKPhysicsBody) -> Bool {
        return firstBody.categoryBitMask == firstCategory.rawValue && secondBody.categoryBitMask == secondCategory.rawValue
    }
    
    private func handleLaserCollision(with laser: SKSpriteNode, hitting alienNode: SKSpriteNode) {
        laser.removeFromParent()
        if let alien = alienNode.userData?["alien"] as? Alien {
            alien.wasHit()
        }
        audio.playAudio(name: "splat")
    }
    
    private func handleAlienCollisionWithEdge(contactPoint: CGPoint, alienNode: SKSpriteNode) {
        guard let alien = alienNode.userData?["alien"] as? Alien else { return }
        
        alienNode.removeAllActions()
        var actions: [SKAction] = []

        let frame = self.frame
        let pad = 3.0
        if (contactPoint.x - pad) <= frame.minX {
            alien.mirrorX = -alien.mirrorX
            actions += alien.actionsFor(alien.hitSide)
            actions += alien.actionsFor(alien.hitLeftSide)
        } else if (contactPoint.x + pad) >= frame.maxX {
            alien.mirrorX = -alien.mirrorX
            actions += alien.actionsFor(alien.hitSide)
            actions += alien.actionsFor(alien.hitRightSide)
        }
        
        if (contactPoint.y - pad) <= frame.minY {
            alien.mirrorY = -alien.mirrorY
            actions += alien.actionsFor(alien.hitBottom)
        } else if (contactPoint.y + pad) >= frame.maxY {
            alien.mirrorY = -alien.mirrorY
            actions += alien.actionsFor(alien.hitTop)
        }
        
        actions += alien.repeatedActionFor(alien.move)
        alienNode.runSequence(actions)
    }
}

extension SKSpriteNode {
    func runSequence(_ actions: [SKAction]) {
        switch actions.count {
        case 0:
            break
        case 1:
            run(actions[0])
        default:
            run(SKAction.sequence(actions))
        }
    }
}
