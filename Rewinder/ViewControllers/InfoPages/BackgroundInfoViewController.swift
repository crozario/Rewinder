//
//  BackgroundInfoViewController.swift
//  Rewinder
//
//  Created by Haard Shah on 4/14/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class BackgroundInfoViewController: UIViewController {

	var delegate: BackgroundInfoPageDelegate?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	@IBAction func nextTapped(_ sender: Any) {
		delegate?.nextTapped(currentViewController: self)
	}
	
	@IBAction func skipTapped(_ sender: Any) {
		// go to last page
		delegate?.skipTapped(currentViewController: self)
	}
}

protocol BackgroundInfoPageDelegate {
	func nextTapped(currentViewController: BackgroundInfoViewController)
	func skipTapped(currentViewController: BackgroundInfoViewController)
}
