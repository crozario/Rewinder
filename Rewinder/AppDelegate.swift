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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
	var audioPlayer: myPlayer?
	var audioRecorder: myRecorder?
	var audioSession: AVAudioSession?
	var home: HomeViewController?
	
//	let settingFile: String = "highlightsettings.txt"
	var settingsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("highlightsettings.txt")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
		
		self.initializeSettings()
		
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
		print("\(#function)")

    }

	var continuePlaying: Bool = false
    func applicationDidEnterBackground(_ application: UIApplication) {
		print("\(#function)")

		if !Settings.continueRecordingInBackground {
			// stop recording and playing
			audioRecorder?.stop()
			audioPlayer?.stop()
			
			// stop session
			audioSession = AVAudioSession.sharedInstance()
			do {
				try audioSession?.setActive(false)
			} catch let error {
				print(error.localizedDescription)
			}
		}

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
		print("\(#function)")
		
		if !Settings.continueRecordingInBackground {
			// start audio session
			audioSession = AVAudioSession.sharedInstance()
			do {
				try audioSession?.setActive(true)
			} catch let error {
				print(error.localizedDescription)
			}
			
			// begin recording
			home?.firstBeginRecording()
		}
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
		print("\(#function)")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
		let fileHandle: FileHandle? = FileHandle(forReadingAtPath: settingsURL.path)
		if let file = fileHandle {
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

