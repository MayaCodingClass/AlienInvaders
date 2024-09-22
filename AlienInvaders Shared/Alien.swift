//
//  Alien.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import SpriteKit

typealias ActionsList = ListHolder<SKAction>
typealias ActionsStack = Stack<ActionsList>

enum AlienState {
    case marching, evading, dead
}

class Alien {
    let size: CGSize
    let offset: CGSize = .zero
    var node: SKSpriteNode!
    var actionsStack = ActionsStack()
    var state: AlienState = .marching
    var mirrorX = 1.0
    var mirrorY = 1.0
    
    required init(size: CGSize) {
        self.size = size
        
        node = SKSpriteNode(imageNamed: imageName)
        node.size = GameScene.alienConfig.size
        node.userData = NSMutableDictionary()
        node.userData?["alien"] = self

        node.physicsBody = PhysicsCategory.createPhysicsBody(
            size: GameScene.alienConfig.size,
            categoryBitMask: .alien,
            contactTestBitMask: .laser,
            isDynamic: true)
    }
    
    // Override these properties and functions in subclass
    
    var imageName: String {
        fatalError("'imageName' must be overridden by a subclass")
    }
    
    func move() {
        fatalError("'move' must be overridden by a subclass")
    }
    
    func hitSide() { }
    
    func hitLeftSide() { }
    
    func hitRightSide() { }
    
    func hitTop() { }
    
    func hitBottom() { }
    
    func splat() -> [Alien] {
        return []
    }
    
    // Movement functions

    final func moveUp(distance: CGFloat = 100.0, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: 0, y: distance * mirrorY, duration: duration))
    }
    
    final func moveDown(distance: CGFloat = 100.0, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: 0, y: -distance * mirrorY, duration: duration))
    }
    
    final func moveLeft(distance: CGFloat = 100.0, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: -distance * mirrorX, y: 0, duration: duration))
    }
    
    final func moveRight(distance: CGFloat = 100.0, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: distance * mirrorX, y: 0, duration: duration))
    }
    
    final func moveBy(x: CGFloat, y: CGFloat, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: x * mirrorX, y: y * mirrorY, duration: duration))
    }
    
    final func circle(diameter: CGFloat = 100.0, duration: CGFloat = 0.5) {
        let radius = diameter / 2
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: -radius, y: 0),
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: (mirrorX == 1.0)
        )
        
        let followCircle = SKAction.follow(
            circlePath.cgPath,
            asOffset: true,
            orientToPath: true,
            duration: duration
        )
        
        append(followCircle)
    }

    final func square(side: CGFloat, duration: CGFloat = 0.5) {
        moveBy(x: 0, y: side, duration: duration / 4)
        moveBy(x: -side, y: 0, duration: duration / 4)
        moveBy(x: 0, y: -side, duration: duration / 4)
        moveBy(x: side, y: 0, duration: duration / 4)
    }
    
    final func append(_ action: SKAction) {
        actionsStack.peek()?.append(action)
    }
    
    final func group(_ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        let actions = actionsStack.pop()!
        append(SKAction.group(actions.list))
    }
    
    final func sequence(_ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        let actions = actionsStack.pop()!
        append(SKAction.sequence(actions.list))
    }
    
    final func repeatFor(count: Int, _ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        let actions = actionsStack.pop()!
        append(SKAction.repeat(SKAction.sequence(actions.list), count: count))
    }
    
    final func actionsFor(_ collectActions: () -> Void) -> [SKAction] {
        actionsStack = ActionsStack()
        actionsStack.push(ActionsList())

        collectActions()

        return actionsStack.pop()!.list
    }
    
    final func repeatedActionFor(_ collectActions: () -> Void) -> [SKAction] {
        let actions = actionsFor(collectActions)
        if !actions.isEmpty {
            return [SKAction.repeatForever(SKAction.sequence(actions))]
        } else {
            return []
        }
    }

    final func wasHit() {
        node.removeAllActions()
        var actions = [SKAction]()

        switch state {
        case .marching:
            actions += repeatedActionFor(move)
            state = .evading
        case .evading:
            let newAliens = splat()
            for newAlien in newAliens {
                newAlien.node.position = node.position
                actions += repeatedActionFor(move)
                node.parent?.addChild(newAlien.node)
            }
            node.removeFromParent()
            node.userData!["alien"] = nil
            state = .dead
        case .dead:
            print("That's odd, you hit an already dead alien!")
        }
        
        node.runSequence(actions)
    }
}
