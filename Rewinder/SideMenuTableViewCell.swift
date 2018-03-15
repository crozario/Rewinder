//
//  SideMenuTableViewCell.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/14/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class SideMenuTableViewCell: UITableViewCell {

    @IBOutlet weak var viewcontrollerImage: UIImageView!
    
    
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
