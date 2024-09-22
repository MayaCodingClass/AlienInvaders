//
//  MyCuteAlien.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import Foundation

class Invisivader: Alien {
    override var imageName: String {
        return "Invisivader"
    }
    
    override func move() {
        group {
            moveBy(x: 0.0, y: -50.0)
            circle(diameter: 40.0)
        }
    }
}

class RedHead: Alien {
    override var imageName: String {
        return "RedHead"
    }
    
    override func move() {
        moveBy(x: 100.0, y: 0.0)
        moveBy(x: -100.0, y: -100.0)
    }
}

class RedAlien: Alien {
    override var imageName: String {
        return "RedAlien"
    }
    
    override func move() {
        moveBy(x: 75.0, y: 75.0)
        moveBy(x: 75.0, y: -75.0)
    }
    
    override func hitSide() {
        moveDown(distance: 200.0)
    }
}

class TealAlien: Alien {
    override var imageName: String {
        return "TealAlien"
    }
    
    override func move() {
        square(side: 100.0)
        moveBy(x: 0, y: -100)
    }
    
    override func hitSide() {
        moveDown(distance: 200.0)
    }
}

class SpiderAlien: Alien {
    override var imageName: String {
        return "SpiderAlien"
    }
    
    override func move() {
        group {
            moveDown()
            moveRight()
        }
        group {
            moveUp()
            moveRight()
        }
    }
    
    override func hitSide() {
        moveDown()
    }
}

class RobotAlien: Alien {
    override var imageName: String {
        return "RobotAlien"
    }
    
    override func move() {
        group {
            circle()
            moveLeft()
            moveDown()
        }
        group {
            circle()
            moveLeft()
            moveUp()
        }
    }
}

class BabyAlien: Alien {
    override var imageName: String {
        "CuteAlien"
    }

    override func move() {
        group {
            circle(diameter: 20.0)
            moveDown(distance: 5.0)
        }
    }
}
