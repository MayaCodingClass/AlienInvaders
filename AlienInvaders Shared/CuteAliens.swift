//
//  MyCuteAlien.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import Foundation

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
        moveBy(x: 75.0, y: 75.0)
        moveBy(x: 75.0, y: -75.0)
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
        moveBy(x: 75.0, y: 75.0)
        moveBy(x: 75.0, y: -75.0)
    }
    
    override func hitSide() {
        moveDown(distance: 200.0)
    }
}

class RobotAlien: Alien {
    override var imageName: String {
        return "RobotAlien"
    }
    
    override func move() {
        group {
            circle(diameter: 100.0)
            moveDown(distance: 25.0)
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
