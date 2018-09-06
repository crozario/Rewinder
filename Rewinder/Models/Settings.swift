//
//  Settings.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/16/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import Foundation
import UIKit

class Settings {
    static var recordingDuration = Duration.leftButton.rawValue
    static var continueRecordingInBackground = false
    static var currentButtonSelected = "left"
	
	static let selectedColor: UIColor = UIColorFromRGB(rgbValue: 0xFF467E)
	static let disabledColor: UIColor = UIColorFromRGB(rgbValue: 0xA0467E)
	static let unSelectedColor: UIColor = UIColorFromRGB(rgbValue: 0x35C2BD)
	static let appThemeColor: UIColor = UIColorFromRGB(rgbValue: 0x0278AE)

    
//    static var d = {}
    
    enum Duration: Double {
        case leftButton = 30.0
        case middleButton = 60.0
        case rightButton = 90.0
    }
    
    static func getRecordingDuration() -> Double {
        return recordingDuration
    }
    
    static func setRecordingDuration(duration: Double) {
        recordingDuration = duration
    }

}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}


func UIColorFromRGB(rgbValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

//enum HighlightDuration {
//    
//}

