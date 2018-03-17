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

