//
//  UndeterminedPermissionViewController.swift
//  Rewinder
//
//  Created by Haard Shah on 3/30/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class UndeterminedPermissionViewController: UIViewController {

	@IBOutlet weak var contentView: UIView!
	
	@IBOutlet weak var enableButton: UIButton!
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		contentView.backgroundColor = Settings.appThemeColor
		contentView.layer.cornerRadius = 10
		contentView.layer.masksToBounds = true
		enableButton.backgroundColor = Settings.selectedColor
        // Do any additional setup after loading the view.
    }
	
	@IBAction func tappedEnable(_ sender: Any) {
		//FIXME: This is dirty and maybe pass homeviewcontroller object using preparefor segue
		self.dismiss(animated: true) {
			let appDelegate = UIApplication.shared.delegate as! AppDelegate
//			appDelegate.firstTime = false
			appDelegate.requestPermissionToMicrophone()
		}
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
