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
    var actionsStack: ActionsStack
    
    init() {
        actionsStack = ActionsStack()
        actionsStack.push(ActionsList())
    }
    
    func moveUp(distance: CGFloat, duration: CGFloat) {
        append(SKAction.moveBy(x: 0, y: distance, duration: duration))
    }
    
    func append(_ action: SKAction) {
        actionsStack.peek()?.append(action)
    }
    
    func group(_ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        actionsStack.pop()
    }
    
    func repeatForever(_ closure: () -> Void) {
        actionsStack.push(ActionsList())
        closure()
        actionsStack.pop()
    }
    
    func moveMyAlienAround() { }
}

class MyAlien: Alien {
    override func moveMyAlienAround() {
        moveUp(distance: 1.0, duration: 1.0)
    }
}
