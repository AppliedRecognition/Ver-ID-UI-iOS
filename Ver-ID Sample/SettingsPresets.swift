//
//  SettingsPresets.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 06/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

struct SecuritySettingsPreset: Equatable {
    let poseCount: Int
    let yawThreshold: Float
    let pitchThreshold: Float
    let authThresholds: [VerIDFaceTemplateVersion: Float]
    let poses: [Bearing]
    
    static let low: SecuritySettingsPreset = SecuritySettingsPreset(poseCount: 1, yawThreshold: 12.0, pitchThreshold: 10.0, authThresholds: [.V16: 3.5, .V20: 3.0, .V21: 3.0], poses: [.straight])
    static let normal: SecuritySettingsPreset = SecuritySettingsPreset(poseCount: 2, yawThreshold: 15.0, pitchThreshold: 12.0, authThresholds: [.V16: 4.0, .V20: 3.5, .V21: 3.5], poses: [.straight, .left, .right])
    static let high: SecuritySettingsPreset = SecuritySettingsPreset(poseCount: 3, yawThreshold: 18.0, pitchThreshold: 15.0, authThresholds: [.V16: 4.5, .V20: 4.0, .V21: 4.0], poses: [.straight, .left, .leftUp, .right, .rightUp])
}

struct FaceDetectionSettingsPreset: Equatable {
    let confidenceThreshold: Float
    let templateExtractionThreshold: Float
    
    static let permissive = FaceDetectionSettingsPreset(confidenceThreshold: -0.5, templateExtractionThreshold: 6.0)
    static let normal = FaceDetectionSettingsPreset(confidenceThreshold: -0.5, templateExtractionThreshold: 8.0)
    static let restrictive = FaceDetectionSettingsPreset(confidenceThreshold: 0.0, templateExtractionThreshold: 9.0)
}
