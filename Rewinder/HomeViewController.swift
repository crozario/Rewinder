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


var recordDuration = 5.0

class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var highlightButton: RoundPlayButton!
    //	var audioRecorder: AVAudioRecorder?
	var audioObj: Audio!
	var audioPlayer: AVAudioPlayer?
	var audioRecorder: AVAudioRecorder?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		audioObj = Audio()
		
		//delete highlights folder
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
		
		//waveform
//		let guide = view.safeAreaLayoutGuide
//		let height = guide.layoutFrame.size.height
//		let viewWidth = view.bounds.size.width
//
//		let waveformImageDrawer = WaveformImageDrawer()
//		let audioURL = Bundle.main.url(forResource: "Eminem - Rap God", withExtension: "mp3")!
//		let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
//																 size: UIScreen.main.bounds.size,
//																 color: UIColor.blue,
//																 backgroundColor: UIColor.white,
//																 style: .striped,
//																 position: .middle,
//																 scale: UIScreen.main.scale)
//		let waveform = Waveform(audioAssetURL: audioURL)!
//
//		let image = topWaveformImage
//		let imageView = UIImageView(image: image!)
//		imageView.frame = CGRect(x: 0, y: 50, width: viewWidth, height: viewWidth/2)
//		view.addSubview(imageView)
//		print("so many samples: \(waveform.samples(count: 200))")
    }
	
	override func viewDidAppear(_ animated: Bool) {
		print("\(#function)")
		self.beginRecording(recordFile: audioObj.getNextTempFile())
	}

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
	
	@IBAction func addHighlight(_ sender: RoundPlayButton) {
        highlightButton.isEnabled = false
		computeHighlight()
	}
	
	var high1: URL?
	var trimmedHigh1: URL?
	var high2: URL?
	var high3: URL?
//	var cropTime: TimeInterval?
	
	func computeHighlight(){
		//get current recording time
		let cropTime = audioRecorder?.currentTime
		
		//stop recording
		audioRecorder?.stop()
	
		if let tmp = audioObj.temp {
			high3 = tmp
			self.beginRecording(recordFile: high3!)
		}

		high1 = audioObj.getOldTempFile()
		high2 = audioObj.getCurrTempFile()
		
		if high1 != nil {
			//need to trip
			print (high1)
			let asset = AVAsset(url: high1!)
			trimmedHigh1 = audioObj.dataURL?.appendingPathComponent("trimmed.caf")
			audioObj.exportAsset(asset, trimmedSoundFileURL: trimmedHigh1!, cropTime: cropTime!)
		}
		else {
			trimmedHigh1 = nil
		}
	}
	
	func stitchHighlight() {
		// then merge all files
		if high1 == nil {
			audioObj.mergeAndAddHighlight2(high2!, high3!, outputFileName: audioObj.getDatetimeString())
		}
		else {
            let a = trimmedHigh1!
            let b = high2!
            let c = high3!
			audioObj.mergeAndAddHighlight(a, b, c)
//            audioObj.mergeAndAddHighlight(b, a, c)
			
//			audioObj.mergeAndAddHighlight(a, c, b)
//			audioObj.mergeAndAddHighlight(b, a, c) //** was good just switch last two
//			audioObj.mergeAndAddHighlight(b, c, a)
//			audioObj.mergeAndAddHighlight(c, a, b)
//			audioObj.mergeAndAddHighlight(c, b, a)
			
			printAudioLength(message: "trimmed", url: a)
			printAudioLength(message: "file2", url: b)
			printAudioLength(message: "file3", url: c)
		}
	}
	
	func printAudioLength(message: String, url: URL) {
		do {
			try audioPlayer = AVAudioPlayer(contentsOf: url)
			print(message)
			print(audioPlayer?.duration)
		}catch let error{
			print (error)
		}
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		if high3 != nil {
			if recorder.url == high3! {
                highlightButton.isEnabled = true
                
				//stitch
                stitchHighlight()
//                stitchHighlight()
				
				high3 = nil
//				self.beginRecording(recordFile: audioObj!.getNextTempFile())
			}
		}
		else {
			self.beginRecording(recordFile: audioObj!.getNextTempFile())
		}
	}
}
