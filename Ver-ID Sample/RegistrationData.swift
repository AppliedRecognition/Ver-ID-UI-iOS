//
//  RegistrationData.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 26/11/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore

struct RegistrationData: Codable {
    
    enum CodingKeys: String, CodingKey {
        case faces, profilePicture
    }
    
    enum FaceCodingKeys: String, CodingKey {
        case version, data
    }
    
    let faces: [Recognizable]
    let profilePicture: Data
    
    init(faces: [Recognizable], profilePicture: Data) {
        self.faces = faces
        self.profilePicture = profilePicture
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.faces = try container.decode([RecognitionFace].self, forKey: .faces)
        self.profilePicture = try container.decode(Data.self, forKey: .profilePicture)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let faces: [RecognitionFace] = try self.faces.map({
            return try RecognitionFace(recognitionData: $0.recognitionData, version: $0.version)
        })
        try container.encode(faces, forKey: .faces)
        try container.encode(self.profilePicture, forKey: .profilePicture)
    }
}
