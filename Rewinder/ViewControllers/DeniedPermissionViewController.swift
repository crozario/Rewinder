//
//  DeniedPermissionViewController.swift
//  Rewinder
//
//  Created by Haard Shah on 3/29/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit
import AVFoundation

class DeniedPermissionViewController: UIViewController {

	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var settingButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		contentView.backgroundColor = Settings.appThemeColor
		contentView.layer.cornerRadius = 10
		contentView.layer.masksToBounds = true
		settingButton.backgroundColor = Settings.selectedColor
        // Do any additional setup after loading the view.
    }
	
	override func viewDidAppear(_ animated: Bool) {
		print("\(#function)")
		// check permissions
		checkPermissions()
	}
	
	func checkPermissions() {
		let session = AVAudioSession.sharedInstance()
		switch session.recordPermission {
		case .granted:
			print("Have permission to record")
//			self.dismiss(animated: true, completion: nil)
		case .denied:
			print("Denied permission")
		case .undetermined:
			print("Undetermined")
		}
	}
	
	@IBAction func tappedSettings(_ sender: Any) {
		guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
			return
		}
		
//		if UIApplication.shared.canOpenURL(settingsUrl) {
//			UIApplication.shared.open(settingsUrl, completionHandler: convertToUIApplicationOpenExternalURLOptionsKeyDictionary({ (success) in
//				// Checking for setting is opened or not
//				print("Setting is opened: \(success)")
//			}))
//		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
