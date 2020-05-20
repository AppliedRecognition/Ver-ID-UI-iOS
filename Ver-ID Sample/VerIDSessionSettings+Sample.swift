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
        speakPrompts = userDefaults.speakPrompts
        useFrontCamera = !userDefaults.useBackCamera
        numberOfResultsToCollect = userDefaults.registrationFaceCount
        faceBoundsFraction = CGSize(width: CGFloat(userDefaults.faceWidthFraction), height: CGFloat(userDefaults.faceHeightFraction))
    }
}

extension AuthenticationSessionSettings {
    
    convenience init(userId: String, userDefaults: UserDefaults) {
        self.init(userId: userId)
        yawThreshold = CGFloat(userDefaults.yawThreshold)
        pitchThreshold = CGFloat(userDefaults.pitchThreshold)
        speakPrompts = userDefaults.speakPrompts
        useFrontCamera = !userDefaults.useBackCamera
        numberOfResultsToCollect = userDefaults.poseCount
        faceBoundsFraction = CGSize(width: CGFloat(userDefaults.faceWidthFraction), height: CGFloat(userDefaults.faceHeightFraction))
    }
}
