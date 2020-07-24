//
//  SessionItemProvider.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 07/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import ZIPFoundation
import MobileCoreServices
import AVFoundation
import QuickLook

class SessionItemProvider: UIActivityItemProvider {
    
    let settings: VerIDSessionSettings
    let result: VerIDSessionResult
    let environment: EnvironmentSettings
    private let url: URL
    
    init(settings: VerIDSessionSettings, result: VerIDSessionResult, environment: EnvironmentSettings) throws {
        self.settings = settings
        self.result = result
        self.environment = environment
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let name = dateFormatter.string(from: result.startTime)
        self.url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Ver-ID session \(name).zip")
        guard let archive = Archive(url: self.url, accessMode: .create) else {
            throw NSError(domain: kVerIDErrorDomain, code: 205, userInfo: [NSLocalizedDescriptionKey:"Unable to create archive"])
        }
        if let videoURL = result.videoURL {
            let videoData = try Data(contentsOf: videoURL)
            try archive.addEntry(with: "video.mov", type: .file, uncompressedSize: UInt32(videoData.count), provider: { position, size in
                videoData[position..<position+size]
            })
        }
        var i = 1
        for imageData in result.faceCaptures.compactMap({ $0.image.jpegData(compressionQuality: 0.8) }) {
            try archive.addEntry(with: "image\(i).jpg", type: .file, uncompressedSize: UInt32(imageData.count), provider: { position, size in
                imageData[position..<position+size]
            })
            i += 1
        }
        let settingsJson = try JSONEncoder().encode(SessionSettingsShareItem(settings: settings))
        try archive.addEntry(with: "settings.json", type: .file, uncompressedSize: UInt32(settingsJson.count), provider: { position, size in
            settingsJson[position..<position+size]
        })
        let resultJson = try JSONEncoder().encode(SessionResultShare(sessionResult: result))
        try archive.addEntry(with: "result.json", type: .file, uncompressedSize: UInt32(resultJson.count), provider: { position, size in
            resultJson[position..<position+size]
        })
        let environmentJson = try JSONEncoder().encode(environment)
        try archive.addEntry(with: "environment.json", type: .file, uncompressedSize: UInt32(environmentJson.count), provider: { position, size in
            environmentJson[position..<position+size]
        })
        super.init(placeholderItem: self.url)
    }
    
    override var item: Any {
        self.url
    }
    
    func cleanup() {
        try? FileManager.default.removeItem(at: self.url)
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return kUTTypeZipArchive as String
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Ver-ID session"
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        guard let imageURL = self.result.imageURLs(withBearing: .straight).first, let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) else {
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
