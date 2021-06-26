//
//  ViewController.swift
//  Test
//
//  Created by Tanishk Deo on 6/2/21.
//

import UIKit
import AVFoundation
import SnapKit

import RxSwift
import RxCocoa


class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    var viewModel: ViewModel!
    let disposeBag = DisposeBag()
    
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
        setupBindings()
        
        // Ducks Audio when interrupted
        NotificationCenter.default.rx.notification(AVAudioSession.interruptionNotification).withUnretained(self).map({$0.0})
            .subscribe(onNext: {
                if $0.player != nil {
                    $0.player?.setVolume(0.2, fadeDuration: 0.0)
                }
            }).disposed(by: disposeBag)
        
        
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Setup Bindings
    
    private func setupBindings() {
        viewModel.recordTitle.drive(recordButton.rx.title(for: .normal)).disposed(by: disposeBag)
        
        viewModel.isLoading.drive(onNext: { [weak self] loading in
            if loading {
                self?.startLoading()
            } else {
                self?.stopLoading()
            }
        }).disposed(by: disposeBag)
        
        recordButton.rx.tap.withUnretained(self).map({ $0.0 })
            .bind {
                $0.viewModel.recordTapped()
            }.disposed(by: disposeBag)
        
        playButton.rx.tap.withUnretained(self).map({$0.0}).bind {
            $0.player?.play()
            $0.viewModel.playAudio()
        }.disposed(by: disposeBag)
        
        viewModel.speechText.drive(speechTextView.rx.text).disposed(by: disposeBag)
        viewModel.attributedSpeechText.drive(speechTextView.rx.attributedText).disposed(by: disposeBag)
    }
    
    
    
    
    lazy var player = try? AVAudioPlayer(contentsOf: viewModel.getAudioURL(),fileTypeHint: AVFileType.caf.rawValue)
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        viewModel.stopAudio()
    }
    

    
    
    
    
    // MARK: UI Elements
    
    private let instructionTextView: UITextView = {
        let textView = UITextView()
        textView.text = "1. Record, 2. View transcribed text, 3. Play back audio with text highlighting"
        textView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        textView.textColor = .gray
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.adjustsFontForContentSizeCategory = true
        textView.makeAcessibilityElement(trait: .summaryElement, value: textView.text, label: "Instruction Text", hint: "Read")
        return textView
    }()
    
    
    private let speechTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 0.5
        textView.textContainerInset = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 10)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFont.preferredFont(forTextStyle: .headline)
        textView.text = ""
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.makeAcessibilityElement(trait: .updatesFrequently, value: textView.text, label: "Speech Text", hint: "Speak and read")
        return textView
    }()
    
    private let recordButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = Const.cornerRadius
        button.backgroundColor = .buttonColor
        
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.tintColor = .white
        button.makeAcessibilityElement(trait: .button, value: "Record", label: "Record", hint: "Records microphone")
        return button
    }()
    
    private let playButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = Const.cornerRadius
        button.backgroundColor = .buttonColor
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.tintColor = .white
        button.setTitle("Play", for: .normal)
        button.makeAcessibilityElement(trait: .button, value: "Play", label: "Play", hint: "Plays transcribed text")
        return button
    }()
    
    private var loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .medium
        indicator.isHidden = true
        return indicator
    }()
    
    func startLoading() {
        loadingView.isHidden = false
        loadingView.startAnimating()
    }
    
    func stopLoading() {
        loadingView.isHidden = true
        loadingView.stopAnimating()
    }
    
    
    
    // MARK: Setup UI
    
    fileprivate func setupUI() {
        view.backgroundColor = .systemBackground
        player?.delegate = self
        
        let topContainerView = UIView()
        view.addSubview(topContainerView)
        
        
        topContainerView.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.5)
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        
        let stackView = UIStackView()
        
        topContainerView.addSubview(instructionTextView)
        topContainerView.addSubview(speechTextView)
        speechTextView.addSubview(loadingView)
        view.addSubview(stackView)
        
        stackView.addArrangedSubview(recordButton)
        stackView.addArrangedSubview(playButton)
        
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 20.0
        
        instructionTextView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-12)
            make.height.equalTo(100)
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(24)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-24)
        }
        
        
        speechTextView.snp.makeConstraints { make in
            make.top.equalTo(instructionTextView.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(24)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-24)
            
            make.bottom.equalTo(stackView.snp.top).multipliedBy(0.75)
        }
        
        loadingView.snp.makeConstraints { make in
            
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            
        }
        
        stackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(12)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-12)
            make.height.equalTo(50)
        }
        
    }
    
    
    
    
    
    
}


extension UIColor {
    static let buttonColor = UIColor(red: 64/255, green: 100/255, blue: 244/255, alpha: 1.0)
}

extension UIView {
    func makeAcessibilityElement(trait: UIAccessibilityTraits, value: String, label: String, hint: String) {
        self.isAccessibilityElement = true
        self.accessibilityTraits = trait
        self.accessibilityLabel = label
        self.accessibilityHint = hint
        self.accessibilityValue = value
    }
}


struct Const {
    static var cornerRadius: CGFloat = 25.0
    
}
