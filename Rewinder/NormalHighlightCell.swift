//
//  NormalHighlightCell.swift
//  Rewinder
//
//  Created by Haard Shah on 3/16/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

protocol HighlightCellDelegate {
	func didTapPlayback(title: String, cell: NormalHighlightCell)
}

class NormalHighlightCell: UITableViewCell {

	@IBOutlet weak var playbackButton: UIButton!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	
	var delegate: HighlightCellDelegate?
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	@IBAction func playbackTapped(_ sender: Any) {
//		setButtonStop()
		delegate?.didTapPlayback(title: titleLabel.text!, cell: self)
	}
	
	func setTitle(_ title: String) {
		titleLabel.text = title
	}
	
	//duration range 0:00-2:00
	func setDuration(_ duration: Double) {

		let timeint: TimeInterval = TimeInterval(exactly: duration)!
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .short
		formatter.allowedUnits = [.minute, .second]
		formatter.zeroFormattingBehavior = [.dropAll]
		let formattedDuration = formatter.string(from: timeint)

		durationLabel.text = formattedDuration
	}
	func setButtonStop() { // playing
		playbackButton.setTitle("Pause", for: .normal)
	}
	func setButtonPlay() { // not playing
		playbackButton.setTitle("Play", for: .normal)
	}
	func getTitle() -> String{
		return titleLabel.text!
	}
}
