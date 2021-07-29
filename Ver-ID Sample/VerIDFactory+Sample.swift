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
        detRecFactory.settings.confidenceThreshold = userDefaults.confidenceThreshold
        detRecFactory.settings.faceExtractQualityThreshold = userDefaults.faceTemplateExtractionThreshold
        detRecFactory.defaultFaceTemplateVersion = userDefaults.enableV20FaceTemplateMigration ? .V20 : .V16
        if let licenceModelPath = Bundle.main.path(forResource: "license01-20210720ay-vh2ukei%2200-q08", ofType: "nv", inDirectory: "Resources") {
            detRecFactory.additionalFaceClassifiers.append(Classifier(name: "license01", filename: licenceModelPath))
        }
        self.faceDetectionFactory = detRecFactory
        self.faceRecognitionFactory = detRecFactory
        self.userManagementFactory = VerIDUserManagementFactory(disableEncryption: !userDefaults.encryptFaceTemplates || Globals.isTesting, isAutomaticFaceTemplateMigrationEnabled: userDefaults.enableV20FaceTemplateMigration)
    }
}
