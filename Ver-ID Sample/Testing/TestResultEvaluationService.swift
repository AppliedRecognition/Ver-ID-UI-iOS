//
//  TestResultEvaluationService.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 15/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

enum SessionError: Error {
    case sessionFailed
}

class TestResultEvaluationService: ResultEvaluationService {
    
    var sessionResult: VerIDSessionResult = VerIDSessionResult(attachments: [])
    let settings: VerIDSessionSettings
    var attachments: [DetectedFace] = []
    
    init(settings: VerIDSessionSettings) {
        self.settings = settings
    }
    
    func addResult(_ result: FaceDetectionResult, image: VerIDImage, imageURL: URL?) -> ResultEvaluationStatus {
        if Globals.shouldFailAuthentication && self.settings is AuthenticationSessionSettings {
            self.sessionResult = VerIDSessionResult(error: SessionError.sessionFailed)
            return .finished
        }
        if result.status == .faceAligned, let face = result.face {
            self.attachments.append(DetectedFace(face: face, bearing: result.requestedBearing, imageURL: imageURL))
        }
        if self.attachments.count == self.settings.numberOfResultsToCollect {
            self.sessionResult = VerIDSessionResult(attachments: self.attachments)
            return .finished
        } else {
            return .waiting
        }
    }
}

class TestResultEvaluationServiceFactory: ResultEvaluationServiceFactory {
    
    func makeResultEvaluationService(settings: VerIDSessionSettings) -> ResultEvaluationService {
        TestResultEvaluationService(settings: settings)
    }
}
