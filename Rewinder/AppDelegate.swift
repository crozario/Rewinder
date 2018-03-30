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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
	var audioPlayer: myPlayer?
	var audioRecorder: myRecorder?
	var audioSession: AVAudioSession?
	var home: HomeViewController?
	
	var havePermission: Bool = false
	var undeterminedPermission: Bool = false
	
//	let settingFile: String = "highlightsettings.txt"
	var settingsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("highlightsettings.txt")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
		
		checkPermissions()
		self.initializeSettings()
		
		application.statusBarStyle = .lightContent
		
        return true
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

    func applicationWillResignActive(_ application: UIApplication) {
		print("\(#function)")

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
		print("\(#function)")
	
		// stop AudioKit
//		do {
//			try AudioKit.stop()
//		} catch let error {
//			print("AudioKit stop error: \(error.localizedDescription)")
//		}
		
		if !Settings.continueRecordingInBackground {
			home?.continueRecording = false
			
			// stop recording and playing
			audioRecorder?.stop()
			audioPlayer?.stop()
			
			// stop AudioKit
			stopAudioKit()
			
			// stop session
			deactivateAudioSession()
		} else {
			// stop AudioKit
//			stopAudioKit() // can't stop audiokit because for some reason it stops the audiosession too
		}
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

	var firstTime: Bool = true
	func applicationDidBecomeActive(_ application: UIApplication) {
		print("\(#function)")

		checkPermissions()
		
		guard home != nil else {
			print("ERROR: home reference inside AppDelegate never set")
			return
		}
		
		if havePermission {
			executeFirstTime()
		}
		else {
			if !undeterminedPermission {
				DispatchQueue.main.async {
					self.home!.performSegue(withIdentifier: "idDeniedPermissionSegue", sender: self.home!)
				}
			}
		}
	}
	
	private func executeFirstTime() { //assumes home is not nil
		if firstTime {
			home!.initializeAKMicrphone() // initialize microphone
			home!.initializeRollingPlot()
			configureAudioSession()
			// start audiokit
			startAudioKit()
			//				home!.startAudioKit(true)
			// start recording
			home!.firstBeginRecording() // FIXME: Will cause wierd behavior when scroll view is removed because then the viewDidAppear will be triggered more often
			firstTime = false
		}
	}
	
	func requestPermissionToMicrophone() {
		print("\(#function)")
		let session = AVAudioSession.sharedInstance()
		if session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:))) {
			session.requestRecordPermission({ (granted: Bool) in
				if granted {
					print("User granted Permission.")
					self.executeFirstTime()
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
			//			try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
			try session.overrideOutputAudioPort(.speaker)
			try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.mixWithOthers /*, .defaultToSpeaker*/])
			try session.setActive(true, with: .notifyOthersOnDeactivation)
		} catch let error {
			print("Error setting up audiosession: \(error.localizedDescription)")
		}
	}
	
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

    func applicationWillTerminate(_ application: UIApplication) {
		print("\(#function)")
		
        self.saveContext()
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
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

