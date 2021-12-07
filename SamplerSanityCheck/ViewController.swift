//
//  ViewController.swift
//  SamplerSanityCheck
//
//  Created by Maximilian Maksutovic on 11/23/21.
//

import UIKit
import CoreAudioKit
import AudioKit
import AudioKitEX
import DunneAudioKit
import CDunneAudioKit
import AVFoundation


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        AudioManager.shared.start()
        // Do any additional setup after loading the view.
    }

    @IBAction func tappedPlayRawSampler(_ sender: Any) {
        AudioManager.shared.testSampler(with: .rawSampler)
    }
    
    @IBAction func tappedPlaySFZSampler(_ sender: Any) {
        AudioManager.shared.testSampler(with: .sfzSampler)
    }
}


class AudioManager {
    static let shared = { AudioManager() }()
    let engine = AudioEngine()
    
    let mainMixer: Mixer
    var rawSampler: Sampler = Sampler()
    var sfzSampler: Sampler = Sampler()
    
    init() {
        mainMixer = Mixer(rawSampler,sfzSampler)
        engine.output = mainMixer
    }
    
    public func start() {
        do {
            try engine.start()
            print("Started Audio Engine")
        } catch let error as NSError {
            Log("ERROR: Can't start AudioKit! \(error)")
        }
    }
    
    public func stop() {
        engine.stop()
    }
}

enum SamplerType {
    case rawSampler
    case sfzSampler
}

extension AudioManager {
    func loadSamples() {
        
        guard let rawSampleURL = Bundle.main.url(forResource: "12345", withExtension: "wav") else {
            fatalError("Error: Could not load filepath")
        }
        
        do {
            let wav = try AVAudioFile(forReading: rawSampleURL)
            rawSampler.loadAudioFile(file: wav, rootNote: 57, noteFrequency: 220)
            
        } catch {
            print("Error: Could not load 12345.wav")
        }
        
        let sfzPath = Bundle.main.bundlePath
        sfzSampler = Sampler(sfzPath: sfzPath, sfzFileName: "testSFZ.sfz")
        sfzSampler.masterVolume = 1.0
    }
    
    func testSampler(with type:SamplerType) {
        switch type {
        case .rawSampler:
            playRawSampler(note: MIDINoteNumber(57), velocity: MIDIVelocity(127), channel: MIDIChannel(0))
        case .sfzSampler:
            playSFZSampler(note: MIDINoteNumber(64), velocity: MIDIVelocity(127), channel: MIDIChannel(0))
        }
    }
    
    func playSFZSampler(note: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        sfzSampler.play(noteNumber: note, velocity: velocity, channel: channel)
    }
    
    func stopSFZSampler(note: MIDINoteNumber, channel: MIDIChannel) {
        sfzSampler.stop(noteNumber: note, channel: channel)
    }
    
    func playRawSampler(note: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
        rawSampler.play(noteNumber: note, velocity: velocity, channel: channel)
    }
    
    func stopRawSampler(note: MIDINoteNumber, channel: MIDIChannel) {
        rawSampler.stop(noteNumber: note, channel: channel)
    }
}

