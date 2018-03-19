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
    
	var homeViewPresented: Bool = false

    var topButtonCenter: CGPoint!
    var bottomButtonCenter: CGPoint!
    var leftButtonCenter: CGPoint!
    var rightButtonCenter: CGPoint!
    var highlightButtonCenter: CGPoint!
    var isRecording = false
    
//    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
//    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    

	let managedObjectContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	//	var audioRecorder: AVAudioRecorder?
	var audioObj: Audio!
    var audioPlayer: AVAudioPlayer?
	//	var audioRecorder: AVAudioRecorder!
	var audioRecorder: myRecorder!
	
	let mic = AKMicrophone()
	var rollingPlot: AKNodeOutputPlot!
	
    var plotView: UIView = {
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
    
    private let pickDurationButton: RoundButton = {
        let button = RoundButton()
        button.cornerRadius = 40
        button.setTitle("D", for: .normal)
        return button
    }()
    
    var buttonsOut = false
    var buttonsConstraintsSet = false
    
	override func viewDidLoad() {
        
		super.viewDidLoad()
        
        //add views to the main view
        view.addSubview(highlightButton)
        view.addSubview(plotView)
        view.addSubview(backgroundRecordingButton)
        view.addSubview(pickDurationButton)
        
        
        setupBackgroundColors()
        
        //add constraints
        setupHighlightButtonConstraints()
        setupPlotViewConstraints()
        setupPickDurationButtonConstraints()
        setupBackgroundRecordingButtonConstraints()
        
        //button actions
        highlightButton.addTarget(self, action: #selector(highlightButtonClicked), for: .touchUpInside)
        backgroundRecordingButton.addTarget(self, action: #selector(backgroundRecordingButtonClicked), for: .touchUpInside)
        pickDurationButton.addTarget(self, action: #selector(pickDurationButtonClicked), for: .touchUpInside)
        
        //drop shadow
        highlightButton.layer.shadowOpacity = 1
        highlightButton.layer.shadowRadius = 5
        backgroundRecordingButton.layer.shadowOpacity = 1
        backgroundRecordingButton.layer.shadowRadius = 5
        pickDurationButton.layer.shadowOpacity = 1
        pickDurationButton.layer.shadowRadius = 5
        
        
        
        
        
//        self.zeroAlpha()
        
//        topButtonCenter = topButton.center
//        bottomButtonCenter = bottomButton.center
//        leftButtonCenter = leftButton.center
//        rightButtonCenter = rightButton.center
//
//        highlightButtonCenter = highlightButton.center
////        highlightButtonCenter = CGPoint(x: mainView.center.x + 10, y: highlightButton.center.y)
//
//        print("top center \(topButtonCenter)")
//        print("bottom center \(bottomButtonCenter)")
//        print("left center \(leftButtonCenter)")
//        print("right center \(rightButtonCenter)")
//        print("highlight center \(highlightButtonCenter)")
//        print("highlight center 2 \(highlightButton.center)")
//
////        highlightButton.center = highlightButtonCenter
//        topButton.center = highlightButtonCenter
//        bottomButton.center = highlightButtonCenter
//        leftButton.center = highlightButtonCenter
//        rightButton.center = highlightButtonCenter
//
//        print("top center \(topButton.center)")
//        print("bottom center \(bottomButton.center)")
//        print("left center \(leftButton.center)")
//        print("right center \(rightButton.center)")
//        print("highlight center \(highlightButton.center)")
//
       
//        topButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
//        bottomButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
//        leftButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
//        rightButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
        
		
		audioObj = Audio(managedObjectContext)
		
		//delete highlights folder
		//		audioObj.deleteAllHighlights()
		
		//waveform
		//		createWaveform()
		
		self.beginRecording(recordFile: audioObj.getNextTempFile())
		
		let micCopy1 = AKBooster(mic)
//		let micCopy2 = AKBooster(mic)
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
		
		
//		AudioKit.output = nil
        do {
            try AudioKit.start()
        } catch let error {
            print(error.localizedDescription)
        }
		
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
		volumeView = MPVolumeView(frame: .null)
//		volumeView.showsRouteButton = true
//		volumeView.showsVolumeSlider = true
		self.view.addSubview(volumeView)
		
		NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
		
	}
	func disableVolumeHub() {
		volumeView.showsRouteButton = true
		volumeView.showsVolumeSlider = true
	}
	func enableVolumeHub() {
		volumeView.showsRouteButton = false
		volumeView.showsVolumeSlider = false
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
	
//	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//		if keyPath == "outputVolume" {
//			print("got in here2")
//		}
//	}
	
    
//    func zeroAlpha() {
//        leftButton.alpha = 0
//        rightButton.alpha = 0
//        topButton.alpha = 0
//        bottomButton.alpha = 0
//    }
//
//    func oneAlpha() {
//        leftButton.alpha = 1
//        rightButton.alpha = 1
//        topButton.alpha = 1
//        bottomButton.alpha = 1
//    }
    

    func setupBackgroundColors() {
        view.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        highlightButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
        pickDurationButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
        backgroundRecordingButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
//        plotView.backgroundColor = .purple
        
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
        plotView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
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
			highlightButton.backgroundColor = UIColorFromRGB(rgbValue: 0xFF467E)
		}
	}
    
    // FIX WITH ICONS
    @objc func backgroundRecordingButtonClicked(_ sender: RoundButton) {
        let recordInBackground = Settings.continueRecordingInBackground
        
        if recordInBackground == true {
            backgroundRecordingButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
            Settings.continueRecordingInBackground = false
        } else {
            backgroundRecordingButton.backgroundColor = UIColorFromRGB(rgbValue: 0xFF467E)
            Settings.continueRecordingInBackground = true
        }
        
    }
    
    @objc func pickDurationButtonClicked() {
        
    }
    
    /* Button Actions */
    
    
//
//    @IBAction func topButtonClicked(_ sender: RoundButton) {
//        Settings.recordingDuration = Settings.Duration.topButton.rawValue
//        print("RECORDING DURATION: \(Settings.recordingDuration)")
//        computeHighlight()
//        UIView.animate(withDuration: 0.3, animations: {
//            self.backToCenter()
//            self.zeroAlpha()
//        })
//    }

//
//    func setButtonsTitle() {
//        leftButton.setTitle(String(Settings.Duration.leftButton.rawValue), for: .normal)
//        topButton.setTitle(String(Settings.Duration.topButton.rawValue), for: .normal)
//        rightButton.setTitle(String(Settings.Duration.rightButton.rawValue), for: .normal)
//        bottomButton.setTitle(String(Settings.customDuration), for: .normal)
//    }

	
    func createRollingPlot(_ inputNode: AKNode) -> AKNodeOutputPlot {
        let frame: CGRect = plotView.frame
		let rplot = AKNodeOutputPlot(inputNode, frame: frame)
		rplot.plotType = .rolling
		rplot.shouldFill = true
		rplot.shouldMirror = true
		rplot.color = UIColorFromRGB(rgbValue: 0xFFFFFF)
        //Blue theme
//        rplot.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        rplot.backgroundColor = .yellow
    
		rplot.gain = 1
		
		return rplot
	}
    
	
	override func viewDidAppear(_ animated: Bool) {
		print("\(#function)")
		homeViewPresented = true
		disableVolumeHub()
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
			rollingPlot.pause()
		}
		enableVolumeHub()
	}
	
	// MARK: - Recording
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
			audioRecorder!.record(forDuration: Settings.recordingDuration)
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
        highlightButton.backgroundColor = UIColorFromRGB(rgbValue: 0xFF467E)
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
				
				self.beginRecording(recordFile: audioObj!.getNextTempFile())
//                highlightButton.isEnabled = true // move to Audio.swift file inside the mergeAndAddHighlight2 Completion Handler
                highlightButton.backgroundColor = UIColorFromRGB(rgbValue: 0x35C2BD)
			}
		}
		else {
			self.beginRecording(recordFile: audioObj!.getNextTempFile())
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
	override init(url: URL, settings: [String : Any]) throws {
		try super.init(url: url, settings: settings)
		localurl = url
		print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
		print("Recorder Object Created")
		print("url: \(url.lastPathComponent)")
		print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	}
	
	deinit {
		print("------------------------------------------------------------------")
		print("Deinit called")
		print("url: \(url.lastPathComponent)")
		print("------------------------------------------------------------------")
	}
    
	func isRecordingHighlight() -> Bool {
		if url.lastPathComponent == "temp.caf" {
			return true
		}
		return false
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





