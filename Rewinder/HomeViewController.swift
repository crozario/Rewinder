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
	
    override func viewDidLoad() {
        super.viewDidLoad()

		audioObj = Audio()
//		audioRecorder?.delegate = self
		
//		audioObj?.startRecording()
		self.beginRecording()
    }

	func beginRecording() {
		let recordFile = audioObj!.getNextTempFile()
		print("recording to " + recordFile.path)
		do {
			try audioRecorder = AVAudioRecorder(url: recordFile, settings: audioObj?.recordSettings as! [String: AnyObject])
			audioRecorder?.delegate = self
			audioRecorder?.prepareToRecord()
			let recordStatus = audioRecorder?.record(forDuration: 3.0)
			print(recordStatus!)
		}catch let error {
			print (error)
		}
	}
	
	@IBAction func addHighlight(_ sender: RoundPlayButton) {
		let files = audioObj?.listOfAudioFiles()
		for file in files!{
//			print(file.path)
//			print(file)
			do {
				try audioPlayer = AVAudioPlayer(contentsOf: file)
				audioPlayer?.delegate = self
				audioPlayer?.prepareToPlay()
				let playStatus = audioPlayer?.play()
			} catch let error as NSError {
				print("audioPlayer error \(error.localizedDescription)")
			}
		}
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
//		audioObj?.startRecording()
		print("delegate Called")
		beginRecording()
	}
}
