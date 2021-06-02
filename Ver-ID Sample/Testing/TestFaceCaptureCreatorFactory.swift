//
//  TestFaceCaptureCreatorFactory.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 15/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

enum SessionError: Error {
    case sessionFailed
}

class TestFaceCaptureCreatorFactory: FaceCaptureCreatorFactory {
    
    var sessionResult: VerIDSessionResult = VerIDSessionResult(faceCaptures: [])
    let settings: VerIDSessionSettings
    var attachments: [FaceCapture] = []
    
    init(settings: VerIDSessionSettings) {
        self.settings = settings
    }
    
    func makeFaceCaptureCreator() -> (FaceDetectionResult) throws -> FaceCapture {
        { faceDetectionResult in
            if Globals.shouldFailAuthentication && self.settings is AuthenticationSessionSettings {
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
