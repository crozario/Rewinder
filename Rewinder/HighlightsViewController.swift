//
//  HighlightsViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import AVFoundation

class HighlightsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    var arr = [String]()
	var filemgr = FileManager.default
	var docsURL: URL?
	var highlightsURL: URL?
    var audioPlayer: AVAudioPlayer?
    var currSelected: Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        arr = ["Crossley", "NJIT", "Haard", "Database", "Computer Networks", "Hackathon", "iOS App", "MacBook"]
//        var playButton = false
//        var stopButton = false
        audioPlayer?.delegate = self
        
		docsURL = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0]
        highlightsURL = docsURL!.appendingPathComponent("highlights")
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		do {
            let files = try filemgr.contentsOfDirectory(atPath: highlightsURL!.path) 
            for file in files {
                arr.append(file)
            }
		} catch let error {
			print(error)
		}
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
    }
	
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = "HighlightCell"
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
        
        cell.textLabel?.text = arr[indexPath.row]
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if currSelected == indexPath.row {
//            audioPlayer?.stop()
//        } else if (audioPlayer?.isPlaying)! {
//            audioPlayer?.stop()
//            setupPlayer(index: indexPath.row)
//            audioPlayer?.play()
//        } else {
//            setupPlayer(index: indexPath.row)
//            audioPlayer?.play()
//        }
        setupPlayer(index: indexPath.row)
        let status = audioPlayer?.play()
        print(status)
    
        
    }
    
    
    func setupPlayer(index: Int) {
        let fileName = arr[index]
//        currSelected = index
        let url = docsURL?.appendingPathComponent(fileName)
        print(url)
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: url!)
            print(audioPlayer)
            audioPlayer?.prepareToPlay()
        } catch let error as NSError {
            print("audioPlayer error \(error.localizedDescription)")
        }
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
    }
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        
    }
    func audioPlayerEndInterruption(player: AVAudioPlayer) {
        
    }
    
    
}








