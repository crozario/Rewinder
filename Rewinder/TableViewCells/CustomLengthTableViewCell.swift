//
//  CustomLengthTableViewCell.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/17/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class CustomLengthTableViewCell: UITableViewCell {

    @IBOutlet weak var customLengthText: UILabel!
    
    @IBOutlet weak var customLengthSetter: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
