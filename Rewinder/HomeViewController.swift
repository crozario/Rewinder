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
import Speech


var recordDuration = 5.0
// change

class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIViewControllerTransitioningDelegate {
    
//    var data = [viewControllerData(image: #imageLiteral(resourceName: "highlightIcon"), title: "Highlights"), viewControllerData(image: #imageLiteral(resourceName: "settingsIcon"), title: "Settings") ]
    
    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var transcribingView: UIView!
    
    @IBOutlet weak var navBarView: UIView!
    
    @IBOutlet weak var highlightButton: RoundButton!
	
    @IBOutlet weak var TranscribingTextView: UITextView!
    
//    @IBOutlet weak var highlightPageButton: RoundButton!
    
//    @IBOutlet weak var settingsPageButton: RoundButton!
//    let highlightTransition = CircularTransition()
//    let settingsTransition = CircularTransition()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var buttonAndTranscribingView: UIView!
    
    
	let managedObjectContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	//	var audioRecorder: AVAudioRecorder?
	var audioObj: Audio!
    var audioPlayer: AVAudioPlayer?
	//	var audioRecorder: AVAudioRecorder!
	var audioRecorder: myRecorder!
	
	let mic = AKMicrophone()
	var rollingPlot: AKNodeOutputPlot!
	
	@IBOutlet weak var plotView: UIView!
    
//    var buttonTag = -1
//
//    @IBAction func highlightButtonPressed(_ sender: RoundButton) {
//        buttonTag = 1
//    }
//
//    @IBAction func settingsButtonPressed(_ sender: RoundButton) {
//        buttonTag = 2
//    }
//
//    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//
//
//        if buttonTag == 1 {
//            highlightTransition.transitionMode = .present
//            highlightTransition.startingPoint = highlightPageButton.center
//            highlightTransition.circleColor = highlightPageButton.backgroundColor!
//            return highlightTransition
//        } else if buttonTag == 2 {
//            highlightTransition.transitionMode = .present
//            settingsTransition.startingPoint = settingsPageButton.center
//            settingsTransition.circleColor = settingsPageButton.backgroundColor!
//            return settingsTransition
//        }
//        return settingsTransition
////        transition.startingPoint = highlightPageButton.center
////        transition.circleColor = highlightPageButton.backgroundColor!
//    }
//
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        if buttonTag == 1 {
//            highlightTransition.transitionMode = .dismiss
//            highlightTransition.startingPoint = highlightPageButton.center
//            highlightTransition.circleColor = highlightPageButton.backgroundColor!
//            return highlightTransition
//        } else if buttonTag == 2 {
//            highlightTransition.transitionMode = .dismiss
//            settingsTransition.startingPoint = settingsPageButton.center
//            settingsTransition.circleColor = settingsPageButton.backgroundColor!
//            return settingsTransition
//        }
//        return settingsTransition
//
////        transition.startingPoint = highlightPageButton.center
////        transition.circleColor = highlightPageButton.backgroundColor!
//
//    }
//
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        print("\(segue.identifier) --- \(segue.source)")
//
//        if buttonTag == 1 {
//            var secondVC = segue.destination as! HighlightsViewController
//
//            secondVC.transitioningDelegate = self
//            secondVC.modalPresentationStyle = .custom
//        } else if buttonTag == 2 {
//            var secondVC = segue.destination as! SettingsViewController
//            secondVC.transitioningDelegate = self
//            secondVC.modalPresentationStyle = .custom
//        }
//
//    }
	
	override func viewDidLoad() {
        
		super.viewDidLoad()
        mainView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        transcribingView.backgroundColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
        navBarView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        buttonAndTranscribingView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
		
		audioObj = Audio(managedObjectContext)
		
		//delete highlights folder
		//		audioObj.deleteAllHighlights()
		
		//waveform
		//		createWaveform()
		
		self.beginRecording(recordFile: audioObj.getNextTempFile())
		
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
		let tracker = AKFrequencyTracker(micCopy2, hopSize: 200, peakCount: 2_000)
		let silence = AKBooster(tracker, gain: 0)
		
		AudioKit.output = silence
        do {
            try AudioKit.start()
        } catch let error {
            print(error.localizedDescription)
        }
		
		// create rolling waveform plot
		rollingPlot = createRollingPlot(micCopy1)
		plotView.addSubview(rollingPlot)
        
        startSession()
	}
    
	
	func createRollingPlot(_ inputNode: AKNode) -> AKNodeOutputPlot {
		let frame: CGRect = plotView.frame
		let rplot = AKNodeOutputPlot(inputNode, frame: frame)
		rplot.plotType = .rolling
		rplot.shouldFill = true
		rplot.shouldMirror = true
		// Color: Yale Blue (RGB: 14, 77, 146) - for RGB proportions between 0-1 divide by 255
		rplot.color = UIColorFromRGB(rgbValue: 0xFFFFFF)
        //Blue theme
        rplot.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
//        rplot.backgroundColor = AKColor(displayP3Red: 2/255, green: 120/255, blue: 174/255, alpha: 1.0)
    
		rplot.gain = 2
		
		return rplot
	}
	
	override func viewDidAppear(_ animated: Bool) {
		print("\(#function)")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		print("\(#function)")
		// reset temp files
		//		audioObj.deleteAndResetTempData()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		print("\(#function)")
		if audioRecorder != nil {
			if audioRecorder!.isRecording {
				// stop recording
				//				audioRecorder!.stop()
			}
		}
	}
    
	// MARK: - Add Highlight
	@IBAction func addHighlight(_ sender: RoundButton) {
		highlightButton.isEnabled = false
		computeHighlight()
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
			audioRecorder!.record(forDuration: recordDuration)
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
				highlightButton.isEnabled = true // move to Audio.swift file inside the mergeAndAddHighlight2 Completion Handler
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
    
    
    func startSession() {
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
                self.TranscribingTextView.text = result.bestTranscription.formattedString
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
        
        
    }

    
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





