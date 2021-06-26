//
//  ViewModel.swift
//  Test
//
//  Created by Tanishk Deo on 6/4/21.
//

import UIKit
import RxSwift
import RxCocoa
import AVFoundation

class ViewModel {
    
    
    // Audio & API Service
    private let audioRecording: AudioRecordingService
    private let service: APIService
    
    // Initialize & Declare Behavior Relays, Observables, and Drivers
    
    private let _isPlaying = BehaviorRelay(value: false)
    
    var isPlaying: Observable<Bool>{
        return _isPlaying.asObservable()
    }
    
    private let _isLoading = BehaviorRelay(value: false)
    
    var isLoading: Driver<Bool> {
        return _isLoading.asDriver(onErrorJustReturn: false)
    }
    
    
    private let _speechText = BehaviorRelay(value: "")
    private let _attributedSpeechText = BehaviorRelay(value: NSAttributedString(string: ""))
    
    var speechText: Driver<String> {
        return _speechText.asDriver(onErrorJustReturn: "")
    }
    
    var attributedSpeechText: Driver<NSAttributedString> {
        return _attributedSpeechText.asDriver(onErrorJustReturn: NSAttributedString(string: ""))
    }
    
    var recordTitle: Driver<String> {
        return audioRecording.isRecording
            .map({ $0 ? "Stop Recording" : "Record" })
            .asDriver(onErrorJustReturn: "")
    }
    
    
    // Dependency Injection
    init(audioService: AudioRecordingService, apiService: APIService) {
        self.audioRecording = audioService
        self.service = apiService
    }
    
    
    let disposeBag = DisposeBag()
    
    var speechTranscription: Model.Transcription? {
        didSet {
            if let alternative = speechTranscription?.results.first?.alternatives.first, let words = alternative.words {
                self.words = words
            }
        }
    }
    
    var words: [Model.Word]? {
        didSet {
            if let words = words {
                self.startTimes = words.map { Double($0.startTime.dropLast())! }
                self.endTimes = words.map { Double($0.endTime.dropLast())!}
            }
        }
    }
    
    var startTimes: [Double]?
    var endTimes: [Double]?
    
    
    func recordTapped() {
        audioRecording.toggleRecording(for: getAudioURL())
        audioRecording.isRecording.subscribe(onNext: { [weak self] recording in
            guard let self = self else {return}
            if recording {
                self._isLoading.accept(true)
                self._speechText.accept("")
            } else {
                self.transcribeRecording()
            }
        }).disposed(by: disposeBag)
        
    }
    
    
    // Calls API and updates accordingly
    
    private func transcribeRecording() {
        service.transcribe(url: getAudioURL()).subscribe(with: self) {
            $0.updateTextForTranscription(transcription: $1) } onError: {
                $0.updateTextForError(error: $1)
            }.disposed(by: disposeBag)
    }
    
    
    // Checks if any start times match
    
    func findWord(startTime: Double) {
        let start = Double(round(10*startTime)/10)
        if let index = self.startTimes?.firstIndex(of: start), let word = self.words?[index], let words = self.words?.map({ $0.word }) {
            highlightWord(index: index, word: word.word, words: words)
        }
    }
    
    // Creates an NSAttributed String with the current word highlighted, updates view through changing Behavior Relay Value
    
    func highlightWord(index: Int, word: String, words: [String]) {
        let beggining = words[0..<index].joined(separator: " ")
        let start = beggining.count == 0 ? 0 : 1
        
        let range = (beggining.count + start)...(beggining.count + word.count)
        
        let attrString = NSAttributedString(string: _speechText.value, attributes: [NSAttributedString.Key.font : UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.label])
        let str = NSMutableAttributedString(attributedString: attrString)
        str.addAttributes([NSAttributedString.Key.backgroundColor : UIColor.buttonColor.withAlphaComponent(0.2)], range: NSRange(range))
        _attributedSpeechText.accept(str)
        
    }
    
    
    // Updates Text After Transcription is Received
    
    func updateTextForTranscription(transcription: Model.Transcription) {
        if let alternative = transcription.results.first?.alternatives.first {
            _speechText.accept(alternative.transcript)
            speechTranscription = transcription
            _isLoading.accept(false)
        }
    }
    
    // Updates Text After Error is Received
    func updateTextForError(error: Error) {
        if let error = error as? CallError, let description = error.description {
            _speechText.accept(description)
            _isLoading.accept(false)
        }
    }
    
    
    private var timer = Timer()
    private var currentTime = 0.0

    
    func playAudio() {
        currentTime = 0.0
        _isPlaying.accept(true)
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
    }
    
    @objc private func updateTimer() {
        currentTime += 0.1
        
        if let end = endTimes?.last, !_isPlaying.value || currentTime >= end {
            timer.invalidate()
            currentTime = 0.0
        }
        
        // Finds & Highlights Word given start time
        
        findWord(startTime: currentTime)
        
    }
    

    func stopAudio() {
        _isPlaying.accept(false)
    }
    
    
    func getAudioURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("audio.caf")
    }
    
}
