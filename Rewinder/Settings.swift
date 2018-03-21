//
//  Settings.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/16/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import Foundation


class Settings {
    static var recordingDuration = Duration.leftButton.rawValue
    static var continueRecordingInBackground = false
    static var currentButtonSelected = "left"
    
    
//    static var d = {}
    
    enum Duration: Double {
        case leftButton = 15.0
        case middleButton = 30.0
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

