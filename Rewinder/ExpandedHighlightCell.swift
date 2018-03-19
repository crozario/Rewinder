//
//  ExpandedHighlightCell.swift
//  Rewinder
//
//  Created by Haard Shah on 3/19/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

protocol ExpandedHighlightCellDelegate {
	func didTapExport(title: String)
	func didTapLike(title: String, cell: ExpandedHighlightCell)
	func didTapDelete(title: String)
	func didTapPlayback(title: String, cell: ExpandedHighlightCell)
}

class ExpandedHighlightCell: UITableViewCell {

//	@IBOutlet weak var durationLabel: UILabel!
//	@IBOutlet weak var playbackButton: UIButton!
//	@IBOutlet weak var titleLabel: UILabel!
//	@IBOutlet weak var waveformView: UIView!
//	
//	var delegate: ExpandedHighlightCellDelegate?
//	
//	@IBAction func exportTapped(_ sender: Any) {
//		delegate?.didTapExport(title: titleLabel.text!)
//	}
//	
//	@IBAction func likeTapped(_ sender: Any) {
//		delegate?.didTapLike(title: titleLabel.text!, cell: self)
//	}
//	
//	@IBAction func deleteTapped(_ sender: Any) {
//		delegate?.didTapDelete(title: titleLabel.text!)
//	}
//	
//	@IBAction func playbackTapped(_ sender: Any) {
//		delegate?.didTapPlayback(title: titleLabel.text!, cell: self)
//	}
//	
//	func setTitle(_ title: String) {
//		titleLabel.text = title
//	}
//	
//	//duration range 0:00-2:00
//	func setDuration(_ duration: Double) {
//		
//		let timeint: TimeInterval = TimeInterval(exactly: duration)!
//		let formatter = DateComponentsFormatter()
//		formatter.unitsStyle = .short
//		formatter.allowedUnits = [.minute, .second]
//		formatter.zeroFormattingBehavior = [.dropAll]
//		let formattedDuration = formatter.string(from: timeint)
//		
//		durationLabel.text = formattedDuration
//	}
//	
//	func setButtonStop() { // playing
//		playbackButton.setTitle("Pause", for: .normal)
//	}
//	func setButtonPlay() { // not playing
//		playbackButton.setTitle("Play", for: .normal)
//	}
//	
//	func getTitle() -> String{
//		return titleLabel.text!
//	}
}
