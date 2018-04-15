//
//  RecordInfoViewController.swift
//  Rewinder
//
//  Created by Haard Shah on 4/14/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class RecordInfoViewController: UIViewController {

	var delegate: RecordInfoPageDelegate?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	@IBAction func nextTapped(_ sender: Any) {
		delegate?.nextTapped(currentViewController: self)
	}
	
	@IBAction func skipTapped(_ sender: Any) {
		// go to last page (hasn't been added yet)
		delegate?.skipTapped(currentViewController: self)
	}
}

protocol RecordInfoPageDelegate {
	func nextTapped(currentViewController: RecordInfoViewController)
	func skipTapped(currentViewController: RecordInfoViewController)
}
