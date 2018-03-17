//
//  SettingsViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
//    @IBOutlet weak var dismissSettingPageButton: RoundButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColorFromRGB(rgbValue: 0x0278AE)
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
//        UINavigationBar.appearance().barTintColor = .blue
        
    }

//    @IBAction func dismissHighlightVC(_ sender: RoundButton) {
//        self.dismiss(animated: true, completion: nil)
//    }
//    
//    @IBAction func backButton(_ sender: UIButton) {
//        performSegue(withIdentifier: "homeSegue", sender: self)
//    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell =  tableView.dequeueReusableCell(withIdentifier: "ContinueCell", for: indexPath) as! ContinueTableViewCell
            return cell
        } else {
            let cell =  tableView.dequeueReusableCell(withIdentifier: "CustomizeLengthCell", for: indexPath) as! CustomLengthTableViewCell
            return cell
        }
        
        
    }

}

