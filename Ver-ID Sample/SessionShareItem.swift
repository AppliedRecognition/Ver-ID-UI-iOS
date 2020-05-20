//
//  SessionShareItem.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 05/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

struct EnvironmentSettings: Encodable {
    let confidenceThreshold: Float
    let faceTemplateExtractionThreshold: Float
    let authenticationThreshold: Float
    let veridVersion: String
    let os: String = "iOS"
}

struct SessionResultShare: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case faces, error, succeeded
    }
    
    enum FaceCodingKeys: String, CodingKey {
        case face, bearing
    }
    
    let sessionResult: VerIDSessionResult
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var facesContainer = container.nestedUnkeyedContainer(forKey: .faces)
        try sessionResult.attachments.forEach({ attachment in
            var faceContainer = facesContainer.nestedContainer(keyedBy: FaceCodingKeys.self)
            try faceContainer.encode(attachment.face, forKey: .face)
            try faceContainer.encode(attachment.bearing, forKey: .bearing)
        })
        if let error = sessionResult.error {
            try container.encode("\(error)", forKey: .error)
            try container.encode(false, forKey: .succeeded)
        } else {
            try container.encode(true, forKey: .succeeded)
        }
    }
}
