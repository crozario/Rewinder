
//
//  AppDelegate.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/24/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AudioKit
import CallKit
import GoogleAPIClientForREST
//import GoogleSignIn
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate /*, GIDSignInDelegate*/ { //GOOGLE UNCOMMENT

	var window: UIWindow?
	var audioPlayer: myPlayer?
	var audioRecorder: myRecorder?
	var audioSession: AVAudioSession?
	var home: HomeViewController?
	var highlightsViewController: HighlightsViewController? // not using it yet (but is initialized from highlightsVC)
	
	var havePermission: Bool = false
	var undeterminedPermission: Bool = false
	
	//	let settingFile: String = "highlightsettings.txt"
	var settingsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("highlightsettings.txt")
	
	// MARK: - Google stuff added
	//GOOGLE UNCOMMENT
	/*
	fileprivate let service = GTLRDriveService()
	private func setupGoogleSignIn() {
		GIDSignIn.sharedInstance().delegate = self as GIDSignInDelegate
		GIDSignIn.sharedInstance().uiDelegate = self as! GIDSignInUIDelegate
		GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDriveFile]
		GIDSignIn.sharedInstance().signInSilently()
	}
	
	func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
		return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
	}
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String
		let annotation = options[UIApplicationOpenURLOptionsKey.annotation]
		return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
	}
	
	//https://stackoverflow.com/a/42829231/7303112
	//GIDSignInDelegate protocol method
	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
		if let _ = error {
			service.authorizer = nil
		} else {
			service.authorizer = user.authentication.fetcherAuthorizer()
		}
	}
	// advised to implement on stackoverflow ^
//	func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
//
//	}
	*/
	
	// MARK: - Main Application Actions
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		checkPermissions()
		self.initializeSettings()
		
		application.statusBarStyle = .lightContent
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: .AVAudioSessionInterruption, object: nil) // FIXME: UNTESTED
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.handleSecondaryAudio(notification:)), name: .AVAudioSessionSilenceSecondaryAudioHint, object: nil) // FIXME: UNTESTED
		
		print("ON PHONE CALL: \(self.isOnPhoneCall())")
		
		//GOOGLE UNCOMMENT
//		GIDSignIn.sharedInstance().clientID = "1013009439972-tqssvh2483slkt0ahfj04df4s0prvp1o.apps.googleusercontent.com"
		
		return true
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		print("\(#function)")
		
		checkPermissions()
		
		guard home != nil else {
			print("ERROR: home reference inside AppDelegate never set")
			return
		}
		
		if havePermission {
			if isOnPhoneCall() {
				// segue
				DispatchQueue.main.async {
					self.home!.performSegue(withIdentifier: "idInPhoneCallSegue", sender: self)
				}
			} else {
				executeFirstTime(force: false)
			}
		}
		else {
			if !undeterminedPermission {
				DispatchQueue.main.async {
					self.home!.performSegue(withIdentifier: "idDeniedPermissionSegue", sender: self.home!)
				}
			}
		}
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		print("\(#function)")
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		print("\(#function)")
		//ALWAYS DO THIS
		home?.continueRecording = true
		
		if !Settings.continueRecordingInBackground {
			// start audio session
			activateAudioSession()
			
			// begin recording
			home?.firstBeginRecording()
			
			// start AudioKit
			startAudioKit()
		} else {
			// start AudioKit
			//			startAudioKit()
		}
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		print("\(#function)")
		
		audioPlayer?.stop() // stop it for now (until we can add controles to control center to be able to play and pause audio from outside app
		
		if !Settings.continueRecordingInBackground {
			home?.continueRecording = false
			
			stopEverything()
		} else {
			// stop AudioKit
			//			stopAudioKit() // FIXME: can't stop audiokit because for some reason it stops the audiosession too
		}
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		print("\(#function)")
		
		//		self.saveContext() ---DONT NEED; Data is saved to core data in Audio.swift
		stopEverything()
		self.saveSettings()
	}
	
	// MARK: - Core Data stack
	
	lazy var persistentContainer: NSPersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let container = NSPersistentContainer(name: "Rewinder")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	// MARK: - Notification Handles
	@objc func handleInterruption(_ notification: Notification) {
		print("\(#function)")
		guard let info = notification.userInfo,
			let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
			let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
				return
		}
		if type == .began {
			print("Interruption Began")
			// pause recording
			self.audioRecorder?.pause()
			// pause playing
			self.audioPlayer?.pause()
		}
		else if type == .ended {
			print("Interruption Ended")
			// resume recording
			self.audioRecorder?.record()
			// don't resume playing (because i'm lazy)
			guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else {
				return
			}
			let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
			if options.contains(.shouldResume) {
				print("options: \(options)")
			}
		}
	}

	
	@objc func handleSecondaryAudio(notification: Notification) {
		// Determine hint type
		guard let userInfo = notification.userInfo,
			let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
			let type = AVAudioSessionSilenceSecondaryAudioHintType(rawValue: typeValue) else {
				return
		}

		if type == .begin {
			// Other app audio started playing - mute secondary audio
			print("Other app audio STARTED playing")
		} else {
			// Other app audio stopped playing - restart secondary audio
			print("Other app audio STOPPED playing")
		}
	}
	
	// MARK: - Other Helper Functions
	// stops recording, stops audiokit and deactivates audio session
	private func stopEverything() {
		// stop recording and playing
		audioRecorder?.stop()
		
		// stop AudioKit
		stopAudioKit()
		
		// stop session
		deactivateAudioSession()
	}
	
	var firstTime: Bool = true
	private func executeFirstTime(force: Bool) { //assumes home is not nil
		print("\(#function) \(force)")
		if firstTime || force {
			home!.initializeAKMicrphone() // initialize microphone
			
			home!.initializeRollingPlot()
			
			configureAudioSession()
			// start audiokit
			startAudioKit()
			//				home!.startAudioKit(true)
			// start recording
			home!.firstBeginRecording() // FIXME: Will cause weird behavior when scroll view is removed because then the viewDidAppear will be triggered more often
			firstTime = false
		}
	}
	
	func requestPermissionToMicrophone() {
		print("\(#function)")
		let session = AVAudioSession.sharedInstance()
		if session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:))) {
			session.requestRecordPermission({ (granted: Bool) in
				DispatchQueue.main.async {
					self.applicationDidBecomeActive(UIApplication.shared)
				}
				if granted {
					print("User granted Permission.")
					//					self.executeFirstTime(force: true)
				} else {
					print("User denied Permission.")
				}
			})
		}
	}
	
	// MARK: Audio Session
	func configureAudioSession() {
		let session = AVAudioSession.sharedInstance()
		do {
			//			try session.overrideOutputAudioPort(.speaker)
			//			try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers /*, .defaultToSpeaker*/])
			let currentRoute = AVAudioSession.sharedInstance().currentRoute
			if currentRoute.outputs.count > 0 {
				for description in currentRoute.outputs {
					if description.portType == AVAudioSessionPortHeadphones {
						print("HEADPHONE plugged in")
						try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers, .defaultToSpeaker])
					} else {
						print("HEADPHONE pulled out")
						try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .mixWithOthers)
						try session.overrideOutputAudioPort(.speaker)
					}
				}
			} else {
				print("requires connection to device")
			}
			//			try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
			try session.setActive(true, with: .notifyOthersOnDeactivation)
		} catch let error {
			print("Error setting up audiosession: \(error.localizedDescription)")
		}
	}
	
	// Audio Sessions
	func activateAudioSession() {
		audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession?.setActive(true)
		} catch let error {
			print("Error reactivating audiosession: \(error.localizedDescription)")
		}
	}
	
	func deactivateAudioSession() {
		audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession?.setActive(false)
		} catch let error {
			print("Error closing audiosession: \(error.localizedDescription)")
		}
	}
	
	func startAudioKit() {
		// start AudioKit
		do {
			try AudioKit.start()
		} catch let error {
			print("AudioKit start error: \(error.localizedDescription)")
		}
	}
	
	func stopAudioKit() {
		// stop AudioKit
		do {
			try AudioKit.stop()
		} catch let error {
			print("AudioKit stop error: \(error.localizedDescription)")
		}
	}
	
	func checkPermissions() {
		print("\(#function)")
		let session = AVAudioSession.sharedInstance()
		switch session.recordPermission() {
		case .granted:
			print("Have permission to record")
			havePermission = true
			undeterminedPermission = false
		case .denied:
			print("Denied permission")
			havePermission = false
			undeterminedPermission = false
		case .undetermined:
			print("Undetermined")
			havePermission = false
			undeterminedPermission = true
		}
	}
	
	func isOnPhoneCall() -> Bool {
		for call in CXCallObserver().calls {
			if call.hasEnded == false {
				return true
			}
		}
		return false
	}
	
	// MARK: - Saving and loading settings
	func initializeSettings() {
		print("\(#function)")
		let fileHandle: FileHandle? = FileHandle(forReadingAtPath: settingsURL.path)
		if let file = fileHandle {
			print("Setting up preset values now...")
			// initialize settings values
			let data: Data = file.readDataToEndOfFile()
			var dataString: String? = String.init(data: data, encoding: .utf8)
			if dataString != nil {
				if dataString!.count == 2 {
					let durationButton: Character = dataString!.removeFirst()
					switch durationButton{
					case "l":
						//same as default
						loadDefaultDurationAndButton()
					case "m":
						Settings.currentButtonSelected = "middle"
						Settings.recordingDuration = Settings.Duration.middleButton.rawValue
					case "r":
						Settings.currentButtonSelected = "right"
						Settings.recordingDuration = Settings.Duration.rightButton.rawValue
					default:
						print("Error data fround in highlightSettings.txt file")
						print("Loading default duration:")
						loadDefaultDurationAndButton()
					}
					let backgroundChar: Character = dataString!.removeFirst()
					let recordInBackground: Bool = (backgroundChar == "1") ? true : false
					if recordInBackground {
						Settings.continueRecordingInBackground = true
					} else {
						Settings.continueRecordingInBackground = false
					}
				}
			}
			
			file.closeFile()
		} else {
			print("Couldn't read highlightsettings.txt. Setting up Defaults...")
			// couldn't read from file --> load defaults
			Settings.continueRecordingInBackground = true
			loadDefaultDurationAndButton()
		}
	}
	
	func loadDefaultDurationAndButton() {
		Settings.recordingDuration = Settings.Duration.leftButton.rawValue
		Settings.currentButtonSelected = "left"
	}
	
	func saveSettings(){
		var dataString: String = ""
		let char = Settings.currentButtonSelected.first
		dataString.append(char!)
		let boolNum = Settings.continueRecordingInBackground ? "1" : "0"
		dataString += boolNum
		
		// create file
		let filemgr = FileManager.default
		
		// write dataString to settingFile
		if let data = dataString.data(using: .utf8) {
			let success = filemgr.createFile(atPath: settingsURL.path, contents: data, attributes: nil)
			if !success {
				print("Error: File write unsuccessful.")
			} else {
				print("Saving Settings data was successful.")
			}
		} else {
			print("Error: Could not encode dataString to UTF-8 data.")
		}
	}
	
	// MARK: - Core Data Saving support
//	func saveContext () { // DONT NEED HERE (Context is saved inside Audio.swift)
//		let context = persistentContainer.viewContext
//		if context.hasChanges {
//			do {
//				try context.save()
//			} catch {
//				// Replace this implementation with code to handle the error appropriately.
//				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//				let nserror = error as NSError
//				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//			}
//		}
//	}
	
}

// MARK: - GIDSignInDelegate
//extension ViewController: GIDSignInDelegate {
//	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//		if let _ = error {
//			service.authorizer = nil
//		} else {
//			service.authorizer = user.authentication.fetcherAuthorizer()
//		}
//	}
//}


