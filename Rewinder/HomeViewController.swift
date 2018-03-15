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

class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
//    var data = [viewControllerData(image: #imageLiteral(resourceName: "highlightIcon"), title: "Highlights"), viewControllerData(image: #imageLiteral(resourceName: "settingsIcon"), title: "Settings") ]
    
    @IBOutlet var mainView: UIView!
    
    @IBOutlet weak var sideMenu: UIView!
    
    @IBOutlet weak var sideMenuLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var transcribingView: UIView!
    
    @IBOutlet weak var navBarView: UIView!
    
    @IBOutlet weak var highlightButton: RoundPlayButton!
	
    @IBOutlet weak var TranscribingTextView: UITextView!
    
    @IBOutlet weak var sideMenuTableView: UITableView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var buttonAndTranscribingView: UIView!
    
    var menuShowing = false
    
	let managedObjectContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	//	var audioRecorder: AVAudioRecorder?
	var audioObj: Audio!
	var audioPlayer: AVAudioPlayer?
	//	var audioRecorder: AVAudioRecorder!
	var audioRecorder: myRecorder!
	
	let mic = AKMicrophone()
	var rollingPlot: AKNodeOutputPlot!
	
	@IBOutlet weak var plotView: UIView!
	
	override func viewDidLoad() {
        
		super.viewDidLoad()
        mainView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        transcribingView.backgroundColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
        navBarView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        buttonAndTranscribingView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        sideMenu.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        sideMenuTableView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        sideMenu.layer.shadowOpacity = 1
        sideMenu.layer.shadowRadius = 6
		
		audioObj = Audio(managedObjectContext)
        sideMenuTableView.delegate = self
        sideMenuTableView.dataSource = self
        sideMenuTableView.separatorStyle = UITableViewCellSeparatorStyle.none

		
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
    @IBAction func openMenu(_ sender: UIButton) {
        if menuShowing == false {
            menuShowing = true
            sideMenuLeadingConstraint.constant = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
        
    }
  
    @IBAction func closeMenu(_ sender: UIButton) {
        if menuShowing == true {
            menuShowing = false
            sideMenuLeadingConstraint.constant = -210
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
    }
    
	// MARK: - Add Highlight
	@IBAction func addHighlight(_ sender: RoundPlayButton) {
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
    
    struct viewControllerData {
        var image: UIImage
        var title: String
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

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SideMenuData.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = "segueCell"
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! SideMenuTableViewCell
//        cell.viewcontrollerImage.image = data[indexPath.row].image
//        cell.title.text = data[indexPath.row].title
        cell.viewcontrollerImage.image = SideMenuData.getImage(index: indexPath.row)
        cell.title.text = SideMenuData.getTitle(index: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.performSegue(withIdentifier: "highlightsSegue", sender: self)
        } else if indexPath.row == 1 {
            self.performSegue(withIdentifier: "settingsSegue", sender: self)
        }
        
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

class SideMenuData {

    struct viewControllerData {
        var image: UIImage
        var title: String
    }

    static var data = [viewControllerData(image: #imageLiteral(resourceName: "highlightIcon"), title: "Highlights"), viewControllerData(image: #imageLiteral(resourceName: "settingsIcon"), title: "Settings") ]

    static func getImage(index: Int) -> UIImage {
        return data[index].image
    }

    static func getTitle(index: Int) -> String {
        return data[index].title
    }
}






