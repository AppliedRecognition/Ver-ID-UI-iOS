//
//  UserDefaults+VerID.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

extension UserDefaults {
    
    var poseCount: Int {
        get {
            self.integer(forKey: "poseCount")
        }
        set {
            self.set(newValue, forKey: "poseCount")
        }
    }
    var yawThreshold: Float {
        get {
            self.float(forKey: "yawThreshold")
        }
        set {
            self.set(newValue, forKey: "yawThreshold")
        }
    }
    var pitchThreshold: Float {
        get {
            self.float(forKey: "pitchThreshold")
        }
        set {
            self.set(newValue, forKey: "pitchThreshold")
        }
    }
    var poses: [Bearing] {
        get {
            self.stringArray(forKey: "poses")?.compactMap({ Bearing(name: $0) }) ?? []
        }
        set {
            self.set(newValue.map({ $0.name }), forKey: "poses")
        }
    }
    var authenticationThresholds: [VerIDFaceTemplateVersion:Float] {
        get {
            guard let data = self.data(forKey: "authenticationThresholds") else {
                return [:]
            }
            if let dict = try? JSONDecoder().decode([VerIDFaceTemplateVersion:Float].self, from: data) {
                return dict
            }
            return [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                self.set(data, forKey: "authenticationThresholds")
            }
        }
    }
    @objc dynamic var confidenceThreshold: Float {
        get {
            self.float(forKey: "confidenceThreshold")
        }
        set {
            self.set(newValue, forKey: "confidenceThreshold")
        }
    }
    @objc dynamic var faceTemplateExtractionThreshold: Float {
        get {
            self.float(forKey: "faceTemplateExtractionThreshold")
        }
        set {
            self.set(newValue, forKey: "faceTemplateExtractionThreshold")
        }
    }
    var registrationFaceCount: Int {
        get {
            self.integer(forKey: "registrationFaceCount")
        }
        set {
            self.set(newValue, forKey: "registrationFaceCount")
        }
    }
    var useBackCamera: Bool {
        get {
            self.bool(forKey: "useBackCamera")
        }
        set {
            self.set(newValue, forKey: "useBackCamera")
        }
    }
    var enableVideoRecording: Bool {
        get {
            self.bool(forKey: "enableVideoRecording")
        }
        set {
            self.set(newValue, forKey: "enableVideoRecording")
        }
    }
    var speakPrompts: Bool {
        get {
            self.bool(forKey: "speakPrompts")
        }
        set {
            self.set(newValue, forKey: "speakPrompts")
        }
    }
    @objc dynamic var encryptFaceTemplates: Bool {
        get {
            self.bool(forKey: "encryptFaceTemplates")
        }
        set {
            self.set(newValue, forKey: "encryptFaceTemplates")
        }
    }
    @objc dynamic var faceWidthFraction: Float {
        get {
            self.float(forKey: "faceWidthFraction")
        }
        set {
            self.set(newValue, forKey: "faceWidthFraction")
        }
    }
    @objc dynamic var faceHeightFraction: Float {
        get {
            self.float(forKey: "faceHeightFraction")
        }
        set {
            self.set(newValue, forKey: "faceHeightFraction")
        }
    }
    @objc dynamic var enableFaceCoveringDetection: Bool {
        get {
            self.bool(forKey: "enableFaceCoveringDetection")
        }
        set {
            self.set(newValue, forKey: "enableFaceCoveringDetection")
        }
    }
    @objc dynamic var faceDetectorVersion: Int {
        get {
            self.integer(forKey: "faceDetectorVersion")
        }
        set {
            self.set(newValue, forKey: "faceDetectorVersion")
        }
    }
    @objc dynamic var useSpoofDeviceDetector: Bool {
        get {
            self.bool(forKey: "useSpoofDeviceDetector")
        }
        set {
            self.set(newValue, forKey: "useSpoofDeviceDetector")
        }
    }
    @objc dynamic var useMoireDetector: Bool {
        get {
            self.bool(forKey: "useMoireDetector")
        }
        set {
            self.set(newValue, forKey: "useMoireDetector")
        }
    }
    @objc dynamic var useSpoofDetector3: Bool {
        get {
            self.bool(forKey: "useSpoofDetector3")
        }
        set {
            self.set(newValue, forKey: "useSpoofDetector3")
        }
    }
    @objc dynamic var useSpoofDetector4: Bool {
        get {
            self.bool(forKey: "useSpoofDetector4")
        }
        set {
            self.set(newValue, forKey: "useSpoofDetector4")
        }
    }
    
    func registerVerIDDefaults() {
        let securitySettingsPreset: SecuritySettingsPreset = .normal
        let detreclibSettings = DetRecLibSettings(modelsURL: nil)
        let registrationSettings = RegistrationSessionSettings(userId: "")
        let authThresholds = try? JSONEncoder().encode(securitySettingsPreset.authThresholds)
        self.register(defaults: [
            "poseCount": securitySettingsPreset.poseCount,
            "yawThreshold": securitySettingsPreset.yawThreshold,
            "pitchThreshold": securitySettingsPreset.pitchThreshold,
            "authenticationThresholds": authThresholds ?? Data(),
            "poses": securitySettingsPreset.poses.map({ $0.name }),
            "useBackCamera": false,
            "enableVideoRecording": false,
            "speakPrompts": false,
            "encryptFaceTemplates": true,
            "registrationFaceCount": registrationSettings.faceCaptureCount,
            "confidenceThreshold": detreclibSettings.confidenceThreshold,
            "faceTemplateExtractionThreshold": detreclibSettings.faceExtractQualityThreshold,
            "faceWidthFraction": registrationSettings.expectedFaceExtents.proportionOfViewWidth,
            "faceHeightFraction": registrationSettings.expectedFaceExtents.proportionOfViewHeight,
            "enableFaceCoveringDetection": false,
            "faceDetectorVersion": detreclibSettings.detectorVersion,
            "useSpoofDeviceDetector": false,
            "useMoireDetector": true,
            "useSpoofDetector3": true,
            "useSpoofDetector4": true
        ])
    }
}
