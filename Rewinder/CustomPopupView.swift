//
//  CustomPopupView.swift
//  Rewinder
//
//  Created by Haard Shah on 3/28/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class CustomPopupView: UIView {

	@IBOutlet var contentView: UIView!
	//	@IBOutlet var popupContentView: UIView!
	@IBOutlet weak var testLabel: UILabel!
	
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
		contentView = loadViewFromNib()
		addSubview(contentView)
		
	}
	
	func loadViewFromNib() -> UIView! {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
		let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
		
		return view
	}
}
