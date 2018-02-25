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
	var recorder: AVAudioRecorder?
	
	let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue, AVEncoderBitRateKey: 16, AVNumberOfChannelsKey: 2, AVSampleRateKey: 44100.0] as [String: Any]
	
	//file system
	var filemgr = FileManager.default
	var docsURL: URL?
	var dataURL: URL?
	var dataPath: String?
	
	var temp1: URL?
	var temp2: URL?
	
	// is the current file being recorded to first temp?
	var firstTemp: Bool?
	
	// should be one Audio object per app run
	init() {
//		recorder = audioRecorder
		
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
		
		firstTemp = true
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
	
	func startRecording() {
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
		
		do {
			try recorder = AVAudioRecorder(url: soundFile!, settings: recordSettings as [String: AnyObject])
			
			recorder?.delegate = HomeViewController.self()
			recorder?.prepareToRecord()
			let recordStatus = recorder?.record(forDuration: 3.0)
			print(recordStatus!)
		}catch let error {
			print (error)
		}
	}
	
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths[0]
	}
	
	func stopRecording() {
		if recorder?.isRecording == true {
			recorder?.stop()
		}
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
}














