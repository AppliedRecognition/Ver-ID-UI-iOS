//
//  TestFaceDetectionService.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 15/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

class TestFaceDetectionService: FaceDetectionService {
    
    init(settings: VerIDSessionSettings) {
        self.angleBearingEvaluation = AngleBearingEvaluation(sessionSettings: settings, pitchThresholdTolerance: 5, yawThresholdTolerance: 5)
        self.facePresenceDetection = FacePresenceDetection(maxMissingFaceCount: 2, angleBearingEvaluation: self.angleBearingEvaluation)
        self.faceAlignmentDetection = FaceAlignmentDetection(angleBearingEvaluation: self.angleBearingEvaluation)
    }
    
    func detectFaceInImage(_ image: VerIDImage) -> FaceDetectionResult {
        guard let size = image.size else {
            return FaceDetectionResult(imageSize: .zero, face: nil, faceBounds: nil, faceAngle: nil, status: .failed, requestedBearing: self.requestedBearing, imageProcessorName: nil)
        }
        return FaceDetectionResult(imageSize: size, face: Face(), faceBounds: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1), faceAngle: self.angleBearingEvaluation.angle(forBearing: self.requestedBearing), status: .faceAligned, requestedBearing: self.requestedBearing, imageProcessorName: nil)
    }
    
    var requestedBearing: Bearing = .straight
    
    var angleBearingEvaluation: AngleBearingEvaluation
    
    var facePresenceDetection: FacePresenceDetection
    
    var faceAlignmentDetection: FaceAlignmentDetection
    
    var spoofingDetection: SpoofingDetection?
    
    var imageProcessors: [ImageProcessorService] = []
    
    
}

class TestFaceDetectionServiceFactory: FaceDetectionServiceFactory {
    
    func makeFaceDetectionService(settings: VerIDSessionSettings) throws -> FaceDetectionService {
        TestFaceDetectionService(settings: settings)
    }
}
