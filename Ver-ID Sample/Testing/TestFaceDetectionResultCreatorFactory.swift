//
//  TestFaceDetectionResultCreatorFactory.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 15/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia
import VerIDCore

class TestFaceDetectionResultCreatorFactory: FaceDetectionResultCreatorFactory {
    
    func makeFaceDetectionResultCreator() -> (VerIDImage, FaceBounds) throws -> FaceDetectionResult {
        { image, faceBounds in
            let result = FaceDetectionResult(image: image, requestedBearing: self.requestedBearing, defaultFaceBounds: faceBounds)
            result.face = Face()
            guard let imageSize = image.size else {
                throw VerIDError.undefinedImageSize
            }
            let faceWidth = min(imageSize.width, imageSize.height) / 2
            let faceHeight = faceWidth * 1.25
            result.faceBounds = CGRect(x: imageSize.width / 2 - faceWidth / 2, y: imageSize.height / 2 - faceHeight / 2, width: faceWidth, height: faceHeight)
            result.face?.bounds = result.faceBounds
            result.faceAngle = self.angleBearingEvaluation.angle(forBearing: self.requestedBearing)
            result.status = .faceAligned
            return result
        }
    }
    
    
    init(settings: VerIDSessionSettings) {
        self.angleBearingEvaluation = AngleBearingEvaluation(sessionSettings: settings, pitchThresholdTolerance: 5, yawThresholdTolerance: 5)
    }
    
    var requestedBearing: Bearing = .straight
    
    var angleBearingEvaluation: AngleBearingEvaluation
    
    
}
