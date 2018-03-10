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
import NotificationCenter

class HighlightsViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    var arr = [String]()
	var filemgr = FileManager.default
	var docsURL: URL!
	var highlightsURL: URL!
    var audioPlayer: AVAudioPlayer?
    var currSelected: Int?
	let fileExtension: String = "caf"
	
	var viewPresented: Bool!
	
    @IBOutlet weak var tableView: UITableView!
	
	let context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)

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
		
		// populate data array (arr) for the first time
		arr = self.getHighlightTitles()
		
		// create observers
		NotificationCenter.default.addObserver(self, selector: #selector(self.updateHighlights(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
		
		// hide empty cells
		tableView.tableFooterView = UIView(frame: CGRect.zero)
		
		viewPresented = true
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	var numToInsert: Int = 0
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		if numToInsert != 0 {
			updateRows()
		}
    }
	
	
	override func viewDidAppear(_ animated: Bool) {
		if numToInsert != 0 {
			updateRows()
		}
		viewPresented = true
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		viewPresented = false
	}
	
	override func viewWillDisappear(_ animated: Bool) {
//		print("\(#function)")
		if audioPlayer != nil {
			if audioPlayer!.isPlaying {
				audioPlayer!.stop()
				audioPlayer = nil
			}
		}
	}
	
	// MARK: - Core Data Save Notification
	@objc func updateHighlights(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty{
				print(inserts)
				// go through and add to tableView at the beginning and to the beginning of arr
				let insert = inserts.first!
				let title: String = insert.value(forKey: "title") as! String
				self.arr.insert(title, at: 0)
				
				if viewPresented == true {
					DispatchQueue.main.async {
						let path = IndexPath(row: 0, section: 0)
						self.tableView.beginUpdates()
						self.tableView.insertRows(at: [path], with: .fade)
						self.tableView.endUpdates()
					}
				} else {
					numToInsert += 1
				}
			}
		}
	}
	
	func updateRows() {
		var iPaths = [IndexPath]()
		for row in 0...self.numToInsert-1 {
			let iPath = IndexPath(row: row, section: 0)
			iPaths.append(iPath)
		}
		tableView.beginUpdates()
		tableView.insertRows(at: iPaths, with: .fade)
		tableView.endUpdates()
		self.numToInsert = 0
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
	
	// MARK: - Delete highlight
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
	
	// MARK: - AudioPlayer delegates
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print("\(#function)")
		audioPlayer = nil
		tableView.deselectRow(at: prevPath!, animated: true)
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
	
	// used inside extension
	var prevPath: IndexPath?
}

extension HighlightsViewController: UITableViewDelegate, UITableViewDataSource {
	
	// MARK: - Playing audio
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//		if let player = audioPlayer {
//			if player.isPlaying{
//				player.stop()
//			}
//			audioPlayer = nil
//		}
//		else{
//			setupPlayer(index: indexPath.row)
//			audioPlayer?.play()
//			print(audioPlayer?.duration ?? -1.0) // -1.0 is default value if the duration cannot be unwraped
//		}
		
		if self.prevPath != nil, self.prevPath == indexPath, self.audioPlayer != nil{
			if self.audioPlayer!.isPlaying {
				audioPlayer!.pause()
				tableView.deselectRow(at: indexPath, animated: true)
			} else {
				audioPlayer?.play()
			}
		} else {
			setupPlayer(index: indexPath.row)
			audioPlayer?.play()
			print(self.arr[indexPath.row] + ": " + (audioPlayer?.duration.description)!)
		}
		prevPath = indexPath
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
	
	// MARK: - Editing highlight name
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { (action, indexPath) in
			let alert = UIAlertController(title: "Modify Highlight Name", message: "What would you like to call this highlight?", preferredStyle: .alert)
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
				_ = try self.removeHighlightDatabaseAndFileSystem(title: self.arr[indexPath.row])
			} catch let error {
				print("delete error: \(error.localizedDescription)")
			}
			
			// delete in tableView
			self.arr.remove(at: indexPath.row)
			tableView.beginUpdates()
			tableView.deleteRows(at: [indexPath], with: .fade)
			tableView.endUpdates()
		})
		
		return [deleteAction, editAction]
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
	
	// MARK: - Unused delegate callbacks
	func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
		print("\(#function)")
		return indexPath
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
		print("\(#function)")
		if let player = audioPlayer {
			if player.isPlaying{
				player.stop()
				audioPlayer = nil
			}
		}
	}
	
	func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
		print("\(#function)")
	}
}








