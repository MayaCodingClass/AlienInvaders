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
            circle()
            moveRight()
            moveUp()
        }
    }
    
    override func hitSide() {
    }
}

class RedWithHatInvader: Alien {
    override var imageName: String {
        return "RedWithHatInvader"
    }
    
    override func move() {
        moveRight()
        moveUp()
        moveRight()
        moveDown()
        moveRight()
        moveDown()
        moveLeft()
        moveLeft()
        moveLeft()
        moveUp()
    }
    
    override func hitSide() {
    }
}

class TealInvader: Alien {
    override var imageName: String {
        return "TealInvader"
    }
    
    override func move() {
        moveLeft()
        moveDown()
        moveRight()
        moveDown()
    }
    
    override func hitSide() {
    }
}

class SpiderInvader: Alien {
    override var imageName: String {
        return "SpiderInvader"
    }
    
    override func move() {
        group {
            circle()
            moveRight()
        }
    }
    
    override func hitSide() {
    }
}

class RobotInvader: Alien {
    override var imageName: String {
        return "RobotInvader"
    }
    
    override func move() {
        moveUp()
        moveRight()
    }
}

