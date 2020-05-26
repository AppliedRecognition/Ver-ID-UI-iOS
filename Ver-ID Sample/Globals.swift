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
        if result.error == nil, let profilePictureURL = Globals.profilePictureURL, let attachment = result.attachments.first(where: { $0.imageURL != nil && $0.bearing == .straight }), let imageURL = attachment.imageURL, let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) {
            UIGraphicsBeginImageContext(attachment.face.bounds.size)
            image.draw(at: CGPoint(x: 0-attachment.face.bounds.minX, y: 0-attachment.face.bounds.minY))
            if let croppedImageData = UIGraphicsGetImageFromCurrentImageContext()?.jpegData(compressionQuality: 1.0) {
                try? croppedImageData.write(to: profilePictureURL)
            }
            UIGraphicsEndImageContext()
        }
    }
    
    static func deleteImagesInSessionResult(_ sessionResult: VerIDSessionResult) {
        if let videoURL = sessionResult.videoURL {
            try? FileManager.default.removeItem(at: videoURL)
        }
        sessionResult.imageURLs.forEach {
            try? FileManager.default.removeItem(at: $0)
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
