//
//  VerIDFactory+Sample.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

extension VerIDFactory {
    
    convenience init(userDefaults: UserDefaults) {
        self.init()
        let detRecFactory = VerIDFaceDetectionRecognitionFactory(apiSecret: nil)
        detRecFactory.faceTemplateVersions = [.V24]
        detRecFactory.settings.confidenceThreshold = userDefaults.confidenceThreshold
        detRecFactory.settings.faceExtractQualityThreshold = userDefaults.faceTemplateExtractionThreshold
        detRecFactory.settings.detectorVersion = UInt32(userDefaults.faceDetectorVersion)
        detRecFactory.defaultFaceTemplateVersion = .latest
        self.faceDetectionFactory = detRecFactory
        self.faceRecognitionFactory = detRecFactory
        self.userManagementFactory = VerIDUserManagementFactory(disableEncryption: !userDefaults.encryptFaceTemplates || Globals.isTesting, isAutomaticFaceTemplateMigrationEnabled: false)
        self.spoofDetectorModels = []
        if userDefaults.useSpoofDeviceDetector {
            self.spoofDetectorModels.insert(.spoofDevice)
//            if let modelURLs = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil)?.filter({ $0.lastPathComponent.starts(with: "ARC_PSD-001")}), !modelURLs.isEmpty {
//                self.additionalSpoofDeviceDetectorModelFileURLs = modelURLs
//            }
        }
    }
}
