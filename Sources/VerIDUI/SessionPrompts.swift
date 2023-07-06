//
//  SessionPrompts.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 31/07/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

class SessionPrompts {
    
    let translatedStrings: TranslatedStrings
    
    init(translatedStrings: TranslatedStrings) {
        self.translatedStrings = translatedStrings
    }
    
    func promptForFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult) -> String? {
        switch faceDetectionResult.status {
        case .faceFixed, .faceAligned:
            return self.translatedStrings["Great, hold it"]
        case .faceMisaligned:
            return self.translatedStrings["Slowly turn to follow the arrow"]
        case .faceTurnedTooFar:
            return nil
        default:
            return self.translatedStrings["Align your face with the oval"]
        }
    }
}
