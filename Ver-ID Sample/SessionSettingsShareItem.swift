//
//  SessionSettingsShareItem.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 05/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

struct SessionSettingsShareItem<T: VerIDSessionSettings>: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case type, expiryTime, numberOfResultsToCollect, useBackCamera, maxRetryCount, speakPrompts, yawThreshold, pitchThreshold, faceWidthFraction, faceHeightFraction, pauseDuration, faceBufferSize, bearings, extractFaceTemplates
    }
    
    let settings: T
    
    init(settings: T) {
        self.settings = settings
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let authSettings = settings as? AuthenticationSessionSettings {
            try container.encode("authentication", forKey: .type)
            try container.encode(authSettings.bearings, forKey: .bearings)
        } else if let regSettings = settings as? RegistrationSessionSettings {
            try container.encode("registration", forKey: .type)
            try container.encode(regSettings.bearingsToRegister, forKey: .bearings)
        } else if let livenessSettings = settings as? LivenessDetectionSessionSettings {
            try container.encode("liveness detection", forKey: .type)
            try container.encode(livenessSettings.bearings, forKey: .bearings)
        }
        try container.encode(settings.maxDuration, forKey: .expiryTime)
        try container.encode(settings.faceCaptureCount, forKey: .numberOfResultsToCollect)
//        try container.encode(!settings.useFrontCamera, forKey: .useBackCamera)
        try container.encode(settings.maxRetryCount, forKey: .maxRetryCount)
        try container.encode(settings.yawThreshold, forKey: .yawThreshold)
        try container.encode(settings.pitchThreshold, forKey: .pitchThreshold)
        //try container.encode(settings.speakPrompts, forKey: .speakPrompts)
        try container.encode(settings.expectedFaceExtents.proportionOfViewWidth, forKey: .faceWidthFraction)
        try container.encode(settings.expectedFaceExtents.proportionOfViewHeight, forKey: .faceHeightFraction)
        try container.encode(settings.pauseDuration, forKey: .pauseDuration)
        try container.encode(settings.faceCaptureFaceCount, forKey: .faceBufferSize)
    }
}
