//
//  HomeViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/24/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import NotificationCenter
import AudioKit
import AudioKitUI
//import Speech
import MediaPlayer

class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIViewControllerTransitioningDelegate {
    
//    var data = [viewControllerData(image: #imageLiteral(resourceName: "highlightIcon"), title: "Highlights"), viewControllerData(image: #imageLiteral(resourceName: "settingsIcon"), title: "Settings") ]
	var continueRecording: Bool = true // will only be set at AppDelegate

	var homeViewPresented: Bool = false

    var topButtonCenter: CGPoint!
    var bottomButtonCenter: CGPoint!

    var leftButtonCenter: CGPoint!
    var middleButtonCenter: CGPoint!
    var rightButtonCenter: CGPoint!
    var pickDurationButtonCenter: CGPoint!
    var isRecording = false
    
//    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
//    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
	var appDelegate = UIApplication.shared.delegate as! AppDelegate
	
	let managedObjectContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	//	var audioRecorder: AVAudioRecorder?
	var audioObj: Audio!
    var audioPlayer: AVAudioPlayer?
	//	var audioRecorder: AVAudioRecorder!
	var audioRecorder: myRecorder!
	
	let mic = AKMicrophone()
	var rollingPlot: AKNodeOutputPlot!
    
    private let navBar: UIView = {
        let nav = UIView()
        let titleItem = UILabel()
        nav.addSubview(titleItem)
        titleItem.text = "Home"
        titleItem.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        titleItem.textColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
        titleItem.translatesAutoresizingMaskIntoConstraints = false
        titleItem.centerXAnchor.constraint(equalTo: nav.centerXAnchor).isActive = true
        titleItem.bottomAnchor.constraint(equalTo: nav.bottomAnchor, constant: -15).isActive = true
        return nav
    }()
	
    private let plotView: UIView = {
        let pView = UIView()
        return pView
    }()
    
    private let highlightButton: RoundButton = {
        let button = RoundButton()
        button.cornerRadius = 40
        button.setTitle("H", for: .normal)
        return button
    }()
    
    private let backgroundRecordingButton: RoundButton = {
        let button = RoundButton()
        button.cornerRadius = 40
        button.setTitle("B", for: .normal)
        return button
    }()
    
    private let pickDurationButton: FloatingActionButton = {
        let button = FloatingActionButton()
        button.cornerRadius = 40
        button.setImage(#imageLiteral(resourceName: "expandicon"), for: .normal)
        button.setTitle("D", for: .normal)
        return button
    }()
    
    private let leftButton: RoundButton = {
        let button = RoundButton()
        button.cornerRadius = 30
        button.setTitle(String(Settings.Duration.leftButton.rawValue), for: .normal)
        return button
    }()
    
    private let middleButton: RoundButton = {
        let button = RoundButton()
        button.cornerRadius = 30
        button.setTitle(String(Settings.Duration.middleButton.rawValue), for: .normal)
        return button
    }()
    
    private let rightButton: RoundButton = {
        let button = RoundButton()
        button.cornerRadius = 30
        button.setTitle(String(Settings.Duration.rightButton.rawValue), for: .normal)
        return button
    }()
    
    var buttonsOut = false
    
    var const1: NSLayoutConstraint!
    var const2: NSLayoutConstraint!
    
	var selectedColor: UIColor!
	var disabledColor: UIColor!
	var unSelectedColor: UIColor!
	var appThemeColor: UIColor!
	
	var firstTime: Bool = false

	// MARK: - View Override Functions
	override func viewDidLoad() {
		super.viewDidLoad()
        
        //add views to the main view
        view.addSubview(navBar)
        view.addSubview(highlightButton)
        view.addSubview(plotView)
        view.addSubview(backgroundRecordingButton)
        view.addSubview(pickDurationButton)
        view.addSubview(leftButton)
        view.addSubview(middleButton)
        view.addSubview(rightButton)
		
		//initialize color vars
		selectedColor = Settings.selectedColor
		disabledColor = Settings.disabledColor
		unSelectedColor = Settings.unSelectedColor
		appThemeColor = Settings.appThemeColor
		
        //drop shadow
//        navBar.layer.shadowOpacity = 1
//        navBar.layer.shadowRadius = 5
//        highlightButton.layer.shadowOpacity = 1
//        highlightButton.layer.shadowRadius = 5
//        backgroundRecordingButton.layer.shadowOpacity = 1
//        backgroundRecordingButton.layer.shadowRadius = 5
//        pickDurationButton.layer.shadowOpacity = 1
//        pickDurationButton.layer.shadowRadius = 5
//        leftButton.layer.shadowOpacity = 1
//        leftButton.layer.shadowRadius = 5
//        middleButton.layer.shadowOpacity = 1
//        middleButton.layer.shadowRadius = 5
//        rightButton.layer.shadowOpacity = 1
//        rightButton.layer.shadowRadius = 5
        
        setupBackgroundColors()
        
        //add constraints
        setupNavBarConstraints()
        setupHighlightButtonConstraints()
        setupPlotViewConstraints()
        setupPickDurationButtonConstraints()
        setupBackgroundRecordingButtonConstraints()
        setupLeftButtonConstraints()
        setupMiddleButtonConstraints()
        setupRightButtonConstraints()
        
        highlightButton.setImage(#imageLiteral(resourceName: "recordicon"), for: .normal)
        
//        rightButtonBottomConstraint.isActive = true
//        rightButtonBottomConstraint.constant = 20
        
        //button actions
        highlightButton.addTarget(self, action: #selector(highlightButtonClicked), for: .touchUpInside)
        backgroundRecordingButton.addTarget(self, action: #selector(backgroundRecordingButtonClicked), for: .touchUpInside)
        pickDurationButton.addTarget(self, action: #selector(pickDurationButtonClicked), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(leftButtonClicked), for: .touchUpInside)
        middleButton.addTarget(self, action: #selector(middleButtonClicked), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonClicked), for: .touchUpInside)
        
        zeroAlpha()
        
        leftButtonCenter = leftButton.center
        middleButtonCenter = middleButton.center
        rightButtonCenter = rightButton.center
//
        pickDurationButtonCenter = pickDurationButton.center
        backToCenter()
        
        checkBackgroundRecodingSet()
    
//        disbleRightButtonConstraints()
        
		audioObj = Audio(managedObjectContext)

		let session = AVAudioSession.sharedInstance()
		switch session.recordPermission() {
		case .granted:
			print("Have permission to record")
		case .denied:
			print("Denied permission")
			DispatchQueue.main.async {
				self.performSegue(withIdentifier: "idPermissionSegue", sender: self)
			}
		case .undetermined:
			print("Undetermined")
		}
		
		do {
//			try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
			try session.overrideOutputAudioPort(.speaker)
			try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers /*, .defaultToSpeaker*/])
			try session.setActive(true, with: .notifyOthersOnDeactivation)
		} catch let error {
			print("Error setting up audiosession: \(error.localizedDescription)")
		}
		
		// start recording and start audio kit only the first time but after app loads
		firstTime = true

		let micCopy1 = AKBooster(mic)
		let micCopy2 = AKBooster(mic)
		if let inputs = AudioKit.inputDevices {
			do {
				try AudioKit.setInputDevice(inputs[0])
				try mic.setDevice(inputs[0])
			} catch let error {
				print (error.localizedDescription)
			}
		}
//		let tracker = AKFrequencyTracker(micCopy1, hopSize: 200, peakCount: 2_000)
//		let silence = AKBooster(tracker, gain: 0)
		
		micCopy2.gain = 0
		AudioKit.output = micCopy2
		
		micCopy1.gain = 5.5
		// create rolling waveform plot
        rollingPlot = createRollingPlot(micCopy1)
        
		
        
		plotView.addSubview(rollingPlot)
        
        rollingPlot.translatesAutoresizingMaskIntoConstraints = false
        rollingPlot.topAnchor.constraint(equalTo: plotView.topAnchor).isActive = true
        rollingPlot.leftAnchor.constraint(equalTo: plotView.leftAnchor).isActive = true
        rollingPlot.rightAnchor.constraint(equalTo: plotView.rightAnchor).isActive = true
        rollingPlot.heightAnchor.constraint(equalToConstant: 300).isActive = true
//        setupRollingPlotConstraints()
        
//        startSession()
//		volumeView = MPVolumeView(frame: .null)
//
//		self.view.addSubview(volumeView)
		
		NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.popupSavedHighlight(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
		
		appDelegate.home = self
		
//		if let popupView = Bundle.main.loadNibNamed("CustomPopupView", owner: self, options: nil)?.first as? CustomPopupView {
//			savedPopupView = popupView
//		}
		savedPopupView = CustomPopupView()
	}
	
	var savedPopupView: CustomPopupView?
	
	
	@objc func popupSavedHighlight(notification: NSNotification) {

		DispatchQueue.main.async {
			if let popupObj = self.savedPopupView {
				let popupView = popupObj.contentView!
				self.view.addSubview(popupView)
				popupView.layer.cornerRadius = 10
				popupView.layer.masksToBounds = true
				popupView.translatesAutoresizingMaskIntoConstraints = false
				popupView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
				popupView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
				popupView.widthAnchor.constraint(equalToConstant: popupView.frame.width).isActive = true
				popupView.heightAnchor.constraint(equalToConstant: popupView.frame.height).isActive = true

				DispatchQueue.main.asyncAfter(deadline: .now() + 1.75, execute: {
					popupView.removeFromSuperview()
				})
			}
		}
	}
    
	override func viewDidAppear(_ animated: Bool) {
		print("\(#function)")
		homeViewPresented = true
		disableVolumeHub()
		if firstTime {
			// start recording
			self.firstBeginRecording()
			// start audiokit
			do {
				try AudioKit.start()
			} catch let error {
				print(error.localizedDescription)
			}
			firstTime = false
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		print("\(#function)")
		if rollingPlot.isConnected {
			rollingPlot.resume()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		print("\(#function)")
		homeViewPresented = false
		if rollingPlot.isConnected {
			print("PAUSING ROLLING PLOT")
			rollingPlot.pause()
		}
		enableVolumeHub()
	}
	
	// MARK: - Overriding Volume Buttons
	func disableVolumeHub() {
//		volumeView.showsRouteButton = true
//		volumeView.showsVolumeSlider = true
	}
	func enableVolumeHub() {
//		volumeView.showsRouteButton = false
//		volumeView.showsVolumeSlider = false
	}

	var volumeView: MPVolumeView!
	@objc func volumeChanged(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let volumeChangeType = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String {
				if volumeChangeType == "ExplicitVolumeChange" {
					if homeViewPresented {
						triggerCaptureAction()
					}
				}
			}
		}
	}
	
    
    func zeroAlpha() {
        leftButton.alpha = 0
        middleButton.alpha = 0
        rightButton.alpha = 0
    }
    
    func oneAlpha() {
        leftButton.alpha = 1
        middleButton.alpha = 1
        rightButton.alpha = 1
    }
	
    func setupBackgroundColors() {
        view.backgroundColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
        highlightButton.backgroundColor = unSelectedColor
        pickDurationButton.backgroundColor = unSelectedColor
        navBar.backgroundColor = appThemeColor
        checkCurrSelected()
//        plotView.backgroundColor = .purple
        
    }
    
    func checkCurrSelected() {
        let curr = Settings.currentButtonSelected
        switch curr {
        case "left":
            leftButton.backgroundColor = selectedColor
            middleButton.backgroundColor = unSelectedColor
            rightButton.backgroundColor = unSelectedColor
        case "middle":
            middleButton.backgroundColor = selectedColor
            leftButton.backgroundColor = unSelectedColor
            rightButton.backgroundColor = unSelectedColor
        case "right":
            rightButton.backgroundColor = selectedColor
            leftButton.backgroundColor = unSelectedColor
            middleButton.backgroundColor = unSelectedColor
        default:
            print("CURRENTBUTTONSELECTED FUNCTION ERROR")
        }
    }
    
    
    //Constraints
    
    func setupNavBarConstraints() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        navBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        navBar.heightAnchor.constraint(equalToConstant: 80).isActive = true
        navBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }
    
    
    func setupHighlightButtonConstraints() {
        highlightButton.translatesAutoresizingMaskIntoConstraints = false
        highlightButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        highlightButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        highlightButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        highlightButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150).isActive = true
    }
    
    
    func setupPlotViewConstraints() {
        plotView.translatesAutoresizingMaskIntoConstraints = false
        plotView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        plotView.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
        plotView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        plotView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func setupPickDurationButtonConstraints() {
        pickDurationButton.translatesAutoresizingMaskIntoConstraints = false
        pickDurationButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        pickDurationButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        pickDurationButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
        pickDurationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        
    }
    
    func setupBackgroundRecordingButtonConstraints() {
        backgroundRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        backgroundRecordingButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        backgroundRecordingButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        backgroundRecordingButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
        backgroundRecordingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        
    }
    
    func setupLeftButtonConstraints() {
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        leftButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        leftButton.rightAnchor.constraint(equalTo: pickDurationButton.leftAnchor, constant: -20).isActive = true
        leftButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        
//        leftButton.center = CGPoint(x: pickDurationButton.center.x - 20, y: pickDurationButton.center.y)
    }
    
    func setupMiddleButtonConstraints() {
        middleButton.translatesAutoresizingMaskIntoConstraints = false
        middleButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        middleButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        middleButton.rightAnchor.constraint(equalTo: pickDurationButton.leftAnchor, constant: 14).isActive = true
        middleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -72).isActive = true
//        middleButton.center = CGPoint(x: pickDurationButton.center.x - 20, y: pickDurationButton.center.y - 20)
    }
    
    func setupRightButtonConstraints() {
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        rightButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        const1 = rightButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15)
        const2 = rightButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        
        
//        rightButton.frame = CGRect(x: pickDurationButton.center.x, y: pickDurationButton.center.y - 20, width: 60, height: 60)
        
//        rightButton.center = CGPoint(x: pickDurationButton.center.x, y: pickDurationButton.center.y - 20)
    }
    
    
    func checkBackgroundRecodingSet() {
        let recordInBackground = Settings.continueRecordingInBackground
        if recordInBackground == true {
            backgroundRecordingButton.setImage(#imageLiteral(resourceName: "backgroundonicon"), for: .normal)
            
        } else {
            backgroundRecordingButton.setImage(#imageLiteral(resourceName: "backgroundofficon"), for: .normal)
        }
        backgroundRecordingButton.backgroundColor = Settings.continueRecordingInBackground ? selectedColor : unSelectedColor
    }
    
    /* Button Actions */
    @objc func highlightButtonClicked(_ sender: RoundButton) {
	
        print("RECORDING WITH DURATION: \(Settings.recordingDuration)")
		
		triggerCaptureAction()
    }
	
	func triggerCaptureAction() {
		if audioRecorder.isRecordingHighlight() {
			audioRecorder.stop()
		} else {
			computeHighlight()
			highlightButton.backgroundColor = disabledColor
			highlightButton.isEnabled = false
			DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
				self.highlightButton.isEnabled = true
				self.highlightButton.backgroundColor = self.selectedColor
                self.highlightButton.setImage(#imageLiteral(resourceName: "stopicon"), for: .normal)
			})
		}
	}
	
    
    // FIX WITH ICONS
    @objc func backgroundRecordingButtonClicked(_ sender: RoundButton) {
        let recordInBackground = Settings.continueRecordingInBackground
        if recordInBackground == true {
            backgroundRecordingButton.backgroundColor = unSelectedColor
            backgroundRecordingButton.setImage(#imageLiteral(resourceName: "backgroundofficon"), for: .normal)
            Settings.continueRecordingInBackground = false
            
        } else {
            backgroundRecordingButton.backgroundColor = selectedColor
            backgroundRecordingButton.setImage(#imageLiteral(resourceName: "backgroundonicon"), for: .normal)
            Settings.continueRecordingInBackground = true
        }
        
    }
    
    @objc func pickDurationButtonClicked() {
        pickDurationButtonCenter = pickDurationButton.center
        if buttonsOut {
            UIView.animate(withDuration: 0.3, animations: {
//                self.rightButtonBottomConstraint.constant = 20
                self.pickDurationButton.backgroundColor = self.unSelectedColor
                
                self.const1.isActive = false
                self.const2.isActive = false
                self.zeroAlpha()
                self.backToCenter()
            })
            buttonsOut = false
        } else {
//            disbleRightButtonConstraints()
            UIView.animate(withDuration: 0.3, animations: {
//                self.rightButtonBottomConstraint.constant = -20
                self.pickDurationButton.backgroundColor = self.selectedColor
                self.const1.isActive = true
                self.const2.isActive = true
                self.oneAlpha()
                self.backToPos()
            })
            buttonsOut = true
        }
    }
    
    @objc func leftButtonClicked() {
        Settings.currentButtonSelected = "left"
        Settings.setRecordingDuration(duration: Settings.Duration.leftButton.rawValue)
        checkCurrSelected()
    }
    
    @objc func middleButtonClicked() {
        Settings.currentButtonSelected = "middle"
        Settings.setRecordingDuration(duration: Settings.Duration.middleButton.rawValue)
        checkCurrSelected()
    }

    @objc func rightButtonClicked() {
        Settings.currentButtonSelected = "right"
        Settings.setRecordingDuration(duration: Settings.Duration.rightButton.rawValue)
        checkCurrSelected()
    }
    
    /* Button Actions */
    func backToCenter() {
        leftButton.center = pickDurationButtonCenter
        middleButton.center = pickDurationButtonCenter
        rightButton.center = pickDurationButtonCenter
    }
    
    func backToPos() {
        leftButton.center = leftButtonCenter
        middleButton.center = middleButtonCenter
        rightButton.center = rightButtonCenter
    }

	
    func createRollingPlot(_ inputNode: AKNode) -> AKNodeOutputPlot {
        let frame: CGRect = plotView.frame
		let rplot = AKNodeOutputPlot(inputNode, frame: frame)
		rplot.plotType = .rolling
		rplot.shouldFill = true
		rplot.shouldMirror = true
		rplot.color = UIColorFromRGB(rgbValue: 0x0278AE)
        //Blue theme
//        rplot.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        rplot.backgroundColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
    
		rplot.gain = 1
		
		return rplot
	}
	
	// MARK: - Recording
	func firstBeginRecording() {
		audioObj.deleteAndResetTempData()
		self.beginRecording(recordFile: audioObj.getNextTempFile())
	}
	
	func beginRecording(recordFile: URL) {
		do {
			if FileManager.default.fileExists(atPath: recordFile.path){
				try FileManager.default.removeItem(at: recordFile)
			}
			try audioRecorder = myRecorder(url: recordFile, settings: (audioObj.recordSettings as [String: AnyObject]?)!)
			audioRecorder?.delegate = self
			audioRecorder?.prepareToRecord()
		}catch let error {
			print (error)
		}
		
		if audioRecorder != nil {
			_ = audioRecorder!.record(forDuration: Settings.recordingDuration)
		}
		else {
			print("ERROR: audioRecorder is nil and therefore did not begin recording")
		}
	}
	
	// MARK: - Computing Highlight
	var high1: URL?
	var trimmedHigh1: URL?
	var trimmedHigh1_high2: URL?
	var high2: URL?
	var high3: URL?
	
	func computeHighlight(){
        highlightButton.backgroundColor = selectedColor
        highlightButton.setImage(#imageLiteral(resourceName: "stopicon"), for: .normal)
//        highlightButton.isEnabled = false
		//get current recording time
		let cropTime = audioRecorder?.currentTime
		
		//get current recording file
		high2 = audioRecorder?.url
		
		//stop recording
		audioRecorder?.stop()
		
		if let tmp = audioObj.temp {
			high3 = tmp
			self.beginRecording(recordFile: high3!)
		}
		
		// get old recording file (high1)
		if high2 == audioObj.temp1 {
			high1 = audioObj.temp2
		} else {
			high1 = audioObj.temp1
		}
		
		if FileManager.default.fileExists(atPath: high1!.path) {
			//need to trim
			let asset = AVAsset(url: high1!)
			trimmedHigh1 = audioObj.dataURL?.appendingPathComponent("trimmed.caf")
			audioObj.exportAsset(asset, trimmedSoundFileURL: trimmedHigh1!, cropTime: cropTime!, mergeWith: high2!)
			trimmedHigh1_high2 = audioObj.highlightsURL.appendingPathComponent(audioObj.bothHigh)
		}
		else {
			trimmedHigh1 = nil
		}
	}
	
	func stitchHighlight() throws {
		// then merge all files
		if !FileManager.default.fileExists(atPath: high1!.path) {
			_ = try audioObj.mergeAndAddHighlight2(high2!, high3!, outputFileName: audioObj.getDatetimeString())
		} else {
			_ = try audioObj.mergeAndAddHighlight2(trimmedHigh1_high2!, high3!, outputFileName: audioObj.getDatetimeString())
		}
	}
	
	// MARK: - AudioRecorder Callback
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		
		//		print("finished recording \(recorder.url)")
		//		print()
		
		if high3 != nil {
			if recorder.url == high3! {
				
				//stitch
				do {
					try stitchHighlight()
				} catch let error {
					print (error)
				}
				
				//reset the var until next time
				high3 = nil
				
				if continueRecording {
					self.beginRecording(recordFile: audioObj!.getNextTempFile())
				}

                highlightButton.backgroundColor = unSelectedColor
                self.highlightButton.setImage(#imageLiteral(resourceName: "recordicon"), for: .normal)
			}
		}
		else {
			if continueRecording {
				self.beginRecording(recordFile: audioObj!.getNextTempFile())
			}
		}
	}
	
	// MARK: - Helper Functions
	func printAudioLength(message: String, url: URL) {
		print(message)
		do {
			try audioPlayer = AVAudioPlayer(contentsOf: url)
			print (message)
			print(audioPlayer?.duration ?? -1.0)
		}catch let error{
			print (error)
		}
	}
    
	
/*  func startSession() {
        if let recognitionTask = speechRecognitionTask {
            recognitionTask.cancel()
            self.speechRecognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryRecord)
        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = speechRecognitionRequest else {
            fatalError("SFSpeechAudioBufferRecognitionRequest object creation failed")
        }
        
        let inputNode = audioEngine.inputNode
        
        recognitionRequest.shouldReportPartialResults = true
        speechRecognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {
            result, error in
            
            var finished = false
            if let result = result {
//                self.TranscribingTextView.text = result.bestTranscription.formattedString
                finished = result.isFinal
            }
            
            if error != nil || finished {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.speechRecognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.speechRecognitionRequest?.append(buffer) }
        audioEngine.prepare()
        try! audioEngine.start()
    }*/
}



class myRecorder: AVAudioRecorder {
	var localurl: URL!
	
	let appdelegate = UIApplication.shared.delegate as! AppDelegate
	
	override init(url: URL, settings: [String : Any]) throws {
		try super.init(url: url, settings: settings)
		localurl = url
		appdelegate.audioRecorder = self
//		print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
//		print("Recorder Object Created")
//		print("url: \(url.lastPathComponent)")
//		print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	}
	
	deinit {
//		appdelegate.audioRecorder = nil
//		print("------------------------------------------------------------------")
//		print("Deinit called")
//		print("url: \(url.lastPathComponent)")
//		print("------------------------------------------------------------------")
	}
    
	func isRecordingHighlight() -> Bool {
		if url.lastPathComponent == "temp.caf" {
			return true
		}
		return false
	}
	
	override func record(forDuration duration: TimeInterval) -> Bool {
		print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
		print("Recording to \(localurl.lastPathComponent)")
		print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
		return super.record(forDuration: duration)
	}
	
	override func stop() {
		super.stop()
		print("------------------------------------------------------------------")
		print("Stopped recording to \(localurl.lastPathComponent)")
		print("------------------------------------------------------------------")
	}
}


extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}


func UIColorFromRGB(rgbValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}





