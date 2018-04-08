//
//  MultipleEditsView.swift
//  Rewinder
//
//  Created by Haard Shah on 4/7/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

protocol MultipleEditsViewDelegate {
	func deletePressed()
	func editPressed()
	func exportPressed()
}

class MultipleEditsView: UIView {

	@IBOutlet var contentView: UIView!
	@IBOutlet weak var exportButton: UIButton!
	@IBOutlet weak var editButton: UIButton!
	@IBOutlet weak var deleteButton: UIButton!
	
	var delegate: MultipleEditsViewDelegate?
	
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
		exportButton.setTitleColor(.white, for: .normal)
		editButton.setTitleColor(.white, for: .normal)
		deleteButton.setTitleColor(.white, for: .normal)
	}
	
	@IBAction func deleteButtonTapped(_ sender: Any) {
		delegate?.deletePressed()
	}
	
	@IBAction func exportButtonTapped(_ sender: Any) {
		delegate?.exportPressed()
	}
	
	@IBAction func editButtonTapped(_ sender: Any) {
		delegate?.editPressed()
	}
	
	func disableEditButton() {
		editButton.isEnabled = false
		editButton.setTitleColor(.lightGray, for: .normal)
	}
	func enableEditButton() {
		editButton.isEnabled = true
		editButton.setTitleColor(.white, for: .normal)
	}
	func disableDeleteAndExportButton() {
		deleteButton.isEnabled = false
		deleteButton.setTitleColor(.lightGray, for: .normal)
		exportButton.isEnabled = false
		exportButton.setTitleColor(.lightGray, for: .normal)
	}
	func enableDeleteAndExportButton() {
		deleteButton.isEnabled = true
		deleteButton.setTitleColor(.white, for: .normal)
		exportButton.isEnabled = true
		exportButton.setTitleColor(.white, for: .normal)
	}
	
	func loadViewFromNib() -> UIView! {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
		let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
		
		return view
	}
}
