//
//  HomeViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/24/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import AVFoundation
import DSWaveformImage
import CoreData
import NotificationCenter

var recordDuration = 5.0

class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
	
	@IBOutlet weak var highlightButton: RoundPlayButton!
	
	let managedObjectContext: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
    //	var audioRecorder: AVAudioRecorder?
	var audioObj: Audio!
	var audioPlayer: AVAudioPlayer?
	var audioRecorder: AVAudioRecorder?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		audioObj = Audio(managedObjectContext)
		
		//delete highlights folder
//		deleteAllHighlights()
		
		//waveform
//		createWaveform()
    }
	
	override func viewDidAppear(_ animated: Bool) {
//		print("\(#function)")
		self.beginRecording(recordFile: audioObj.getNextTempFile())
//		audioObj.printAllHighlightEntities()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		if audioRecorder != nil {
			if audioRecorder!.isRecording {
				audioRecorder?.stop()
			}
		}
	}
	
	// MARK: - Add Highlight
	@IBAction func addHighlight(_ sender: RoundPlayButton) {
        highlightButton.isEnabled = false
		computeHighlight()
	}
	
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
	
	func deleteAllHighlights() {
		let highFolder = audioObj.highlightsURL
		let filemgr = audioObj.filemgr
		do {
			let files = try filemgr.contentsOfDirectory(atPath: highFolder!.path)
			for file in files {
				try filemgr.removeItem(atPath: highFolder!.path + "/" + file)
			}
		} catch let error {
			print (error)
		}
	}
	
	func createWaveform() {
//		let guide = view.safeAreaLayoutGuide
//		let height = guide.layoutFrame.size.height 	//never used
		let viewWidth = view.bounds.size.width
		
		let waveformImageDrawer = WaveformImageDrawer()
		let audioURL = Bundle.main.url(forResource: "Eminem - Rap God", withExtension: "mp3")!
		let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
																 size: UIScreen.main.bounds.size,
																 color: UIColor.blue,
																 backgroundColor: UIColor.white,
																 style: .striped,
																 position: .middle,
																 scale: UIScreen.main.scale)
		let waveform = Waveform(audioAssetURL: audioURL)!
		
		let image = topWaveformImage
		let imageView = UIImageView(image: image!)
		imageView.frame = CGRect(x: 0, y: 50, width: viewWidth, height: viewWidth/2)
		view.addSubview(imageView)
		print("so many samples: \(String(describing: waveform.samples(count: 200)))")
	}
	
	// MARK: - Recording
	func beginRecording(recordFile: URL) {
		do {
			if FileManager.default.fileExists(atPath: recordFile.path){
				try FileManager.default.removeItem(at: recordFile)
			}
			try audioRecorder = AVAudioRecorder(url: recordFile, settings: (audioObj.recordSettings as [String: AnyObject]?)!)
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
}
