//
//  Audio.swift
//  Rewinder
//
//  Created by Haard Shah on 2/24/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import AVFoundation

class Audio {
	
	var session: AVAudioSession?
	
	let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue, AVEncoderBitRateKey: 16, AVNumberOfChannelsKey: 2, AVSampleRateKey: 44100.0] as [String: Any]
	
	//file system
	var filemgr = FileManager.default
	var docsURL: URL?
	var dataURL: URL?
	var dataPath: String?
	
	var highlightsURL: URL?
	var highlightsPath: String?
	
	var temp1: URL?
	var temp2: URL?
	var temp: URL?
	
	// is the current file being recorded to first temp?
	var firstTemp: Bool?
	
	// should be one Audio object per app run
	init() {
		
		session = AVAudioSession.sharedInstance()
		do {
			try session?.setCategory(AVAudioSessionCategoryPlayAndRecord)
		}catch let error as NSError{
			print (error)
		}
		
		//request permission
		
		
		//init directories
		let dirs = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
		docsURL = dirs[0]
		dataURL = docsURL!.appendingPathComponent("data")
		dataPath = dataURL!.path
		if !(filemgr.fileExists(atPath: dataPath!)){
			do {
				try filemgr.createDirectory(atPath: dataPath!, withIntermediateDirectories: true, attributes: nil)
			}
			catch let error {
				print (error)
			}
		}
		temp1 = dataURL!.appendingPathComponent("temp1.caf")
		temp2 = dataURL!.appendingPathComponent("temp2.caf")
		//extra temp file
		temp = dataURL!.appendingPathComponent("temp.caf")
		
		highlightsURL = docsURL!.appendingPathComponent("highlights")
		highlightsPath = highlightsURL!.path
		if !(filemgr.fileExists(atPath: highlightsPath!)){
			do {
				try filemgr.createDirectory(atPath: highlightsPath!, withIntermediateDirectories: true, attributes: nil)
			}
			catch let error {
				print (error)
			}
		}
		
		firstTemp = true
	}
	
	func mergeAndAddHighlight(_ file1: URL, _ file2: URL,_ file3: URL) {
		// Create a new audio track we can append to
		let composition = AVMutableComposition()
		var appendedAudioTrack: AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
		// Grab the two audio tracks that need to be appended
		let asset1 = AVURLAsset(url: URL(fileURLWithPath: file1.path), options: nil)
		let asset2 = AVURLAsset(url: URL(fileURLWithPath: file2.path), options: nil)
		let asset3 = AVURLAsset(url: URL(fileURLWithPath: file3.path), options: nil)
		var error: Error? = nil
		// Grab the first audio track and insert it into our appendedAudioTrack
		var track1 = asset1.tracks(withMediaType: .audio) as [AVAssetTrack]
		var timeRange: CMTimeRange = CMTimeRangeMake(kCMTimeZero, asset1.duration)
		if let aIndex = track1[0] as? AVAssetTrack {
			try? appendedAudioTrack?.insertTimeRange(timeRange, of: aIndex, at: kCMTimeZero)
		}
		if error != nil {
			// do something
			return
		}
		// Grab the second audio track and insert it at the end of the first one
		var track2 = asset2.tracks(withMediaType: .audio) as [AVAssetTrack]
		timeRange = CMTimeRangeMake(kCMTimeZero, asset2.duration)
		if let aIndex = track2[0] as? AVAssetTrack {
			try? appendedAudioTrack?.insertTimeRange(timeRange, of: aIndex, at: asset1.duration)
		}
		if error != nil {
			// do something
			return
		}
		// Grab the third audio track and insert it at the end of the second one
		var track3 = asset3.tracks(withMediaType: .audio) as [AVAssetTrack]
		timeRange = CMTimeRangeMake(kCMTimeZero, asset3.duration)
		if let aIndex = track3[0] as? AVAssetTrack {
			try? appendedAudioTrack?.insertTimeRange(timeRange, of: aIndex, at: asset2.duration)
		}
		if error != nil {
			// do something
			return
		}
		
		// Create a new audio file using the appendedAudioTrack
		let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)
		if exportSession == nil {
			// do something
			return
		}
        let fileName = getDatetimeString()
//        let fileName: String = "littHighlight3.caf"
		print("filename \(fileName)")
		let appendedAudioPath = highlightsURL?.appendingPathComponent(fileName)
		
		//remove if exists
		if FileManager.default.fileExists(atPath: appendedAudioPath!.path) {
			do {
				try FileManager.default.removeItem(at: appendedAudioPath!)
			} catch let error {
				print (error)
			}
		}
		
		// make sure to fill this value in
		exportSession?.outputURL = appendedAudioPath
		exportSession?.outputFileType = AVFileType.caf
		exportSession?.exportAsynchronously(completionHandler: {() -> Void in
			// exported successfully?
			switch exportSession?.status {
			case .failed?:
				print("failed")
				break
			case .completed?:
				// you should now have the appended audio file
				print("SUCCESS")
				break
			case .waiting?:
				break
			default:
				break
			}
			var _: Error? = nil
		})
	}
	
	func getDatetimeString() ->String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy-HH-mm-ss"
        print(dateFormatter.string(from: date))
        let currentFileName = "recording-\(dateFormatter.string(from: date)).caf"
        return currentFileName
	}
	
	func requestPermission(_ session: AVAudioSession) {
		
	}
	
	func checkRecordingPermission() -> Bool {
		let status = session?.recordPermission()
		if status == .granted {
			return true
		}
		return false
	}
	
	func getNextTempFile() -> URL{
		var soundFile: URL?
		if firstTemp! {
			//record to temp1
			soundFile = temp1
			firstTemp = false
		}else {
			//record to temp2
			soundFile = temp2
			firstTemp = true
		}
		return soundFile!
	}
	
	
	
	
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths[0]
	}
	
//	func trimTillEnd(inputFile, timeFromEnd)
	
//	func merge(file1, file2) -> outputMergedFile
	
	func listOfAudioFiles() -> [URL] {
		var fileURLs = [URL]()
		do {
			let files = try filemgr.contentsOfDirectory(atPath: dataPath!)
//			print(files)
			for file in files {
				fileURLs.append((dataURL?.appendingPathComponent(file))!)
			}
		}
		catch let error {
			print (error)
		}
		return fileURLs
	}
	
	func listOfHighlights() -> [URL] {
		var fileURLs = [URL]()
		do {
			let files = try filemgr.contentsOfDirectory(atPath: highlightsPath!)
			//			print(files)
			for file in files {
//				fileURLs.append((highlightsURL?.appendingPathComponent(file))!)
				fileURLs.append(URL(string: file)!)
			}
		}
		catch let error {
			print (error)
		}
		return fileURLs
	}
}














