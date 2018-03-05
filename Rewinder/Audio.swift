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
	var docsURL: URL!
	var dataURL: URL!
	var dataPath: String!
	
	var highlightsURL: URL!
	var highlightsPath: String!
	
	var temp1: URL!
	var temp2: URL!
	var temp: URL!
	
	// is the current file being recorded to first temp?
	var firstTemp: Bool?
	
//	var highlightButton: RoundPlayButton!
	
	// should be one Audio object per app run
	init() {
		
//		highlightButton = button
		
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
//		let trimmed = dataURL!.appendingPathComponent("trimmed.caf")
		
		do {
			if filemgr.fileExists(atPath: temp1.path){
				try filemgr.removeItem(at: temp1)
			}
			if filemgr.fileExists(atPath: temp2.path){
				try filemgr.removeItem(at: temp2)
			}
			if filemgr.fileExists(atPath: temp.path){
				try filemgr.removeItem(at: temp)
			}
		}catch let error {
			print (error)
		}
		
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
	
	func getDatetimeString() ->String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy-HH-mm-ss"
//        print(dateFormatter.string(from: date))
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
	
	func getCurrTempFile() -> URL{
		var currFile: URL?
		if firstTemp! {
			currFile = temp2
		} else {
			currFile = temp1
		}
		return currFile!
	}
	
	func getOldTempFile() -> URL{
		var oldFile: URL?
		if firstTemp! {
			oldFile = temp1
		}
		else {
			oldFile = temp2
		}
		return oldFile!
	}
	
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths[0]
	}

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
	
	
	let bothHigh: String = "both_high.caf"
	func exportAsset(_ asset: AVAsset, trimmedSoundFileURL: URL, cropTime: TimeInterval, mergeWith: URL) {
		//		print("\(#function)")
		
		//see if temp.caf exists in data
		print(FileManager.default.fileExists(atPath: trimmedSoundFileURL.path))
		
		if FileManager.default.fileExists(atPath: trimmedSoundFileURL.path) {
			//			print("sound exists, removing \(trimmedSoundFileURL.path)")
			do {
				if try trimmedSoundFileURL.checkResourceIsReachable() {
					//					print("is reachable")
				}
				
				try FileManager.default.removeItem(atPath: trimmedSoundFileURL.path)
			} catch {
				print("could not remove \(trimmedSoundFileURL)")
				print(error.localizedDescription)
			}
		}
		
		//		print("creating export session for \(asset)")
		
		if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) {
			exporter.outputFileType = AVFileType.caf
			exporter.outputURL = trimmedSoundFileURL
			
			let duration = CMTimeGetSeconds(asset.duration)
			
			let startTime = CMTimeMakeWithSeconds(cropTime, 1000000)
			let endTime = CMTimeMakeWithSeconds(duration, 1000000)
			exporter.timeRange = CMTimeRangeFromTimeToTime(startTime, endTime)
			
			// do it
			exporter.exportAsynchronously(completionHandler: {
				//				print("export complete \(exporter.status)")
				if exporter.status == .failed {
					if let e = exporter.error {
						print("failed to export trimmed file \(e)")
					}
				}
				else if exporter.status == .cancelled {
					print("export cancelled \(String(describing: exporter.error))")
				}
				else if exporter.status == .completed{
					do {
						_ = try self.mergeAndAddHighlight2(trimmedSoundFileURL, mergeWith, outputFileName: self.bothHigh)
					} catch let error {
						print (error)
					}
				}
			})
		} else {
			print("cannot create AVAssetExportSession for asset \(asset)")
		}
	}
	
//	func mergeAndAddHighlight(_ file1: URL, _ file2: URL,_ file3: URL) throws {
//		let firsthalf = try mergeAndAddHighlight2(file1, file2, outputFileName: "dummy.caf")
//		if filemgr.fileExists(atPath: firsthalf.path){
//			_ = try mergeAndAddHighlight2(firsthalf, file3, outputFileName: getDatetimeString())
////			do {
////				try filemgr.removeItem(at: firsthalf)
////			} catch let error {
////				print (error)
////			}
//		}
//	}
	var mostRecentHighlight: URL?
	var prev_file2: URL?
	func mergeAndAddHighlight2(_ file1: URL, _ file2: URL, outputFileName: String) throws -> AVAssetExportSession{
		// Create a new audio track we can append to
		let composition = AVMutableComposition()
		var appendedAudioTrack: AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
		// Grab the two audio tracks that need to be appended
		
		let asset1 = AVURLAsset(url: URL(fileURLWithPath: file1.path), options: nil)
		let asset2 = AVURLAsset(url: URL(fileURLWithPath: file2.path), options: nil)
		
		// Grab the first audio track and insert it into our appendedAudioTrack
		var track1: [AVAssetTrack] = asset1.tracks(withMediaType: .audio) as [AVAssetTrack]
		var timeRange: CMTimeRange = CMTimeRangeMake(kCMTimeZero, asset1.duration)
		if track1.count != 0 {
			if let aIndex = track1[0] as? AVAssetTrack {
				try? appendedAudioTrack?.insertTimeRange(timeRange, of: aIndex, at: kCMTimeZero)
			}
		}
		
		// Grab the second audio track and insert it at the end of the first one
		var track2 = asset2.tracks(withMediaType: .audio) as [AVAssetTrack]
		timeRange = CMTimeRangeMake(kCMTimeZero, asset2.duration)
		if let aIndex = track2[0] as? AVAssetTrack {
			try? appendedAudioTrack?.insertTimeRange(timeRange, of: aIndex, at: asset1.duration)
		}
		
		// Create a new audio file using the appendedAudioTrack
		let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)
		if exportSession == nil {
			// do something
			print("Merge error: exportSession nil")
		}
		
//		let outputFileName = getDatetimeString()
		print("filename \(outputFileName)")
		let appendedAudioPath = highlightsURL.appendingPathComponent(outputFileName)
		mostRecentHighlight = appendedAudioPath
		
		//remove if exists
		if FileManager.default.fileExists(atPath: appendedAudioPath.path) {
			do {
				try FileManager.default.removeItem(at: appendedAudioPath)
			} catch let error {
				print (error)
			}
		}
		exportSession?.outputURL = appendedAudioPath
		exportSession?.outputFileType = AVFileType.caf
		exportSession?.exportAsynchronously(completionHandler: {() -> Void in
			// exported successfully?
			switch exportSession?.status {
			case .failed?:
				print("Failed exporting merged files")
				break
			case .completed?: // you should now have the appended audio file
				if file2 == self.temp {
					if self.prev_file2 != nil {
						//rename temp to prev_file2
						//rename the temp.caf to high2 (prev_file2)
						
						self.renameFile(oldFile: file2, newFile: self.prev_file2!)
					}
					else {
						self.renameFile(oldFile: file2, newFile: self.temp1)
					}
					self.delete_both_high()
				}
				if file2 != self.temp {
					self.prev_file2 = file2
				}
				
				print("SUCCESS merging files")
				break
			case .waiting?:
				break
			default:
				break
			}
			var _: Error? = nil
		})
		return exportSession!
	}
	
	func renameFile (oldFile: URL, newFile: URL) {
		if self.filemgr.fileExists(atPath: oldFile.path){
			do {
				//first remove the original
				try self.filemgr.removeItem(at: newFile)
				//now rename temp --> high2 (aka prev_file2 aka temp to temp1/temp2)
				try self.filemgr.moveItem(at: oldFile, to: newFile)
			} catch let error {
				print (error)
			}
		}
	}
	
	func delete_both_high() {
		let url = highlightsURL.appendingPathComponent(self.bothHigh)
		if self.filemgr.fileExists(atPath: url.path){
			do {
				try filemgr.removeItem(at: url)
			} catch let error {
				print (error)
			}
		}
	}
}














