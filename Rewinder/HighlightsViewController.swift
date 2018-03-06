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
	
	override func viewWillDisappear(_ animated: Bool) {
//		print("\(#function)")
		if audioPlayer != nil {
			if audioPlayer!.isPlaying {
				audioPlayer!.pause() //FIX ME: WHY ARE WE PAUSING?
			}
		}
	}
	
	// MARK: - Table view cell content
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
    
	// MARK: - Playing audio
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
	
	// CONTINUE NOTE: check the edit and implement the delete
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
				
				//check if newName already exists
				if self.highlightTitleExists(title: newName) {
					// close alert --> closes automatically
					self.dismiss(animated: true, completion: nil)
					
					// display message
					let alreadyExistsAlert = UIAlertController(title: "Rename Error", message: "Highlight name already exists.", preferredStyle: .alert)
					alreadyExistsAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
					self.present(alreadyExistsAlert, animated: true)
				} else {
					let managedObj = self.getHighlightManagedObject(title: oldName)
					managedObj.setValue(newName, forKey: "title")
					do {
						try self.context.save()
						self.arr[indexPath.row] = newName
						self.tableView.reloadRows(at: [indexPath], with: .fade)
					} catch let error {
						print(error.localizedDescription)
					}
				}
			}))
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			self.present(alert, animated: false)
		})
		
		let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
			
			// delete in database and filesystem
			do {
				try self.removeHighlightDatabaseAndFileSystem(title: self.arr[indexPath.row])
			} catch let error {
				print("delete error: \(error.localizedDescription)")
			}
			
			// delete in tableView
			self.arr.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .fade)
			
//			tableView.reloadData() //try to just remove the row instead
		})
		
		return [deleteAction, editAction]
	}
	
	func removeHighlightDatabaseAndFileSystem(title: String) throws -> Bool {
		let managedObj = self.getHighlightManagedObject(title: title)
		
		// remove in filesystem
		let file = managedObj.value(forKey: "fileName") as! String
		let url = self.highlightsURL.appendingPathComponent(file)
		if self.filemgr.fileExists(atPath: url.path) {
			try self.filemgr.removeItem(at: url)
		} else {
			print("File \(title).caf not found in filesystem")
			return false
		}
		
		// remove in database
		self.context.delete(managedObj)
		try self.context.save()
		
		// deletion complete successfully
		return true
	}
	
	// MARK: - Core data getters
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
	
	let defaultNotFoundManagedObject: NSManagedObject = NSManagedObject()
	func getHighlightManagedObject(title: String) -> NSManagedObject {
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
		
		var managedObj: NSManagedObject!
		if results.count > 0 {
			managedObj = results[0] as! NSManagedObject
			// there should only be one
			if results.count != 1 {
				print("Unexpected behavior inside core data. Searched for \(title), found multiple with same title.")
			}
		} else {
			managedObj = defaultNotFoundManagedObject
		}
		
		return managedObj
	}
	
	func getHighlightFilename(title: String) -> String {
		return (getHighlightManagedObject(title: title).value(forKey: "fileName") as? String)!
	}
	
	func highlightTitleExists(title: String) -> Bool {
		let managedObj = getHighlightManagedObject(title: title)
		if managedObj != defaultNotFoundManagedObject {
			return true
		}
		return false
	}
	
	// MARK: - Unused delegate callbacks
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








