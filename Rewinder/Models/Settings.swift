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


//enum HighlightDuration {
//    
//}

