//
//  SettingsViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBAction func durationSlider(_ sender: UISlider) {
        recordDuration = Double(sender.value)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
