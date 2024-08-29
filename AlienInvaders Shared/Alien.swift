//
//  Alien.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import SpriteKit

typealias ActionsList = ListHolder<SKAction>
typealias ActionsStack = Stack<ActionsList>

class Alien {
    let offset: CGSize = .zero
    var node: SKSpriteNode!
    var actionsStack = ActionsStack()
    var hitCount = 0
    
    init() {
        node = SKSpriteNode(imageNamed: imageName)
        node.size = GameScene.AlienLayout.size
        node.userData = NSMutableDictionary()
        node.userData!["owner"] = self
    }
    
    // Override these properties and functions in subclass
    
    var imageName: String {
        fatalError("'imageName' must be overridden by a subclass")
    }
    
    func moveMyAlienAround() {
        fatalError("'moveMyAlienAround' must be overridden by a subclass")
    }
    
    func splat() -> [Alien] {
        return []
    }
    
    // Movement functions

    final func moveUp(distance: CGFloat, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: 0, y: distance, duration: duration))
    }
    
    final func moveDown(distance: CGFloat, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: 0, y: -distance, duration: duration))
    }
    
    final func moveLeft(distance: CGFloat, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: -distance, y: 0, duration: duration))
    }
    
    final func moveRight(distance: CGFloat, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: distance, y: 0, duration: duration))
    }
    
    final func moveBy(x: CGFloat, y: CGFloat, duration: CGFloat = 0.25) {
        append(SKAction.moveBy(x: x, y: y, duration: duration))
    }
    
    final func circle(diameter: CGFloat, duration: CGFloat = 0.5) {
        let radius = diameter / 2
        let circlePath = UIBezierPath(
            arcCenter: .zero,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
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
    
    final func run() {
        actionsStack = ActionsStack()
        actionsStack.push(ActionsList())

        moveMyAlienAround()

        let actions = actionsStack.pop()!
        node.run(SKAction.repeatForever(SKAction.sequence(actions.list)))
    }
}

class MyAlien: Alien {
    override func moveMyAlienAround() {
        moveUp(distance: 1.0, duration: 1.0)
    }
}
