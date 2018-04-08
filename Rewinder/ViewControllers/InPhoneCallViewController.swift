//
//  InPhoneCallViewController.swift
//  Rewinder
//
//  Created by Haard Shah on 4/8/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class InPhoneCallViewController: UIViewController {

	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var doneButton: UIButton!
	override func viewDidLoad() {
        super.viewDidLoad()

        contentView.backgroundColor = Settings.appThemeColor
		contentView.layer.cornerRadius = 10
		contentView.layer.masksToBounds = true
		doneButton.backgroundColor = Settings.selectedColor
    }

	@IBAction func donePressed(_ sender: Any) {
		self.dismiss(animated: true) {
			let appDelegate = UIApplication.shared.delegate as! AppDelegate
			appDelegate.applicationDidBecomeActive(UIApplication.shared)
		}
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
