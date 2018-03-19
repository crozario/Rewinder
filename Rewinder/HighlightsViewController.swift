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
	var twoDarr = [[String]]()
	var filemgr = FileManager.default
	var docsURL: URL!
	var highlightsURL: URL!
    var audioPlayer: AVAudioPlayer?
    var currSelected: Int?
	let fileExtension: String = "caf"
	
	var viewPresented: Bool!
	
//    @IBOutlet weak var dismissHighlightPageButton: RoundButton!
    @IBOutlet weak var tableView: UITableView!
	
	let context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	let attribute_dateandtime: String = "dateandtime"
	let attribute_duration: String = "duration"
	let attribute_fileName: String = "fileName"
	let attribute_title: String = "title"
	
//    @IBAction func dismissHighlightVC(_ sender: RoundButton) {
//        self.dismiss(animated: true, completion: nil)
//    }
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
//		arr = self.getHighlightTitles()
		
		self.getHighlightTitlesTwoD()
		
		// create observers
		NotificationCenter.default.addObserver(self, selector: #selector(self.updateHighlights(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
		
		// hide empty cells
		tableView.tableFooterView = UIView(frame: CGRect.zero)
		tableView.estimatedRowHeight = 60.0
		tableView.rowHeight = UITableViewAutomaticDimension
		
		viewPresented = true
    }
    
    
//    @IBAction func backButton(_ sender: UIButton) {
//       performSegue(withIdentifier: "homeSegue", sender: self)
//    }
    
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	var numToInsert: Int = 0
	var twoDinserted = [[Bool]]()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		if !twoDinserted.isEmpty {
			updateRows()
		}
    }
	
	
	override func viewDidAppear(_ animated: Bool) {
		if !twoDinserted.isEmpty {
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
	
	// CONTINUE NOTE: Insert sections into the tableview real time and change all the arr write and reads to twoDarr
	// MARK: - Core Data Save Notification
	@objc func updateHighlights(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty{
				print(inserts)
				// go through and add to tableView at the beginning and to the beginning of arr
				let insert = inserts.first!
//				self.arr.insert(title, at: 0)
				let newSectionInserted: Bool = appendTo2Darr(managedObject: insert)
				
				if viewPresented == true {
					DispatchQueue.main.async {
						self.tableView.beginUpdates()
						if newSectionInserted {
							let section_idx = IndexSet(integer: 0)
							self.tableView.insertSections(section_idx, with: .fade)
						}
						let path = IndexPath(row: 0, section: 0)
						self.tableView.insertRows(at: [path], with: .fade)
						self.tableView.endUpdates()
					}
				} else {
					if twoDinserted.isEmpty || newSectionInserted {
						if newSectionInserted {
							twoDinserted.insert([true], at: 0)
						} else {
							twoDinserted.insert([false], at: 0)
						}
					} 
					else {
						twoDinserted[0].append(false)
					}
				}
			}
		}
	}
	
	func updateRows() {
		var iPaths = [IndexPath]()

		for (section, row) in twoDinserted.enumerated() {
			if row[0] == true {
				//insert section
				let section_idx = IndexSet(integer: section)
				tableView.beginUpdates()
				tableView.insertSections(section_idx, with: .fade)
				tableView.endUpdates()
			}
			for rowIdx in 0..<row.count {
				let iPath = IndexPath(row: rowIdx, section: section)
				iPaths.append(iPath)
			}
		}
		
		tableView.beginUpdates()
		tableView.insertRows(at: iPaths, with: .fade)
		tableView.endUpdates()
		
		twoDinserted.removeAll(keepingCapacity: false)
	}
	
	// MARK: - Core data getters
	func getHighlightsList() -> [NSFetchRequestResult] {
		let entityDescription = NSEntityDescription.entity(forEntityName: "HighlightEntity", in: context)
		let request: NSFetchRequest<HighlightEntity> = HighlightEntity.fetchRequest()
		let sortDescriptor = NSSortDescriptor(key: attribute_dateandtime, ascending: true)
		
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
			titles.append((managedObject.value(forKey: attribute_title) as? String)!)
		}
		return titles
	}
	
	func getHighlightTitlesTwoD(){
		let results = self.getHighlightsList()
		
		for element in results {
			let managedObj = element as! NSManagedObject
			_ = appendTo2Darr(managedObject: managedObj)
		}
	}
	
	func appendTo2Darr(managedObject: NSManagedObject) -> Bool {
		
		var newSectionInserted: Bool = false
		
		let date: Date = managedObject.value(forKey: attribute_dateandtime) as! Date
		let currDate: String = getDate(date: date)
		let title: String = managedObject.value(forKey: attribute_title) as! String
		
		if !twoDarr.isEmpty {
			// should never have twoDarr[0].count == 0 so don't need to check
			let prevDate: String = twoDarr[0][0]
			
			if currDate == prevDate {
				twoDarr[0].insert(title, at: 1)
				newSectionInserted = false
			}
			else {
				twoDarr.insert([currDate], at: 0)
				twoDarr[0].insert(title, at: 1)
				newSectionInserted = true
			}
		} else {
			twoDarr.insert([currDate], at: 0)
			twoDarr[0].insert(title, at: 1)
			newSectionInserted = true
		}
		return newSectionInserted
	}
	
    func getDate(date: Date) -> String{
        // in "en_US" format; ex: Mar 15, 2018
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US")
        
        return dateFormatter.string(from: date)
    }
    
	func print2D(_ arr: [[String]]) {
		for sublist in arr {
			print(sublist)
		}
	}
	
	let defaultNotFoundManagedObject: NSManagedObject = NSManagedObject()
	func getHighlightManagedObject(title: String) -> NSManagedObject {
		let entityDescription = NSEntityDescription.entity(forEntityName: "HighlightEntity", in: context)
		let request: NSFetchRequest<HighlightEntity> = HighlightEntity.fetchRequest()
		let sortDescriptor = NSSortDescriptor(key: attribute_dateandtime, ascending: true)
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
		let highlightManagedObject = getHighlightManagedObject(title: title)
		let fileName = highlightManagedObject.value(forKey: attribute_fileName) as! String
		return fileName
	}
	
	func highlightTitleExists(title: String) -> Bool {
		let managedObj = getHighlightManagedObject(title: title)
		if managedObj != defaultNotFoundManagedObject {
			return true
		}
		return false
	}
	
	func getHighlightDuration(title: String) -> Double {
		let highlightManagedObject = getHighlightManagedObject(title: title)
		let duration: Double = highlightManagedObject.value(forKey: attribute_duration) as! Double
		return duration
	}
	
	func getFileURL(from title: String) -> URL {
		let fileName = getHighlightFilename(title: title)
		let url = highlightsURL.appendingPathComponent(fileName)
		return url
	}
	
	// MARK: - Delete highlight
	func removeHighlightDatabaseAndFileSystem(title: String) throws -> Bool {
		let managedObj = self.getHighlightManagedObject(title: title)
		
		// remove in filesystem
		let file = managedObj.value(forKey: attribute_fileName) as! String
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
//		tableView.deselectRow(at: prevPath!, animated: true)
		prevCell?.setButtonPlay()
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
	
	func getElementFromTwoDarr(indexPath: IndexPath) -> String {
		return twoDarr[indexPath.section][indexPath.row + 1]
	}
	
	func setElementOfTwoDarr(indexPath: IndexPath, title: String) {
		twoDarr[indexPath.section][indexPath.row + 1] = title
	}
	
	func removeElementOfTwoDarr(indexPath: IndexPath) {
		twoDarr[indexPath.section].remove(at: indexPath.row + 1)
	}
	
	// used inside extension
	var prevPath: IndexPath?
	var prevCell: NormalHighlightCell?
}

extension HighlightsViewController: HighlightCellDelegate {
	func didTapPlayback(title: String, cell: NormalHighlightCell) {
		print("tapped playback on \(title)")
		if prevCell != nil, prevCell?.getTitle() == title, audioPlayer != nil {
			if audioPlayer!.isPlaying {
				audioPlayer!.pause()
				cell.setButtonPlay()
			} else {
				audioPlayer!.play()
				cell.setButtonStop()
			}
		} else {
			setupPlayerFromTitle(title: title)
			audioPlayer?.play()
			cell.setButtonStop()
			prevCell?.setButtonPlay()
			print(title + ": " + (audioPlayer?.duration.debugDescription)!)
		}
		prevCell = cell
	}
}

extension HighlightsViewController: UITableViewDelegate, UITableViewDataSource {
	
	// MARK: - Playing audio
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
//		if self.prevPath != nil, self.prevPath == indexPath, self.audioPlayer != nil{
//			if self.audioPlayer!.isPlaying {
//				audioPlayer!.pause()
//				tableView.deselectRow(at: indexPath, animated: true)
//			} else {
//				audioPlayer!.play()
//			}
//		} else {
//			setupPlayer(indexPath: indexPath)
//			audioPlayer?.play()
//			print(self.getElementFromTwoDarr(indexPath: indexPath) + ": " + (audioPlayer?.duration.description)!)
//		}
//		prevPath = indexPath
	}
	
	func setupPlayer(indexPath: IndexPath) {
		let url = highlightsURL.appendingPathComponent(self.getHighlightFilename(title: self.getElementFromTwoDarr(indexPath: indexPath)))
		do {
			try audioPlayer = AVAudioPlayer(contentsOf: url)
			audioPlayer?.delegate = self
			audioPlayer?.prepareToPlay()
		} catch let error as NSError {
			print("audioPlayer error \(error.localizedDescription)")
		}
	}
	
	func setupPlayerFromTitle(title: String) {
		let url = highlightsURL.appendingPathComponent(self.getHighlightFilename(title: title))
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
				textField.text = self.getElementFromTwoDarr(indexPath: indexPath)
				textField.clearButtonMode = .always
			})
			alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (updateAction) in
				let newName = alert.textFields!.first!.text!
				let oldName = self.getElementFromTwoDarr(indexPath: indexPath)
				
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
					managedObj.setValue(newName, forKey: self.attribute_title)
					do {
						try self.context.save()
//						self.arr[indexPath.row] = newName
						self.setElementOfTwoDarr(indexPath: indexPath, title: newName)
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
				let element = self.getElementFromTwoDarr(indexPath: indexPath)
				_ = try self.removeHighlightDatabaseAndFileSystem(title: element)
			} catch let error {
				print("delete error: \(error.localizedDescription)")
			}
			
			// delete in tableView
//			self.arr.remove(at: indexPath.row)
			self.removeElementOfTwoDarr(indexPath: indexPath)
			tableView.beginUpdates()
			tableView.deleteRows(at: [indexPath], with: .fade)
			tableView.endUpdates()
			
			// check if the section still has any rows (delete section if not)
			if self.twoDarr[indexPath.section].count == 1 {
//				print("BEFORE")
//				self.print2D(self.twoDarr)
				self.twoDarr.remove(at: indexPath.section)
//				print("AFTER")
//				self.print2D(self.twoDarr)
				tableView.beginUpdates()
				var section_indexset = IndexSet()
				section_indexset.insert(indexPath.section)
				tableView.deleteSections(section_indexset, with: .fade)
				tableView.reloadData()
				tableView.endUpdates()
			}
		})
		
		// export to photo library
		let exportAction = UITableViewRowAction(style: .destructive, title: "Export", handler: { (action, indexPath) in
			let fileURL = self.getFileURL(from: self.getElementFromTwoDarr(indexPath: indexPath))
			let activityItems = [fileURL]
			let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
			self.present(activityViewController, animated: true, completion: {
				print("Export completed successfully")
			})
		})
		
		return [deleteAction, editAction, exportAction]
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
	
	// MARK: - Table view cell content	
	func numberOfSections(in tableView: UITableView) -> Int {
		return twoDarr.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (twoDarr[section].count - 1)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let reuseId = "idNormalHighlightCell"
		let cell =  tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! NormalHighlightCell
		
//		cell.textLabel?.text = getElementFromTwoDarr(indexPath: indexPath)
		let title = getElementFromTwoDarr(indexPath: indexPath)
		cell.setTitle(title)
		let duration = getHighlightDuration(title: title)
		cell.setDuration(duration)
		cell.delegate = self
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if twoDarr.count > section {
			if twoDarr[section].count > 0 {
				return twoDarr[section][0]
			}
		}
		return "unexpected"
	}
	
	// MARK: - Unused delegate callbacks
	func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
		print("\(#function)")
		return indexPath
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
		print("\(#function)")
	}
}








