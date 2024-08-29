//
//  Audio.swift
//  AlienInvaders
//
//  Created by Doug on 8/26/24.
//

import AVFoundation

class Audio {
    static let Files = ["laser", "splat", "ui-glitch"]

    var audioPlayers: [String: AVAudioPlayer] = [:]

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error.localizedDescription)")
        }

        for fileName in Audio.Files {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
                print("Failed to find audio file: \(fileName).m4a")
                continue
            }
            
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer.prepareToPlay() // Preload the audio into memory
                audioPlayers[fileName] = audioPlayer
            } catch {
                print("Failed to preload audio file: \(fileName).m4a, error: \(error.localizedDescription)")
            }
        }
    }

    func playAudio(name: String, loop: Bool = false) {
        guard let audioPlayer = audioPlayers[name] else {
            print("Audio player not found for file: \(name).m4a")
            return
        }
        
        audioPlayer.numberOfLoops = loop ? -1 : 0 // Set loop if needed
        audioPlayer.play() // Start playback
    }

    func stopAudio(name: String) {
        guard let audioPlayer = audioPlayers[name] else {
            print("Audio player not found for file: \(name).m4a")
            return
        }
        
        audioPlayer.stop() // Stop playback
        audioPlayer.currentTime = 0 // Reset to the beginning of the audio file
    }
}
