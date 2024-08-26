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
    var node: SKSpriteNode
    var actionsStack = ActionsStack()
    
    init(color: UIColor, size: CGSize) {
        node = SKSpriteNode(color: color, size: size)
    }
    
    func moveUp(distance: CGFloat, duration: CGFloat = 1.0) {
        append(SKAction.moveBy(x: 0, y: distance, duration: duration))
    }
    
    func moveDown(distance: CGFloat, duration: CGFloat = 1.0) {
        append(SKAction.moveBy(x: 0, y: -distance, duration: duration))
    }
    
    func moveLeft(distance: CGFloat, duration: CGFloat = 1.0) {
        append(SKAction.moveBy(x: -distance, y: 0, duration: duration))
    }
    
    func moveRight(distance: CGFloat, duration: CGFloat = 1.0) {
        append(SKAction.moveBy(x: distance, y: 0, duration: duration))
    }
    
    func moveBy(x: CGFloat, y: CGFloat, duration: CGFloat = 1.0) {
        append(SKAction.moveBy(x: x, y: y, duration: duration))
    }
    
    func circle(diameter: CGFloat, duration: CGFloat = 2.0) {
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

    func square(side: CGFloat, duration: CGFloat = 2.0) {
        moveBy(x: side, y: 0, duration: duration / 4)
        moveBy(x: 0, y: side, duration: duration / 4)
        moveBy(x: -side, y: 0, duration: duration / 4)
        moveBy(x: 0, y: -side, duration: duration / 4)
    }
    
    func append(_ action: SKAction) {
        actionsStack.peek()?.append(action)
    }
    
    func group(_ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        let actions = actionsStack.pop()!
        append(SKAction.group(actions.list))
    }
    
    func sequence(_ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        let actions = actionsStack.pop()!
        append(SKAction.sequence(actions.list))
    }
    
    func repeatFor(count: Int, _ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        let actions = actionsStack.pop()!
        append(SKAction.repeat(SKAction.sequence(actions.list), count: count))
    }
    
    func repeatForever(_ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        let actions = actionsStack.pop()!
        append(SKAction.repeatForever(SKAction.sequence(actions.list)))
    }
    
    func run() {
        actionsStack = ActionsStack()
        actionsStack.push(ActionsList())

        moveMyAlienAround()

        let actions = actionsStack.pop()!
        node.run(SKAction.sequence(actions.list))
    }
    
    func moveMyAlienAround() { }
}

class MyAlien: Alien {
    override func moveMyAlienAround() {
        moveUp(distance: 1.0, duration: 1.0)
    }
}
