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
    var audioPlayer: myPlayer?
    var currSelected: Int?
	let fileExtension: String = ".caf"
	let attribute_dateandtime: String = "dateandtime"
	let attribute_duration: String = "duration"
	let attribute_fileName: String = "fileName"
	let attribute_title: String = "title"
	var viewPresented: Bool!									// How is this used?
	let context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	let appdelegate = UIApplication.shared.delegate as! AppDelegate
	
	// MARK: GUI Stuff on HighlightsVC
    private let navBar: UIView = {
        let nav = UIView()
//		navBar.layer.shadowOpacity = 1
//		navBar.layer.shadowRadius = 5
        return nav
    }()
	
	private let titleItem: UILabel = {
		let title = UILabel()
		title.text = "Highlights"
		title.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
		title.textColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
		return title
	}()
	
	private let selectButton: UIButton = {
		let button = UIButton()
		button.setTitle(" Select ", for: .normal)
		button.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 16)
		button.setTitleColor(UIColor.black, for: .normal)
//		button.layer.backgroundColor = Settings.selectedColor.cgColor
		button.layer.backgroundColor = UIColor.white.cgColor
		button.layer.cornerRadius = 10
		return button
	}()
	
	private let infoButton: UIButton = {
		let button = UIButton()
		button.setTitle("  Info  ", for: .normal)
		button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
		button.setTitleColor(UIColor.white, for: .normal)
		button.layer.backgroundColor = Settings.unSelectedColor.cgColor
		button.layer.cornerRadius = 10
		
		return button
	}()
	
    @IBOutlet weak var tableView: UITableView!
	
	var highlightsModel: Highlights!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
		view.addSubview(navBar)
		setupNavBarConstraints()
		setupTableViewConstraints()
		navBar.addSubview(titleItem)
		setupTitleItemConstraints()
		navBar.addSubview(selectButton)
		setupSelectButtonConstraints()
		navBar.addSubview(infoButton)
		setupInfoButtonContraints()
		
		tableView.backgroundColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
		navBar.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)

        audioPlayer?.delegate = self
		
		// initialize file system urls
		docsURL = filemgr.urls(for: .documentDirectory, in: .userDomainMask)[0]
        highlightsURL = docsURL.appendingPathComponent("highlights")
//        let audioSession = AVAudioSession.sharedInstance()
		// play from bottom speaker
//        do {
//            try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
//        } catch let error as NSError {
//            print("audioSession error: \(error.localizedDescription)")
//        }
		
		// populate data array (arr) for the first time
//		arr = self.getHighlightTitles()
		highlightsModel = Highlights()
		self.getHighlightTitlesTwoD()
		
		// create observers
		NotificationCenter.default.addObserver(self, selector: #selector(self.updateHighlights(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.audioRouteChangeListener(notification:)), name: Notification.Name.AVAudioSessionRouteChange, object: nil)
		
		// hide empty cells
		tableView.tableFooterView = UIView(frame: CGRect.zero)
		tableView.estimatedRowHeight = 60.0
		tableView.rowHeight = UITableViewAutomaticDimension
		
		selectButton.addTarget(self, action: #selector(selectButtonClicked), for: .touchUpInside)
		isInMultipleSelectionMode = false
		
		infoButton.addTarget(self, action: #selector(infoButtonClicked), for: .touchUpInside)
		
		appdelegate.highlightsViewController = self
		
		viewPresented = true
		
//		printHighlightsDirectory()
//		printHighlightsDatabase()
    }
	
	func printHighlightsDatabase() {
		let managedobj_list = self.getHighlightsList()
		print("-----------------PRINTING highlights/ database content:-----------------")
		for element in managedobj_list {
			let obj = element as! NSManagedObject
			let title = obj.value(forKey: attribute_title) as! String
			let filename = obj.value(forKey: attribute_fileName) as! String
			print("Title: \(title).... FileName: \(filename)")
		}
	}
	
	func printHighlightsDirectory() {
		print("-----------------PRINTING highlights/ directory content:-----------------")
		do {
			let filelist = try filemgr.contentsOfDirectory(atPath: highlightsURL.path)
			for filename in filelist {
				print(filename)
			}
		} catch let error {
			print("Error: \(error.localizedDescription)")
		}
	}
	
	/*
	Need to delete highlights from highlightsURL folder
	@param titles : list of highlight names without file .caf extension
	*/
	func deleteHighlightsFromFilesystem(titles: [String]) {
		for title in titles {
			let fileurl = getFileURL(title: title)
			if filemgr.fileExists(atPath: fileurl.path) {
				do {
					try filemgr.removeItem(at: fileurl)
				} catch let error {
					print("Error: \(error.localizedDescription)")
				}
			}
		}
	}
	
	var playerView: HighlightPlayerView = HighlightPlayerView()
	func initializeHighlightPlayerView() {
		let playerContent = playerView.contentView!
		view.addSubview(playerContent)
		playerContent.alpha = 1.0
		playerContent.layer.cornerRadius = 10
		playerContent.layer.masksToBounds = true
		playerView.delegate = self
		setupHighlightPlayerViewConstraints()
	}
	
//    @IBAction func backButton(_ sender: UIButton) {
//       performSegue(withIdentifier: "homeSegue", sender: self)
//    }
	
	var isInMultipleSelectionMode: Bool {
		get {
			if tableView.allowsMultipleSelection {
				return true
			} else {
				return false
			}
		}
		set {
			if newValue == true{
				tableView.allowsMultipleSelection = true
				selectButton.setTitle(" Cancel ", for: .normal)
				if audioPlayer != nil {
					audioPlayer?.stop()
				}
				if playerView.contentView.superview != nil {
					removePlayerView()
				}
				addMultipleEditsView()
			}
			else {
				tableView.allowsMultipleSelection = false
				selectButton.setTitle(" Select ", for: .normal)
				removeMultipleEditsView()
			}
		}
	}
	private func printSelectedRows() {
		for path in selectedPaths {
			let cellTitle = getElementFromTwoDarr(indexPath: path)
			print(cellTitle)
		}
	}
	
	var multipleEditsView: MultipleEditsView = MultipleEditsView()
	private func addMultipleEditsView() {
		multipleEditsView.delegate = self
		updateMultipleViewButtons()
		if let bottomView = multipleEditsView.contentView {
			view.addSubview(bottomView)
			bottomView.backgroundColor = Settings.appThemeColor
			bottomView.translatesAutoresizingMaskIntoConstraints = false
			bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
			bottomView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
			bottomView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
			if deviceIsIPhoneX() {
				bottomView.heightAnchor.constraint(equalToConstant: 70).isActive = true
			} else {
				bottomView.heightAnchor.constraint(equalToConstant: 50).isActive = true
			}
		}
	}
	func deviceIsIPhoneX() -> Bool{
		if UIDevice().userInterfaceIdiom == .phone {
			if UIScreen.main.nativeBounds.height == 2436 {
				return true
			}
		}
		return false
	}
	private func removeMultipleEditsView() {
		multipleEditsView.contentView.removeFromSuperview()
	}
    
	@objc func selectButtonClicked() {
		print("\(#function)")
		if isInMultipleSelectionMode {
			isInMultipleSelectionMode = false
		} else {
			isInMultipleSelectionMode = true
		}
	}
	
	@objc func infoButtonClicked() {
		DispatchQueue.main.async {
			self.performSegue(withIdentifier: "idInfoPageSegue", sender: self)
		}
	}
	
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
		print("\(#function)")
		audioPlayer?.stop()
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
			if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {
				print("Deleted Item")
				print(deletes)
				let delete = deletes.first!
				print("CHECK")
				let delete_title = delete.value(forKey: attribute_title) as! String
				print(delete_title)
				
				if delete_title == playerView.title {
					print("MATCH")
					DispatchQueue.main.async {
						self.playerView.contentView.removeFromSuperview()
					}
				}
			}
		}
	}
	
	func updateRows() {
		var iPaths = [IndexPath]()
		tableView.beginUpdates()
		for (section, row) in twoDinserted.enumerated() {
			if row[0] == true {
				//insert section
				let section_idx = IndexSet(integer: section)
				
				tableView.insertSections(section_idx, with: .fade)
//				tableView.endUpdates()
			}
			for rowIdx in 0..<row.count {
				let iPath = IndexPath(row: rowIdx, section: section)
				iPaths.append(iPath)
			}
		}
		
//		tableView.beginUpdates()
		tableView.insertRows(at: iPaths, with: .fade)
//		tableView.reloadData() // BAD FIXME
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
	
	/*
	Was used previously to populate the 1D 'arr' data array for tableview
	*/
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
		// not yet
//		return (title + fileExtension)
	}
	
	func highlightTitleExists(title: String) -> Bool {
		let managedObj = getHighlightManagedObject(title: title)
		if managedObj != defaultNotFoundManagedObject {
			return true
		}
		return false
	}
	
	/**
	Look for highlight file in the file system
	- parameters:
		- url: url of file in filesystem
	**/
	func highlightFileExists(url: URL) -> Bool {
		if filemgr.fileExists(atPath: url.path) {
			return true
		}
		
		// did not find highlight
		return false
	}
	
	func getHighlightDuration(title: String) -> Double {
		let highlightManagedObject = getHighlightManagedObject(title: title)
		let duration: Double = highlightManagedObject.value(forKey: attribute_duration) as! Double
		return duration
	}
	
	func getFileURL(title: String) -> URL {
		let fileName = getHighlightFilename(title: title)
		let url = highlightsURL.appendingPathComponent(fileName)
		return url
	}
	
	// MARK: - Delete and rename highlight
	/*
	Deletes highlight from from filesystem and from datbase
	*/
	func removeHighlightDatabaseAndFileSystem(title: String) throws -> Bool {
		let managedObj = self.getHighlightManagedObject(title: title)
		
		// remove in filesystem
		deleteHighlightsFromFilesystem(titles: [title])
		
		// remove in database
		self.context.delete(managedObj)
		try self.context.save()
		
		// deletion complete successfully
		return true
	}
	
	/*
	First renames file in filesystem
	Then renames file in database and changes attribute 'title' and 'fileName'
	*/
	func renameHighlightDatabaseAndFileSystem(oldTitle: String, newTitle: String) -> Bool {
		print("BEFORE")
		printHighlightsDirectory()
		printHighlightsDatabase()
		
		//	add extension
		let oldFile: String = getHighlightFilename(title: oldTitle)			// add extension
//		let newFile: String = getHighlightFilename(title: newTitle)			// add extension
		let newFile: String = newTitle + ".caf"
		//	get url
		let oldPath: String = getHighlightURL(fileName: oldFile).path		// get path
		let newPath: String = getHighlightURL(fileName: newFile).path		// get path
		
		//*	Rename file in filesystem
		//	make sure file exists
		if !filemgr.fileExists(atPath: oldPath) {
			print("Error: File could not be renamed because it does not exist.")
			return false
		}
		//	now rename
		do {
			try filemgr.moveItem(atPath: oldPath, toPath: newPath)
			print("SUCCESSFUL: rename in filesystem.")
		} catch let error {
			print("Error: \(error.localizedDescription)")
			return false
		}
		
		//*	Rename filename and title in database
		let managedObj = getHighlightManagedObject(title: oldTitle)	// get database handle
		managedObj.setValue(newFile, forKey: attribute_fileName)
		managedObj.setValue(newTitle, forKey: attribute_title)
		do {
			try context.save()
		} catch let error {
			print("ERROR: \(error.localizedDescription)")
		}
		
		print("AFTER")
		printHighlightsDirectory()
		printHighlightsDatabase()
		
		// renamed successfully
		return true
	}
	
	/*
	Adds .caf extension to a file
	*/
	func getFileName(title: String) -> String {
		return (title + fileExtension)
	}
	
	/*
	returns highlight file url
	uses global highlight url and appends filename string
	*/
	func getHighlightURL(fileName: String) -> URL {
		return self.highlightsURL.appendingPathComponent(fileName)
	}
	
	// MARK: - headphone notifications
	@objc private func audioRouteChangeListener(notification: Notification) {
		guard let audioChangeReason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as? UInt else {
			return
		}

		switch audioChangeReason {
		case AVAudioSessionRouteChangeReason.newDeviceAvailable.rawValue:
			print("headphone plugged in")
			do {
				try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers, .defaultToSpeaker])
			} catch let error {
				print(error.localizedDescription)
			}
		case AVAudioSessionRouteChangeReason.oldDeviceUnavailable.rawValue:
			print("headphone plugged out")
			do {
				try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
				audioPlayer?.pause()
			} catch let error {
				print(error.localizedDescription)
			}
		default:
			break
		}
	}
	
	// MARK: - AudioPlayer delegates
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		print("\(#function)")
		
		//view will disappear 20 seconds after audio has finished playing
		DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
			if self.audioPlayer == nil {
//				self.playerView.contentView.removeFromSuperview()
				self.removePlayerView()
			}
		})
		audioPlayer = nil
		
//		tableView.deselectRow(at: prevPath!, animated: true)
//		prevCell?.setButtonPlay()
	}
	
	func removePlayerView() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.15, delay: 0, options: .transitionFlipFromRight, animations: {
				self.playerView.contentView.alpha = 0
			}, completion: { (_) in
				self.playerView.contentView.removeFromSuperview()
			})
		}
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
//		return twoDarr[indexPath.section][indexPath.row + 1]
		return highlightsModel.getHighlightTitle(indexPath: indexPath)
	}
	
	func setElementOfTwoDarr(indexPath: IndexPath, title: String) {
//		twoDarr[indexPath.section][indexPath.row + 1] = title
		highlightsModel.setHighlightTitle(indexPath: indexPath, title: title)
	}
	
	func removeElementOfTwoDarr(indexPath: IndexPath) {
//		twoDarr[indexPath.section].remove(at: indexPath.row + 1)
		highlightsModel.removeHighlightTitle(indexPath: indexPath)
	}
	
	// MARK: setting up constraints
	func setupHighlightPlayerViewConstraints() {
		playerView.titleLabel.textColor = UIColor.white
		let player = playerView.contentView!
		//		player.backgroundColor = Settings.appThemeColor
		player.translatesAutoresizingMaskIntoConstraints = false
		player.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		//		player.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5).isActive = true
		//		player.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5).isActive = true
		player.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -10).isActive = true
		player.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -35).isActive = true
		//		player.heightAnchor.constraint(equalToConstant: player.frame.height).isActive = true
		player.heightAnchor.constraint(equalToConstant: player.bounds.height).isActive = true
	}
	
	func setupNavBarConstraints() {
		navBar.translatesAutoresizingMaskIntoConstraints = false
		navBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
		navBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		navBar.heightAnchor.constraint(equalToConstant: 80).isActive = true
		navBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
	}
	
	func setupTitleItemConstraints() {
		titleItem.translatesAutoresizingMaskIntoConstraints = false
		titleItem.centerXAnchor.constraint(equalTo: navBar.centerXAnchor).isActive = true
		titleItem.bottomAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -20).isActive = true
	}
	
	func setupSelectButtonConstraints() {
		selectButton.translatesAutoresizingMaskIntoConstraints = false
		selectButton.rightAnchor.constraint(equalTo: navBar.rightAnchor, constant: -10).isActive = true
		//		selectButton.bottomAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -16).isActive = true
		selectButton.centerYAnchor.constraint(equalTo: titleItem.centerYAnchor, constant: 0).isActive = true
	}
	
	func setupInfoButtonContraints() {
		infoButton.translatesAutoresizingMaskIntoConstraints = false
		infoButton.leftAnchor.constraint(equalTo: navBar.leftAnchor, constant: 10).isActive = true
		infoButton.centerYAnchor.constraint(equalTo: titleItem.centerYAnchor, constant: 5).isActive = true
	}
	
	func setupTableViewConstraints() {
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
		tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
		tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
	}
	
	// MARK: initialize variables for extensions
	var prevPath: IndexPath?
	var prevCell: NormalHighlightCell?
	
	var selectedPaths: [IndexPath] = []
}

// MARK: - Player Delegate
extension HighlightsViewController: HighlightPlayerDelegate {
	func pressedPlayButton() {
		if let player = audioPlayer {
			// must be in paused state just play
			_ = player.play()
		}
		else {
			if let path = self.playerView.indexPath {
				let setup_success = setupPlayer(indexPath: path)
				if setup_success {
					let result = audioPlayer?.play()
					if result != nil, result! {
						tableView.selectRow(at: path, animated: true, scrollPosition: .top)
					}
					print(self.getElementFromTwoDarr(indexPath: path) + ": " + (audioPlayer?.duration.description)!)
				}
			}
		}
	}
	func pressedPauseButton() {
		if let player = audioPlayer {
			if player.isPlaying {
				player.pause()
			} else {
				print("player is not playing") // shouldn't happen
			}
		} else {
			print("player is nil") // also shouldn't happen
		}
	}
	func swipeDetected() {
		audioPlayer?.stop()
		removePlayerView()
		print("View removed")
	}
	func tapDetected() {
		if let path = self.playerView.indexPath {
			tableView.selectRow(at: path, animated: true, scrollPosition: .top)
		}
	}
}

// MARK: - TableView multiple edits view delegate
extension HighlightsViewController: MultipleEditsViewDelegate {
	func deletePressed() {
		print("DELETING HIGHLIGHTS...")
		printSelectedRows()
		isInMultipleSelectionMode = false
		if selectedPaths.count > 0 {
			deleteMultipleHighlights(indexPaths: selectedPaths)
		}
	}
	
	func editPressed() {
		print("EDITING HIGHLIGHT...")
		printSelectedRows()
		if selectedPaths.count == 1 {
			if let path = selectedPaths.first {
				editHighlight(indexPath: path)
			}
		}
		isInMultipleSelectionMode = false
	}
	
	func exportPressed() {
		print("EXPORTING HIGHLIGHTS...")
		printSelectedRows()
		exportMultipleHighlights(indexPaths: selectedPaths)
//		isInMultipleSelectionMode = false
	}
}

// MARK: - TableView Delegate and Data Source
extension HighlightsViewController: UITableViewDelegate, UITableViewDataSource {
	
	// MARK: - Playing audio
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if isInMultipleSelectionMode {
			let cell = tableView.cellForRow(at: indexPath) as! NormalHighlightCell
			setCellSelectionState(normalHighlightCell: cell)
			
			updateMultipleViewButtons()
		} else {
			// check if player window is there
			if playerView.superview == nil {
				// add to superview
				initializeHighlightPlayerView()
				print("added view")
			}
			else {
				print("did not need to create view")
			}
			
			let setup_success = setupPlayer(indexPath: indexPath)
			if !setup_success { // could not setup player properly
				// deselect cell
				tableView.deselectRow(at: indexPath, animated: true)
				return
			}
			
			_ = audioPlayer?.play()
			if AVAudioSession.sharedInstance().isOtherAudioPlaying {
				print("other audio is playing")
			}
			print(self.getElementFromTwoDarr(indexPath: indexPath) + ": " + (audioPlayer?.duration.description)!)
		}
	}
	
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if isInMultipleSelectionMode {
			let cell = tableView.cellForRow(at: indexPath) as! NormalHighlightCell
			setCellSelectionState(normalHighlightCell: cell)
			
			updateMultipleViewButtons()
		}
	}
	
	// updates the edit button on the multipleEditsView
	private func updateMultipleViewButtons() {
		if let paths = tableView.indexPathsForSelectedRows {
			selectedPaths = paths
		} else {
			selectedPaths.removeAll()
		}
		if selectedPaths.count > 0 {
			multipleEditsView.enableDeleteAndExportButton()
		}
		else {
			multipleEditsView.disableDeleteAndExportButton()
		}
		if selectedPaths.count == 1 {
			multipleEditsView.enableEditButton()
		} else {
			multipleEditsView.disableEditButton()
		}
	}
	
	func setupPlayer(indexPath: IndexPath) -> Bool{
		let highlightTitle = getElementFromTwoDarr(indexPath: indexPath)
		print("Title: \(highlightTitle)")
		print("FileName: \(self.getHighlightFilename(title: highlightTitle))")
//		let url = highlightsURL.appendingPathComponent(self.getHighlightFilename(title: highlightTitle))
		let url = getFileURL(title: highlightTitle)
		if !highlightFileExists(url: url) {
			return false
		}
		do {
			try audioPlayer = myPlayer(contentsOf: url)
			audioPlayer?.highlightPlayerView = playerView
			audioPlayer?.indexPath = indexPath
			audioPlayer?.tableView = tableView
			audioPlayer?.highlightTitle = highlightTitle
			audioPlayer?.delegate = self
			audioPlayer?.prepareToPlay()
		} catch let error as NSError {
			print("audioPlayer error \(error.localizedDescription)")
		}
		
		// player setup successfully
		return true
	}
	
	// FIXME: why do we need this?
	//	I think this was an attempt to setup player from a Cell class that knows title but not indexPath
	func setupPlayerFromTitle(title: String, cellRef: NormalHighlightCell) {
		let url = getFileURL(title: title)
		do {
			try audioPlayer = myPlayer(contentsOf: url)
//			audioPlayer?.cell = cellRef
			audioPlayer?.delegate = self
			audioPlayer?.prepareToPlay()
		} catch let error as NSError {
			print("audioPlayer error \(error.localizedDescription)")
		}
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
	
//	func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//		print("\(#function)")
//	}
//
//	func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
//		print("\(#function)")
//	}
	
	// MARK: - Table view cell content	
	func numberOfSections(in tableView: UITableView) -> Int {
		let numSections = twoDarr.count
		if numSections == 0 {
			let label: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
			label.text = "All your highlights will appear here. Swipe right to go to the Home page and start capturing highlights!"
			label.font = UIFont(name: "HelveticaNeue", size: 16)
			label.textColor = Settings.appThemeColor
			label.textAlignment = .center
			tableView.backgroundView = label
			label.numberOfLines = 7
			tableView.separatorStyle = .none
		} else {
			tableView.backgroundView = nil
		}
		return numSections
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
//		cell.delegate = self
		
		setCellSelectionState(normalHighlightCell: cell)
		
		return cell
	}
	
	func setCellSelectionState(normalHighlightCell: NormalHighlightCell) {
		if isInMultipleSelectionMode {
			if normalHighlightCell.isSelected == true {
//				normalHighlightCell.accessoryType = .checkmark
				normalHighlightCell.accessoryType = .none	// for now because the checkmarks repeat even though they're being reset everything a cell is reused inside cellForRowAt
			} else {
				normalHighlightCell.accessoryType = .none
			}
		}
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if twoDarr.count > section {
			if twoDarr[section].count > 0 {
				return twoDarr[section][0]
			}
		}
		return "unexpected section header"
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		view.tintColor = Settings.appThemeColor
		view.backgroundColor = UIColor.init(white: 1, alpha: 0.0)
		let header = view as! UITableViewHeaderFooterView
		header.textLabel?.textColor = UIColor.white
	}
	
	// MARK: - Modifying tableview cells
	@available(iOS 11.0, *)
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, handler) in
			self.deleteHighlight(indexPath: indexPath)
			tableView.reloadData() // FIXME: shouldn't do this
		}
		let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, handler) in
			self.editHighlight(indexPath: indexPath)
//			tableView.reloadData() // FIXME: shouldn't do this
		}
		let exportAction = UIContextualAction(style: .normal, title: "Export") { (action, view, handler) in
			self.exportHighlight(indexPath: indexPath)
//			tableView.reloadData() // FIXME: shouldn't do this
		}

		deleteAction.backgroundColor = Settings.selectedColor
		editAction.backgroundColor = Settings.unSelectedColor
		exportAction.backgroundColor = Settings.appThemeColor
		let actions = [deleteAction, editAction, exportAction]
		let configuration = UISwipeActionsConfiguration(actions: actions)
		configuration.performsFirstActionWithFullSwipe = true
		if isInMultipleSelectionMode {
			return UISwipeActionsConfiguration()
		} else {
			return configuration
		}
	}
	
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { (action, indexPath) in
			self.editHighlight(indexPath: indexPath)
		})
		
		let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
			self.deleteHighlight(indexPath: indexPath)
		})
		
		// export to photo library
		let exportAction = UITableViewRowAction(style: .normal, title: "Export", handler: { (action, indexPath) in
			self.exportHighlight(indexPath: indexPath)
		})
		
		deleteAction.backgroundColor = Settings.selectedColor
		editAction.backgroundColor = Settings.unSelectedColor
		exportAction.backgroundColor = Settings.appThemeColor
		
		if isInMultipleSelectionMode {
			return []
		} else {
			return [deleteAction, editAction, exportAction]
		}
	}
	
	func deleteMultipleHighlights(indexPaths: [IndexPath]) {
		let reversepaths = indexPaths.sorted().reversed()
		for path in reversepaths {
			deleteHighlight(indexPath: path)
		}
	}
	
	func deleteHighlight(indexPath: IndexPath) {
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
			tableView.reloadData()		//BAD SHOULDN'T RELOAD EVERYTHING
			tableView.endUpdates()
		}
	}
	
	func editHighlight(indexPath: IndexPath) {
		let alert = UIAlertController(title: "Modify Highlight Name", message: "What would be a suitable name for this highlight? 🤔", preferredStyle: .alert)
		alert.addTextField(configurationHandler: { (textField) in
			textField.delegate = self
			textField.autocapitalizationType = .sentences
			textField.text = self.getElementFromTwoDarr(indexPath: indexPath)
//			textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//			textField.selectAll(nil)
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
//				let managedObj = self.getHighlightManagedObject(title: oldName)
//				managedObj.setValue(newName, forKey: self.attribute_title)
//				let fileName = newName + fileExtension
//				managedObj.setValue(fileName, forKey: self.attribute_fileName)
				do {
					try self.context.save()
					// FIRST: Rename on filesystem and databse
					let success = self.renameHighlightDatabaseAndFileSystem(oldTitle: oldName, newTitle: newName)
					
					if success {
						//	rename on twoDarr
						self.setElementOfTwoDarr(indexPath: indexPath, title: newName)
						//	update tableview
						self.tableView.reloadRows(at: [indexPath], with: .fade)
						
						//	also change on playerview
						if self.playerView.title == oldName {
							self.playerView.title = newName
						}
					}
					else {	// show alert error
						let renameErrorAlert = UIAlertController(title: "Rename Error", message: "Highlight coud not be renamed.", preferredStyle: .alert)
						renameErrorAlert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
						self.present(renameErrorAlert, animated: true)
					}
				} catch let error {
					print(error.localizedDescription)
				}
			}
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		self.present(alert, animated: false)
	}
	
	//*	Should wrap around exporMultipleHighlights(indexPaths: [IndexPath])
	func exportHighlight(indexPath: IndexPath) {
		let path_arr = [indexPath]
		exportMultipleHighlights(indexPaths: path_arr)
	}
	
	func exportMultipleHighlights(indexPaths: [IndexPath]) {
		if indexPaths.count > 0 {
			var activityItems: [URL] = []
			for path in indexPaths {
				let fileURL = self.getFileURL(title: self.getElementFromTwoDarr(indexPath: path))
				activityItems.append(fileURL)
			}
			let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
			self.present(activityViewController, animated: true, completion: {
				print("Export completed successfully")
			})
		}
	}
	
	// MARK: - Unused delegate callbacks
	func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		print("\(#function)")
		return indexPath
	}
	
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

extension HighlightsViewController: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
	}
}

class myPlayer: AVAudioPlayer {
	
//	var cell: NormalHighlightCell?
	
	var highlightPlayerView: HighlightPlayerView?
	
	var appdelegate = UIApplication.shared.delegate as! AppDelegate
	
	var tableView: UITableView?
	var indexPath: IndexPath?
	var highlightTitle: String?
//	override init(contentsOf url: URL) throws {
//		try super.init(contentsOf: url)
//		appdelegate.audioPlayer = self
//	}
	
	deinit {
//		appdelegate.audioPlayer = nil
	}
	
	override func play() -> Bool {
		let returnval = super.play()
		
		appdelegate.audioPlayer = self
		
//		cell?.setButtonStop()
		if returnval {
			setHighlightPlayerView(isPlayingHighlight: true)
		}
		
		highlightPlayerView?.indexPath = indexPath
		selectHighlightRow()
		
		return returnval
	}
	
	override func stop() {
		super.stop()
//		cell?.setButtonPlay()
		setHighlightPlayerView(isPlayingHighlight: false)
		
		deselectHighlightRow()
	}
	
	func deselectHighlightRow (){
		if let path = indexPath {
			tableView?.deselectRow(at: path, animated: true)
			//			print("deselecting inside stop")
		}
	}
	
	func selectHighlightRow() {
		if let path = indexPath {
			tableView?.selectRow(at: path, animated: true, scrollPosition: .none)
			//			print("deselecting inside stop")
		}
	}
	
	override func pause() {
		super.pause()
//		cell?.setButtonPlay()
		setHighlightPlayerView(isPlayingHighlight: false)
	}
	
	func setHighlightPlayerView(isPlayingHighlight: Bool) {
		if isPlayingHighlight {
			highlightPlayerView?.setPlaying()
			
			if let title = highlightTitle {
				highlightPlayerView?.title = title
			}
		} else {
			highlightPlayerView?.setPaused()
		}
	}
}

//import GoogleAPIClientForREST
//import GoogleSignIn
//
//extension HighlightsViewController: GIDSignInDelegate {
//	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//		let service = (UIApplication.shared.delegate as! AppDelegate)
//		if let _ = error {
//			service.authorizer = nil
//		} else {
//			service.authorizer = user.authentication.fetcherAuthorizer()
//		}
//	}
//}






