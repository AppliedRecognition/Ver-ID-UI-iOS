//
//  VerIDSessionSettings+Sample.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 06/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

extension RegistrationSessionSettings {
    
    convenience init(userId: String, userDefaults: UserDefaults) {
        self.init(userId: userId)
        yawThreshold = CGFloat(userDefaults.yawThreshold)
        pitchThreshold = CGFloat(userDefaults.pitchThreshold)
        faceCaptureCount = userDefaults.registrationFaceCount
        bearingsToRegister = faceCaptureCount == 1 ? [.straight] : [.straight,.left,.right]
        expectedFaceExtents = FaceExtents(proportionOfViewWidth: CGFloat(userDefaults.faceWidthFraction), proportionOfViewHeight: CGFloat(userDefaults.faceHeightFraction))
        isFaceCoveringDetectionEnabled = userDefaults.enableFaceCoveringDetection
        isSunglassesDetectionEnabled = userDefaults.enableSunglassesDetection
    }
}

extension AuthenticationSessionSettings {
    
    convenience init(userId: String, userDefaults: UserDefaults) {
        self.init(userId: userId)
        yawThreshold = CGFloat(userDefaults.yawThreshold)
        pitchThreshold = CGFloat(userDefaults.pitchThreshold)
        faceCaptureCount = userDefaults.poseCount
        bearings = Set(userDefaults.poses)
        expectedFaceExtents = FaceExtents(proportionOfViewWidth: CGFloat(userDefaults.faceWidthFraction), proportionOfViewHeight: CGFloat(userDefaults.faceHeightFraction))
        isFaceCoveringDetectionEnabled = userDefaults.enableFaceCoveringDetection
        isSunglassesDetectionEnabled = userDefaults.enableSunglassesDetection
    }
}
