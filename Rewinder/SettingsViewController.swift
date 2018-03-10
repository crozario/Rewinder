//
//  SettingsViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var highlightLength: UILabel!
    
    @IBAction func durationSlider(_ sender: UISlider) {
        recordDuration = Double(sender.value)
        highlightLength.text = "\(Int(recordDuration)) secs"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        
        
//        UINavigationBar.appearance().barTintColor = .blue
        
    }

}

