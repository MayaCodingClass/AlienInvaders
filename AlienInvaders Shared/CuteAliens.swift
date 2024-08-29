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
    
    override func moveMyAlienAround() {
        moveBy(x: 50.0, y: 50.0)
        moveBy(x: 50.0, y: -50.0)
    }
}

class TealAlien: Alien {
    override var imageName: String {
        return "TealAlien"
    }
    
    override func moveMyAlienAround() {
        moveBy(x: 50.0, y: 50.0)
        moveBy(x: 50.0, y: -50.0)
    }
}

class SpiderAlien: Alien {
    override var imageName: String {
        return "SpiderAlien"
    }
    
    override func moveMyAlienAround() {
        moveBy(x: 50.0, y: 50.0)
        moveBy(x: 50.0, y: -50.0)
    }
}

class RobotAlien: Alien {
    override var imageName: String {
        return "RobotAlien"
    }
    
    override func moveMyAlienAround() {
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

    override func moveMyAlienAround() {
        group {
            circle(diameter: 20.0)
            moveDown(distance: 5.0)
        }
    }
}
