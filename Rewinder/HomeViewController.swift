//
//  HomeViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/24/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

//	var audioRecorder: AVAudioRecorder?
	var audioObj: Audio?
	var audioPlayer: AVAudioPlayer?
	var audioRecorder: AVAudioRecorder?
	
	let recordDuration: Double = 6.0
	
    override func viewDidLoad() {
        super.viewDidLoad()

		audioObj = Audio()
//		audioRecorder?.delegate = self
		
//		audioObj?.startRecording()
		self.beginRecording()
    }

	func beginRecording() {
		let recordFile = audioObj!.getNextTempFile()
//		print("recording to " + recordFile.path)
		do {
			try audioRecorder = AVAudioRecorder(url: recordFile, settings: audioObj?.recordSettings as! [String: AnyObject])
			audioRecorder?.delegate = self
			audioRecorder?.prepareToRecord()
//			print("recording starts: \(recordFile)")
			let recordStatus = audioRecorder?.record(forDuration: recordDuration)
//			print(recordStatus!)
			
		}catch let error {
			print (error)
		}
	}
	
	func altRecording(file3: URL) {
		let recordFile = file3
		do {
			try audioRecorder = AVAudioRecorder(url: recordFile, settings: audioObj?.recordSettings as! [String: AnyObject])
			audioRecorder?.delegate = self
			audioRecorder?.prepareToRecord()
			print("SPECIAL recording starts:")
			let recordStatus = audioRecorder?.record(forDuration: recordDuration)
//			print(recordStatus!)
			
		}catch let error {
			print (error)
		}
	}
	
	@IBAction func addHighlight(_ sender: RoundPlayButton) {
		
//		let files = audioObj?.listOfAudioFiles()
//		for file in files!{
//			do {
//				try audioPlayer = AVAudioPlayer(contentsOf: file)
//				audioPlayer?.delegate = self
//				audioPlayer?.prepareToPlay()
//				audioPlayer?.play()
//			} catch let error as NSError {
//				print("audioPlayer error \(error.localizedDescription)")
//			}
//		}
		computeHighlight()
//		let files = audioObj?.listOfHighlights()
//		for file in files!{
//			print(file)
//			do {
//				try audioPlayer = AVAudioPlayer(contentsOf: file)
//				audioPlayer?.delegate = self
//				audioPlayer?.prepareToPlay()
//				audioPlayer?.play()
//			} catch let error as NSError {
//				print("audioPlayer error \(error.localizedDescription)")
//			}
//		}
	}
	
	var high1: URL?
	var trimmedHigh1: URL?
	var high2: URL?
	var new3: URL?
	var cropTime: TimeInterval?
	
	func computeHighlight(){
		//get current recording time
		cropTime = audioRecorder?.currentTime
		
		//stop recording
		audioRecorder?.stop()
		
		new3 = audioObj?.temp
		altRecording(file3: new3!)
		
		//which temp lastest?
		if audioObj?.firstTemp == true {
			// temp2 latest
			high2 = audioObj?.temp2
			high1 = audioObj?.temp1
		}
		else {
			// temp1 latest
			high2 = audioObj?.temp1
			high1 = audioObj?.temp2
		}
		if high1 != nil {
			//need to trip
			let asset = AVAsset(url: high1!)
			trimmedHigh1 = audioObj?.dataURL?.appendingPathComponent("trimmed.caf")
			exportAsset(asset, trimmedSoundFileURL: trimmedHigh1!)
		}
	}
	
	func stitchHighlight(currTime: TimeInterval, trimmed: URL, file2: URL, file3: URL) {
		// then merge all files
		audioObj?.mergeAndAddHighlight(trimmed, file2, file3)
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {

//		let files = audioObj?.listOfAudioFiles()
//		for file in files!{
//			//			print(file.path)
//			//			print(file)
//			do {
//				try audioPlayer = AVAudioPlayer(contentsOf: file)
//				audioPlayer?.delegate = self
//				audioPlayer?.prepareToPlay()
//				//				let playStatus = audioPlayer?.play()
//				print(file)
//				print(audioPlayer?.duration)
//			} catch let error as NSError {
//				print("audioPlayer error \(error.localizedDescription)")
//			}
//		}
		
		if new3 != nil {
			if recorder.url == new3! {
				//stitch
				stitchHighlight(currTime: cropTime!, trimmed: trimmedHigh1!, file2: high2!, file3: new3!)
				
				let list = [trimmedHigh1, high2, new3, audioObj?.mostRecentHighlight]
				for file in list{
					if file != nil {
						do {
							try audioPlayer = AVAudioPlayer(contentsOf: file!)
							audioPlayer?.delegate = self
							audioPlayer?.prepareToPlay()
							//				let playStatus = audioPlayer?.play()
							print(file)
							print(audioPlayer?.duration)
						} catch let error as NSError {
							print("audioPlayer error \(error.localizedDescription)")
						}
					}
				}

				new3 = nil
//				beginRecording()
			}
		}
		else {
			beginRecording()
		}
	}
	
	func exportAsset(_ asset: AVAsset, trimmedSoundFileURL: URL) {
		print("\(#function)")
		
//		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//		let trimmedSoundFileURL = documentsDirectory.appendingPathComponent(fileName)
		print("saving to \(trimmedSoundFileURL.path)")
		
		//see if temp.caf exists in data
		print(FileManager.default.fileExists(atPath: trimmedSoundFileURL.path))
		
		if FileManager.default.fileExists(atPath: trimmedSoundFileURL.path) {
			print("sound exists, removing \(trimmedSoundFileURL.path)")
			do {
				if try trimmedSoundFileURL.checkResourceIsReachable() {
					print("is reachable")
				}
				
				try FileManager.default.removeItem(atPath: trimmedSoundFileURL.path)
			} catch {
				print("could not remove \(trimmedSoundFileURL)")
				print(error.localizedDescription)
			}
			
		}
		
		print("creating export session for \(asset)")
		
		if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) {
			exporter.outputFileType = AVFileType.caf
			exporter.outputURL = trimmedSoundFileURL
			
			let duration = CMTimeGetSeconds(asset.duration)

			let startTime = CMTimeMakeWithSeconds(cropTime!, 1000000)
			let endTime = CMTimeMakeWithSeconds(duration, 1000000)
			exporter.timeRange = CMTimeRangeFromTimeToTime(startTime, endTime)
//			exporter.timeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
			
			// do it
			exporter.exportAsynchronously(completionHandler: {
				print("export complete \(exporter.status)")
				
				switch exporter.status {
				case  AVAssetExportSessionStatus.failed:
					
					if let e = exporter.error {
						print("export failed \(e)")
					}
					
				case AVAssetExportSessionStatus.cancelled:
					print("export cancelled \(String(describing: exporter.error))")
				default:
					print("export complete")
				}
			})
		} else {
			print("cannot create AVAssetExportSession for asset \(asset)")
		}
		
	}
}
