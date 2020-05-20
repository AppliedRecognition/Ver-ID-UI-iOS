//
//  RegistrationProvider.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 06/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import MobileCoreServices
import AVFoundation

class RegistrationProvider: UIActivityItemProvider {
    
    let verid: VerID
    let profilePictureURL: URL
    let url: URL
    
    init(verid: VerID, profilePictureURL: URL) throws {
        self.verid = verid
        self.profilePictureURL = profilePictureURL
        let faces: [Recognizable] = try self.verid.userManagement.facesOfUser(VerIDUser.defaultUserId)
        let imageData = try Data(contentsOf: self.profilePictureURL)
        let registration = RegistrationData(faces: faces, profilePicture: imageData)
        let data = try JSONEncoder().encode(registration)
        self.url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Ver-ID registration").appendingPathExtension("verid")
        try data.write(to: url, options: .atomicWrite)
        super.init(placeholderItem: self.url)
    }
    
    func cleanup() {
        try? FileManager.default.removeItem(at: self.url)
    }
    
    override var item: Any {
        return self.url
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return Globals.registrationUTType
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Ver-ID registration.verid"
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        guard let image = UIImage(contentsOfFile: self.profilePictureURL.path) else {
            return nil
        }
        UIGraphicsBeginImageContext(size)
        defer {
            UIGraphicsEndImageContext()
        }
        let rect = AVMakeRect(aspectRatio: size, insideRect: CGRect(origin: .zero, size: image.size))
        let scale = size.width / rect.width
        let cropRect = CGRect(origin: CGPoint(x: 0-rect.minX*scale, y: 0-rect.minY*scale), size: image.size.applying(CGAffineTransform(scaleX: scale, y: scale)))
        image.draw(in: cropRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
