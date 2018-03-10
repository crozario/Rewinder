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

var recordDuration = 5.0
// change

class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
	
	@IBOutlet weak var highlightButton: RoundPlayButton!
	
	
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
	}
	
	func createRollingPlot(_ inputNode: AKNode) -> AKNodeOutputPlot {
		let frame: CGRect = plotView.frame
		let rplot = AKNodeOutputPlot(inputNode, frame: frame)
		rplot.plotType = .rolling
		rplot.shouldFill = true
		rplot.shouldMirror = true
		// Color: Yale Blue (RGB: 14, 77, 146) - for RGB proportions between 0-1 divide by 255
		rplot.color = AKColor(displayP3Red: 0.055, green: 0.302, blue: 0.573, alpha: 1.0)
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

