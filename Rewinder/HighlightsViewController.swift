//
//  HighlightsViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class HighlightsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    var arr = [String]()
	var filemgr = FileManager.default
	var docsURL: URL!
	var highlightsURL: URL!
    var audioPlayer: AVAudioPlayer?
    var currSelected: Int?
	let fileExtension: String = "caf"
    
    @IBOutlet weak var tableView: UITableView!
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	//CONTINUE NOTE: load the table view from database and manage changes to database using notifications of the NSManagedObjectContext
	
    override func viewDidLoad() {
        super.viewDidLoad()

        audioPlayer?.delegate = self
		
		// initialize file system urls
		docsURL = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0]
        highlightsURL = docsURL.appendingPathComponent("highlights")
		
		// initialize audio session
		let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
		
		// play from bottom speaker
        do {
            try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
    }
	
//	var dataFiles = [String]()
//	var dataURL: URL?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		arr = self.getHighlightTitles()
		
        tableView.reloadData()
    }
	
	func getHighlightsList() -> [NSFetchRequestResult] {
		let entityDescription = NSEntityDescription.entity(forEntityName: "HighlightEntity", in: context)
		let request: NSFetchRequest<HighlightEntity> = HighlightEntity.fetchRequest()
		let sortDescriptor = NSSortDescriptor(key: "dateandtime", ascending: false)
		
		request.entity = entityDescription
		request.sortDescriptors = [sortDescriptor]
		
		var results = [NSFetchRequestResult]()
		do {
			results = try context.fetch(request as! NSFetchRequest<NSFetchRequestResult>)
		} catch let error {
			print (error.localizedDescription)
		}
		return results
	}
	
	func getHighlightTitles() -> [String]{
		let results = self.getHighlightsList()
		var titles = [String]()
		for element in results {
			let managedObject = element as! NSManagedObject
			titles.append((managedObject.value(forKey: "title") as? String)!)
		}
		return titles
	}
	
	func getHighlightFilename(title: String) -> String {
		let entityDescription = NSEntityDescription.entity(forEntityName: "HighlightEntity", in: context)
		let request: NSFetchRequest<HighlightEntity> = HighlightEntity.fetchRequest()
		let sortDescriptor = NSSortDescriptor(key: "dateandtime", ascending: true)
		let pred = NSPredicate(format: "(title = %@)", title)
		
		request.entity = entityDescription
		request.sortDescriptors = [sortDescriptor]
		request.predicate = pred
		
		var results = [NSFetchRequestResult]()
		do {
			results = try context.fetch(request as! NSFetchRequest<NSFetchRequestResult>)
		} catch let error {
			print (error.localizedDescription)
		}
		
		var fileName: String!
		if results.count == 1 {
			let managedObject = results[0] as! NSManagedObject
			fileName = managedObject.value(forKey: "fileName") as? String
		} else {
			// there shouldn't be duplicates
		}
		
		return fileName
	}
	
	override func viewWillDisappear(_ animated: Bool) {
//		print("\(#function)")
		if audioPlayer != nil {
			if audioPlayer!.isPlaying {
				audioPlayer!.pause()
//				self.audioPlayerBeginInterruption(audioPlayer!)
			}
			
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
		
		if let player = audioPlayer {
			if player.isPlaying{
				player.stop()
				audioPlayer = nil
			}
			else {
				player.play()
			}
		}
		else{
			setupPlayer(index: indexPath.row)
			audioPlayer?.play()
			print(audioPlayer?.duration ?? -1.0) // -1.0 is default value if the duration cannot be unwraped
		}
    }

    func setupPlayer(index: Int) {
		let url = highlightsURL.appendingPathComponent(self.getHighlightFilename(title: arr[index]))

        do {
			try audioPlayer = AVAudioPlayer(contentsOf: url)
			audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        } catch let error as NSError {
            print("audioPlayer error \(error.localizedDescription)")
        }
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == UITableViewCellEditingStyle.delete {
//			print("remove editing")
//            let fileName = arr.remove(at: indexPath.row)
//            let url = highlightsURL?.appendingPathComponent(fileName)
//
//            if FileManager.default.fileExists(atPath: url!.path) {
//                do {
//                    try FileManager.default.removeItem(atPath: url!.path)
//                } catch {
//                    print(error.localizedDescription)
//                }
//
//            }
//            tableView.reloadData()
//        }
//		else if editingStyle == .insert {
//			print("insert editing")
//		}
//    }
	
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
//	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
//		
//	}
	
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let editAction = UITableViewRowAction(style: .default, title: "Edit", handler: { (action, indexPath) in
			let alert = UIAlertController(title: "Modify Highlight Name", message: "Would would you like to call this highlight?", preferredStyle: .alert)
			alert.addTextField(configurationHandler: { (textField) in
				textField.text = self.arr[indexPath.row]
				textField.clearButtonMode = .always
			})
			alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (updateAction) in
				let newName = alert.textFields!.first!.text!
				let oldName = self.arr[indexPath.row]
				let newURL = self.highlightsURL.appendingPathComponent(newName).appendingPathExtension(self.fileExtension)
				let oldURL = self.highlightsURL.appendingPathComponent(oldName).appendingPathExtension(self.fileExtension)
				
				//check if newName already exists
				if self.filemgr.fileExists(atPath: newURL.path) {
					// close alert --> closes automatically
					self.dismiss(animated: true, completion: nil)
					
					// display message
					let alreadyExistsAlert = UIAlertController(title: "Rename Error", message: "Highlight name already exists.", preferredStyle: .alert)
					alreadyExistsAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
					self.present(alreadyExistsAlert, animated: true)
				} else {
					do {
						try self.filemgr.moveItem(at: oldURL, to: newURL)
					} catch let error {
						print (error)
					}
					self.arr[indexPath.row] = newName
					self.tableView.reloadRows(at: [indexPath], with: .fade)
				}
			}))
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			self.present(alert, animated: false)
		})
		
		let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
//			self.arr.remove(at: indexPath.row)
			// also remove in file system
			tableView.reloadData()
		})
		
		return [deleteAction, editAction]
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
		print("\(#function)")
		print(error as Any)
    }
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		print("\(#function)")
		if player.isPlaying {
			player.pause()
		}
    }
    func audioPlayerEndInterruption(player: AVAudioPlayer) {
		print("\(#function)")
		
    }
    
    
}








