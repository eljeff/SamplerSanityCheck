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
            guard let floatData = wav.toFloatChannelData() else {
                fatalError("Error: Could not unwrap float data")
            }
            let leftChannelFloats = floatData[0]
            let rightChannelFloats = floatData[1]
            let interleavedCount: Int = leftChannelFloats.count + rightChannelFloats.count
            var interleavedFloats = [Float](repeating: 0.0, count: interleavedCount)
            for i in 0..<leftChannelFloats.count {
                if i == 0 {
                    interleavedFloats[i] = leftChannelFloats[i]
                    interleavedFloats[i+1] = rightChannelFloats[i]
                }
                else {
                    let iFloatIndex = i*2
                    interleavedFloats[iFloatIndex] = leftChannelFloats[i]
                    interleavedFloats[iFloatIndex+1] = rightChannelFloats[i]
                }

            }
            
            let floatPointer = UnsafeMutablePointer<Float>.init(mutating: interleavedFloats)
            
            let sampleRate = Float(Settings.sampleRate)
            let desc = SampleDescriptor(noteNumber: 64,
                                        noteFrequency: sampleRate/1000,
                                        minimumNoteNumber: -1,
                                        maximumNoteNumber: -1,
                                        minimumVelocity: -1,
                                        maximumVelocity: -1,
                                        isLooping: false,
                                        loopStartPoint: 0,
                                        loopEndPoint: 1,
                                        startPoint: 0,
                                        endPoint: 0)
            
            let ddesc = SampleDataDescriptor(sampleDescriptor: desc,
                                             sampleRate: sampleRate,
                                             isInterleaved: true,
                                             channelCount: 1,
                                             sampleCount: Int32(interleavedFloats.count),
                                             data: floatPointer)
            rawSampler.loadRawSampleData(from: ddesc)
            rawSampler.setLoop(thruRelease: true)
            rawSampler.buildSimpleKeyMap()
            
        } catch {
            print("Error: Could not load 12345.wav")
        }
        
        DispatchQueue.main.async {
            let sfzPath = Bundle.main.bundlePath
            self.sfzSampler = Sampler(sfzPath: sfzPath, sfzFileName: "testSFZ.sfz")
            self.sfzSampler.masterVolume = 1.0
//            self.sfzSampler.isMonophonic = 0.0
//            self.sfzSampler.loopThruRelease = 0.0
        }
       
    }
    
    func testSampler(with type:SamplerType) {
        switch type {
        case .rawSampler:
            playRawSampler(note: MIDINoteNumber(42), velocity: MIDIVelocity(127), channel: MIDIChannel(0))
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

