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
    
    @IBOutlet weak var tableView: UITableView!
    
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
        
        do {
            try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
    }
	var dataFiles = [String]()
	var dataURL: URL?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		do {
            let files = try filemgr.contentsOfDirectory(atPath: highlightsURL!.path)
            arr.removeAll(keepingCapacity: true)
            for file in files {
                arr.append(file)
            }
		} catch let error {
			print(error)
		}
//		dataURL = docsURL!.appendingPathComponent("data")
//		do {
//			let files = try filemgr.contentsOfDirectory(atPath: dataURL!.path)
//			for file in files {
//				arr.append(file)
//				dataFiles.append(file)
//			}
//		} catch let error {
//			print(error)
//		}
		
        tableView.reloadData()
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

		if let player = audioPlayer {
			if player.isPlaying{
				player.stop()
				audioPlayer = nil
			}
		}
		else{
			setupPlayer(index: indexPath.row)
			audioPlayer?.play()
		}

        print(audioPlayer?.duration)
    }

    func setupPlayer(index: Int) {
        let fileName = arr[index]
//        currSelected = index
//        let url = highlightsURL?.appendingPathComponent(fileName)
		var url: URL?
		if dataFiles.contains(fileName) {
			url = (dataURL?.appendingPathComponent(fileName))
		}
		else {
			url = (highlightsURL?.appendingPathComponent(fileName))
		}
		print(dataFiles)
		
        print(url)
        do {
			try audioPlayer = AVAudioPlayer(contentsOf: url!)
			audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        } catch let error as NSError {
            print("audioPlayer error \(error.localizedDescription)")
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
			print("remove editing")
            let fileName = arr.remove(at: indexPath.row)
            let url = highlightsURL?.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: url!.path) {
                do {
                    try FileManager.default.removeItem(atPath: url!.path)
                } catch {
                    print(error.localizedDescription)
                }
                
            }
            tableView.reloadData()
        }
		else if editingStyle == .insert {
			print("insert editing")
		}
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
		print("\(#function)")
	}
	
	func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
		print("\(#function)")
	}
	
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print("\(#function)")
		audioPlayer = nil
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		
    }
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		if player.isPlaying {
			player.pause()
		}
    }
    func audioPlayerEndInterruption(player: AVAudioPlayer) {
		
    }
    
    
}








