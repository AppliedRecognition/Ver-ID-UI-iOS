//
//  TestSessionFunctions.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 11/08/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

class TestSessionFunctions: SessionFunctions {
    
    override var sessionFaceTrackingAccumulator: (inout SessionFaceTracking, (image: VerIDImage, defaultFaceBounds: FaceBounds)) throws -> Void {
        { faceTracking, capture in
            faceTracking.image = capture.image
            faceTracking.defaultFaceBounds = capture.defaultFaceBounds
            guard let imageSize = capture.image.size else {
                throw VerIDError.undefinedImageSize
            }
            let face = Face()
            let faceWidth = min(imageSize.width, imageSize.height) / 2
            let faceHeight = faceWidth * 1.25
            face.bounds = CGRect(x: imageSize.width / 2 - faceWidth / 2, y: imageSize.height / 2 - faceHeight / 2, width: faceWidth, height: faceHeight)
            face.angle = faceTracking.angleBearingEvaluation.angle(forBearing: faceTracking.requestedBearing)
            faceTracking.face = face
        }
    }
    
    override var facePresenceDetectionAccumulator: (inout FacePresenceDetection, SessionFaceTracking) throws -> Void {
        { facePresence, faceTracking in
            facePresence.sessionFaceTracking = faceTracking
            facePresence.status = .found
        }
    }
    
    override var faceAlignmentDetectionAccumulator: (inout FaceAlignmentDetection, FacePresenceDetection) throws -> Void {
        { faceAlignment, facePresence in
            faceAlignment.facePresence = facePresence
            faceAlignment.status = .aligned
        }
    }
    
    override var spoofingDetectionAccumulator: (inout SpoofingDetection, FaceAlignmentDetection) throws -> Void {
        { spoofingDetection, faceAlignmentDetection in
            spoofingDetection.faceAlignment = faceAlignmentDetection
        }
    }
    
    override var faceDetectionResultCreator: (SpoofingDetection) throws -> FaceDetectionResult {
        { spoofingDetection in
            guard let faceTracking = spoofingDetection.faceAlignment?.facePresence?.sessionFaceTracking else {
                preconditionFailure("spoofingDetection.faceAlignment?.facePresence?.sessionFaceTracking is nil")
            }
            guard let image = faceTracking.image else {
                preconditionFailure("faceTracking.image is nil")
            }
            guard let bounds = faceTracking.defaultFaceBounds else {
                preconditionFailure("faceTracking.defaultFaceBounds is nil")
            }
            let result = FaceDetectionResult(image: image, requestedBearing: faceTracking.requestedBearing, defaultFaceBounds: bounds)
            result.status = .faceAligned
            result.face = faceTracking.face
            return result
        }
    }
    
    override var faceCaptureCreator: (FaceDetectionResult) throws -> FaceCapture {
        { faceDetectionResult in
            if Globals.shouldFailAuthentication && self.sessionSettings is AuthenticationSessionSettings {
                throw NSError(domain: kVerIDErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey:"Test failure"])
            }
            guard faceDetectionResult.status == .faceAligned, let face = faceDetectionResult.face else {
                throw VerIDError.unexpectedFaceDetectionResultStatus
            }
            guard let imageSize = faceDetectionResult.image.size else {
                throw VerIDError.undefinedImageSize
            }
            let recognizableFace = RecognizableFace(face: face, recognitionData: Data())
            UIGraphicsBeginImageContext(imageSize)
            defer {
                UIGraphicsEndImageContext()
            }
            if let context = UIGraphicsGetCurrentContext() {
                let shapeLayer = CAShapeLayer()
                shapeLayer.fillColor = UIColor.gray.cgColor
                shapeLayer.bounds = CGRect(origin: .zero, size: imageSize)
                shapeLayer.draw(in: context)
            }
            guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
                throw VerIDError.imageCreationFailure
            }
            return FaceCapture(face: recognizableFace, bearing: faceDetectionResult.requestedBearing, image: image)
        }
    }
}
