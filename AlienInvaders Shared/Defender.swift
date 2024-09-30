//
//  Defender.swift
//  AlienInvaders
//
//  Created by Doug on 9/30/24.
//

import SpriteKit

class Defender {
    let gameState: GameState
    var node: SKSpriteNode!

    required init(gameState: GameState) {
        self.gameState = gameState
    }
}
