//
//  HighlightPlayerView.swift
//  Rewinder
//
//  Created by Haard Shah on 3/28/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

protocol HighlightPlayerDelegate {
	func pressedPlayButton();
	func pressedPauseButton();
	func swipeDetected();
}

class HighlightPlayerView: UIView {

	@IBOutlet var contentView: UIView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var playbackButton: UIButton!
	
	var delegate: HighlightPlayerDelegate?
	
	var indexPath: IndexPath?
	
	var playingHighlight: Bool = false
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	@IBOutlet var swipeGesture: UISwipeGestureRecognizer!
	
	@IBAction func swipeDetected(_ sender: UISwipeGestureRecognizer) {
		print("Swipe detected")
		delegate?.swipeDetected()
	}

	func commonInit() {
		contentView = loadViewFromNib()
		addSubview(contentView)
		contentView.addGestureRecognizer(swipeGesture)
		titleLabel.text = "Not Playing"
	}
	
	var title: String {
		get {
			return titleLabel.text!
		}
		set {
			titleLabel.text = newValue
		}
	}
	
	// should display the play image on the button
	func setPaused() {
//		playbackButton.setImage(#imageLiteral(resourceName: "playicon.png"), for: .normal)
		playbackButton.setTitle("Play", for: .normal)
		playingHighlight = false
	}
	
	// should display the pause image on the button
	func setPlaying() {
//		playbackButton.setImage(#imageLiteral(resourceName: "pauseicon"), for: .normal)
		playbackButton.setTitle("Pause", for: .normal)
		playingHighlight = true
	}
	
	
	
	
	@IBAction func didPressPlayback(_ sender: Any) {
		if playingHighlight { // meaning the pause button was visible
			delegate?.pressedPauseButton()
		}
		else { // the play button was visible
			delegate?.pressedPlayButton()
		}
	}
	
	func loadViewFromNib() -> UIView! {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
		let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
		
		return view
	}
}
