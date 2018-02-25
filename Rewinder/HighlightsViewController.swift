//
//  HighlightsViewController.swift
//  Rewinder
//
//  Created by Crossley Rozario on 2/25/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import Foundation

import UIKit



class HighlightsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var arr = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arr = ["Crossley", "NJIT", "Haard", "Database", "Computer Networks", "Hackathon", "iOS App", "MacBook"]
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = "HighlightCell"
        let cell =  tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
        
        cell.textLabel?.text = arr[indexPath.row]
        
        return cell
    }
    
}


