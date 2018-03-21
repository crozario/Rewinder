//
//  FloatingActionButton.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/19/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import UIKit

class FloatingActionButton:RoundButton {
    
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        alphaBefore = alpha
        
        UIView.animate(withDuration: 0.3, animations: {
            if self.transform == .identity {
                self.transform = CGAffineTransform(rotationAngle: (.pi / 4) )
            } else {
                self.transform = .identity
            }
        })
        return super.beginTracking(touch, with: event)

    }
}
