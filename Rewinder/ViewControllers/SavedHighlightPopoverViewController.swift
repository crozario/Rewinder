//
//  SavedHighlightPopoverViewController.swift
//  Rewinder
//
//  Created by Haard Shah on 3/28/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class SavedHighlightPopoverViewController: UIViewController {

	@IBOutlet weak var popupView: UIView!
	override func viewDidLoad() {
        super.viewDidLoad()

		popupView.layer.cornerRadius = 10
		popupView.layer.masksToBounds = true
    }
	
	override func viewDidAppear(_ animated: Bool) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
			self.dismiss(animated: true, completion: nil)
		})
	}

}
