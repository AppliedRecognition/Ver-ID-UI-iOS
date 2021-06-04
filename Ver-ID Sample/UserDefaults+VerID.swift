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
    @objc var authenticationThreshold: Float {
        get {
            self.float(forKey: "authenticationThreshold")
        }
        set {
            self.set(newValue, forKey: "authenticationThreshold")
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
    @objc dynamic var enableV20FaceTemplateMigration: Bool {
        get {
            self.bool(forKey: "enableV20FaceTemplateMigration")
        }
        set {
            self.set(newValue, forKey: "enableV20FaceTemplateMigration")
        }
    }
    
    func registerVerIDDefaults() {
        let securitySettingsPreset: SecuritySettingsPreset = .normal
        let faceDetectionSettingsPreset: FaceDetectionSettingsPreset = .normal
        let registrationSettings = RegistrationSessionSettings(userId: "")
        self.register(defaults: [
            "poseCount": securitySettingsPreset.poseCount,
            "yawThreshold": securitySettingsPreset.yawThreshold,
            "pitchThreshold": securitySettingsPreset.pitchThreshold,
            "authenticationThreshold": securitySettingsPreset.authThreshold,
            "useBackCamera": false,
            "enableVideoRecording": false,
            "speakPrompts": false,
            "encryptFaceTemplates": true,
            "registrationFaceCount": registrationSettings.faceCaptureCount,
            "confidenceThreshold": faceDetectionSettingsPreset.confidenceThreshold,
            "faceTemplateExtractionThreshold": faceDetectionSettingsPreset.templateExtractionThreshold,
            "faceWidthFraction": registrationSettings.expectedFaceExtents.proportionOfViewWidth,
            "faceHeightFraction": registrationSettings.expectedFaceExtents.proportionOfViewHeight,
            "enableFaceCoveringDetection": false,
            "enableV20FaceTemplateMigration": false
        ])
    }
}
