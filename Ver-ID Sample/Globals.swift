//
//  Globals.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 02/03/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

struct Globals {
    static var profilePictureURL: URL?
    static var verid: VerID?
    
    static func updateProfilePictureFromSessionResult(_ result: VerIDSessionResult) {
        if result.error == nil, let profilePictureURL = Globals.profilePictureURL, let faceImage = result.faceCaptures.first(where: { $0.bearing == .straight })?.faceImage {
            if let croppedImageData = faceImage.jpegData(compressionQuality: 1.0) {
                try? croppedImageData.write(to: profilePictureURL)
            }
        }
    }
    
    static func deleteImagesInSessionResult(_ sessionResult: VerIDSessionResult) {
        if let videoURL = sessionResult.videoURL {
            try? FileManager.default.removeItem(at: videoURL)
        }
    }
    
    static var isTesting: Bool {
        #if DEBUG
            return CommandLine.arguments.contains("--test")
        #else
            return false
        #endif
    }
    
    static var shouldCancelAuthentication: Bool {
        return isTesting && CommandLine.arguments.contains("--cancel-authentication")
    }
    
    static var shouldFailAuthentication: Bool {
        return isTesting && CommandLine.arguments.contains("--fail-authentication")
    }
    
    static let registrationUTType = "com.appliedrec.verid.Registration"
}
