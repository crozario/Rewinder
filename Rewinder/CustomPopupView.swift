//
//  CustomPopupView.swift
//  Rewinder
//
//  Created by Haard Shah on 3/28/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class CustomPopupView: UIView {

	
//	@IBOutlet var popupContentView: UIView!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	func commonInit() {
//		popupContentView = Bundle.main.loadNibNamed("CustomPopupView", owner: self, options: nil)?.first as? UIView
//		addSubview(popupContentView)
//		popupContentView.frame = self.bounds
//		popupContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	}

}
