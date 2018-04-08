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
	let fileExtension: String = "caf"
    
    
    private let navBar: UIView = {
        let nav = UIView()
//        let titleItem = UILabel()
//        nav.addSubview(titleItem)
//        titleItem.text = "Highlights"
//        titleItem.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
//        titleItem.textColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
//        titleItem.translatesAutoresizingMaskIntoConstraints = false
//        titleItem.centerXAnchor.constraint(equalTo: nav.centerXAnchor).isActive = true
//        titleItem.bottomAnchor.constraint(equalTo: nav.bottomAnchor, constant: -20).isActive = true
		
//		let selectButton = UIButton()
//		nav.addSubview(selectButton)
//		selectButton.setTitle("Select", for: .normal)
//		selectButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 16)
//		selectButton.setTitleColor(UIColor.white, for: .normal)
//		selectButton.rightAnchor.constraint(equalTo: nav.rightAnchor).isActive = true
//		selectButton.bottomAnchor.constraint(equalTo: nav.bottomAnchor, constant: -20).isActive = true
		
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
        
        view.addSubview(navBar)
        setupNavBarConstraints()
        setupTableViewConstraints()
		navBar.addSubview(titleItem)
		setupTitleItemConstraints()
		navBar.addSubview(selectButton)
		setupSelectButtonConstraints()
        tableView.backgroundColor = UIColorFromRGB(rgbValue: 0xFFFFFF)
        navBar.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        
//        navBar.layer.shadowOpacity = 1
//        navBar.layer.shadowRadius = 5

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
		
		viewPresented = true
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
	func setupHighlightPlayerViewConstraints() {
		playerView.titleLabel.textColor = UIColor.white
		let player = playerView.contentView!
//		player.backgroundColor = Settings.appThemeColor
		player.translatesAutoresizingMaskIntoConstraints = false
		player.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//		player.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5).isActive = true
//		player.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5).isActive = true
		player.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -10).isActive = true
		player.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
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
    
    func setupTableViewConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
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
				selectButton.setTitle(" Cancle ", for: .normal)
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
			bottomView.heightAnchor.constraint(equalToConstant: 50).isActive = true
		}
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
				setupPlayer(indexPath: path)
				let result = audioPlayer?.play()
				if result != nil, result! {
					tableView.selectRow(at: path, animated: true, scrollPosition: .top)
				}
				print(self.getElementFromTwoDarr(indexPath: path) + ": " + (audioPlayer?.duration.description)!)
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
		isInMultipleSelectionMode = false
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
			
			setupPlayer(indexPath: indexPath)
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
	
	func setupPlayer(indexPath: IndexPath) {
		let highlightTitle = getElementFromTwoDarr(indexPath: indexPath)
		let url = highlightsURL.appendingPathComponent(self.getHighlightFilename(title: highlightTitle))
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
	}
	
	func setupPlayerFromTitle(title: String, cellRef: NormalHighlightCell) {
		let url = highlightsURL.appendingPathComponent(self.getHighlightFilename(title: title))
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
		return configuration
	}
	
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { (action, indexPath) in
			self.editHighlight(indexPath: indexPath)
		})
		
		let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
			self.deleteHighlight(indexPath: indexPath)
		})
		
		// export to photo library
		let exportAction = UITableViewRowAction(style: .destructive, title: "Export", handler: { (action, indexPath) in
			self.exportHighlight(indexPath: indexPath)
		})
		
		return [deleteAction, editAction, exportAction]
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
				let managedObj = self.getHighlightManagedObject(title: oldName)
				managedObj.setValue(newName, forKey: self.attribute_title)
				do {
					try self.context.save()
					//		self.arr[indexPath.row] = newName
					self.setElementOfTwoDarr(indexPath: indexPath, title: newName)
					self.tableView.reloadRows(at: [indexPath], with: .fade)
					
					//	also change on playerview
					if self.playerView.title == oldName {
						self.playerView.title = newName
					}
				} catch let error {
					print(error.localizedDescription)
				}
			}
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		self.present(alert, animated: false)
	}
	
	func exportHighlight(indexPath: IndexPath) {
		let fileURL = self.getFileURL(from: self.getElementFromTwoDarr(indexPath: indexPath))
		let activityItems = [fileURL]
		let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
		self.present(activityViewController, animated: true, completion: {
			print("Export completed successfully")
		})
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
		setHighlightPlayerView(isPlayingHighlight: true)
		
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






