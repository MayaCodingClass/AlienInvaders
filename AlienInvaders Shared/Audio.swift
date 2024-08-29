//
//  Audio.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import AVFoundation

class Audio {
    static let Files = ["laser", "splat", "ui-glitch"]
    
    // Dictionary to hold a pool of AVAudioPlayer instances for each sound
    var audioPlayers: [String: [AVAudioPlayer]] = [:]
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error.localizedDescription)")
        }

        // Preload audio files into the player pools
        for fileName in Audio.Files {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
                print("Failed to find audio file: \(fileName).m4a")
                continue
            }
            
            do {
                // Create a pool of players for each sound
                var playerPool: [AVAudioPlayer] = []
                for _ in 0..<10 { // Adjust the pool size based on expected simultaneous playbacks
                    let audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer.prepareToPlay()
                    playerPool.append(audioPlayer)
                }
                audioPlayers[fileName] = playerPool
            } catch {
                print("Failed to preload audio file: \(fileName).m4a, error: \(error.localizedDescription)")
            }
        }
    }

    func playAudio(name: String) {
        guard let playerPool = audioPlayers[name] else {
            print("Audio player pool not found for file: \(name).m4a")
            return
        }

        // Find the first available player that is not currently playing, otherwise do not play
        if let availablePlayer = playerPool.first(where: { !$0.isPlaying }) {
            availablePlayer.numberOfLoops = 0
            availablePlayer.currentTime = 0 // Start from the beginning
            availablePlayer.play()
        }
    }
}
