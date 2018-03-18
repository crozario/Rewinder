//
//  Settings.swift
//  Rewinder
//
//  Created by Crossley Rozario on 3/16/18.
//  Copyright © 2018 Crossley Rozario. All rights reserved.
//

import Foundation


class Settings {
    static var recordingDuration = 30.0
    static var continueRecording = false
    static var customDuration = 120.0
    
    enum Duration: Double {
        case leftButton = 30.0
        case topButton = 60.0
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

