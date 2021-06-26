//
//  AudioRecordingService.swift
//  Project
//
//  Created by Tanishk Deo on 6/6/21.
//

import Foundation
import AVFoundation

import RxSwift
import RxCocoa


class AudioRecordingService: NSObject, AVAudioRecorderDelegate {
    
    var audioRecorder: AVAudioRecorder!
    
    // private, can only be mutated by the service
    private let _isRecording = BehaviorRelay(value: false)
    
    
    // Observed by others
    var isRecording: Observable<Bool>{
        return _isRecording.asObservable()
    }
    
    
    override init() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord)
            try session.setActive(true)
            session.requestRecordPermission() { granted in
                if granted {
                    print("Granted Microphone Permission")
                } else {
                    print("Denied Microphone Permission")
                }
            }
        } catch {
            print(error)
        }
    }
    
    
    func toggleRecording(for url: URL?) {
        if _isRecording.value {
            stopRecording()
        } else if let url = url {
            startRecording(withURL: url)
        }
    }
    
    func startRecording(withURL url: URL) {
        let settings = [
            AVEncoderBitRateKey: 16,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            _isRecording.accept(true) // Changes state
        } catch {
            print(error)
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        _isRecording.accept(false) // Changes state
    }
    
    
    
    
    
}
