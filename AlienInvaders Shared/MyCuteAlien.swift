//
//  MyCuteAlien.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import Foundation

class MyCuteAlien: Alien {
    override var imageName: String {
        return "cuteAlien"
    }
    
    override func moveMyAlienAround() {
        moveBy(x: 20.0, y: 20.0)
        moveBy(x: 20.0, y: -20.0)
    }
    
    override func splat() -> [Alien] {
        return [
            MyCuteBabyAlien(offset: CGSize(width: -10, height: 10)),
            MyCuteBabyAlien(offset: CGSize(width: 10, height: 10)),
            MyCuteBabyAlien(offset: CGSize(width: -10, height: 0)),
            MyCuteBabyAlien(offset: CGSize(width: 10, height: 0))
        ]
    }
}

class MyCuteBabyAlien: Alien {
    init(offset: CGSize) {
        let size = CGSize(
            width: GameScene.AlienLayout.size.width / 2,
            height: GameScene.AlienLayout.size.height / 2
        )
        super.init(color: .blue, size: size, offset: offset)
    }

    override var imageName: String {
        "cuteAlien"
    }

    override func moveMyAlienAround() {
        group {
            circle(diameter: 20.0)
            moveDown(distance: 5.0)
        }
    }
}
