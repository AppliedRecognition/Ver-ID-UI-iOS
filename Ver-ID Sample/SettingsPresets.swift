//
//  SettingsPresets.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 06/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation

struct SecuritySettingsPreset: Equatable {
    let poseCount: Int
    let yawThreshold: Float
    let pitchThreshold: Float
    let authThreshold: Float
    
    static let low: SecuritySettingsPreset = SecuritySettingsPreset(poseCount: 1, yawThreshold: 12.0, pitchThreshold: 10.0, authThreshold: 3.5)
    static let normal: SecuritySettingsPreset = SecuritySettingsPreset(poseCount: 2, yawThreshold: 15.0, pitchThreshold: 12.0, authThreshold: 4.0)
    static let high: SecuritySettingsPreset = SecuritySettingsPreset(poseCount: 3, yawThreshold: 18.0, pitchThreshold: 15.0, authThreshold: 4.5)
}

struct FaceDetectionSettingsPreset: Equatable {
    let confidenceThreshold: Float
    let templateExtractionThreshold: Float
    
    static let permissive = FaceDetectionSettingsPreset(confidenceThreshold: -0.5, templateExtractionThreshold: 6.0)
    static let normal = FaceDetectionSettingsPreset(confidenceThreshold: -0.5, templateExtractionThreshold: 8.0)
    static let restrictive = FaceDetectionSettingsPreset(confidenceThreshold: 0.0, templateExtractionThreshold: 9.0)
}
