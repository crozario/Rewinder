//
//  ContinueTableViewCell.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/17/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class ContinueTableViewCell: UITableViewCell {
    
    @IBOutlet weak var continueText: UILabel!
    
    @IBOutlet weak var continueSwitch: UISwitch!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
