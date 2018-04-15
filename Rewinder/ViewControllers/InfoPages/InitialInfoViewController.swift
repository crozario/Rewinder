//
//  InitialInfoViewController.swift
//  Rewinder
//
//  Created by Haard Shah on 4/14/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class InitialInfoViewController: UIViewController {

	var delegate: InitialInfoPageDelegate?
	
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

protocol InitialInfoPageDelegate {
	func nextTapped(currentViewController: InitialInfoViewController)
	func skipTapped(currentViewController: InitialInfoViewController)
}
