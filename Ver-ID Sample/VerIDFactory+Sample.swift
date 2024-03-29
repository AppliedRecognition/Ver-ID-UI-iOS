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
        }
        if userDefaults.useMoireDetector {
            self.spoofDetectorModels.insert(.moire)
        }
        if userDefaults.useSpoofDetector3 {
            self.spoofDetectorModels.insert(.spoof3)
        }
        if userDefaults.useSpoofDetector4 {
            self.spoofDetectorModels.insert(.spoof4)
        }
    }
}
