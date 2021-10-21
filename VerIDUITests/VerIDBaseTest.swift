//
//  VerIDBaseTest.swift
//  VerIDCoreTests
//
//  Created by Jakub Dolejs on 26/11/2019.
//  Copyright © 2019 Applied Recognition Inc. All rights reserved.
//

import XCTest
import UIKit
import Accelerate
import Vision
import VerIDCore

class VerIDBaseTest: XCTestCase {
    
    static var images: [String:[UIImage]] = [:]
    static var faces: [String:[RecognizableFace]] = [:]
    static var dlImage: UIImage?
    
    override class func setUp() {
        let imageURLs: [(String,String,String?,Int)] = [
            ("user1", "https://ver-id.s3.amazonaws.com/test_images/jakub/Photo%2004-05-2016%2C%2018%2057%2050.jpg", "https://ver-id.s3.amazonaws.com/test_images/jakub/Photo%2004-05-2016%2C%2018%2057%2050.json", 0),
            ("user1", "https://ver-id.s3.amazonaws.com/test_images/jakub/Photo%2004-05-2016%2C%2020%2031%2029.jpg", "https://ver-id.s3.amazonaws.com/test_images/jakub/Photo%2004-05-2016%2C%2020%2031%2029.json", 1),
            ("user2", "https://ver-id.s3.amazonaws.com/test_images/marcin/Photo%2031-05-2016%2C%2015%2020%2026.jpg", "https://ver-id.s3.amazonaws.com/test_images/marcin/Photo%2031-05-2016%2C%2015%2020%2026.json", 0),
            ("user2", "https://ver-id.s3.amazonaws.com/test_images/marcin/Photo%2031-05-2016%2C%2015%2021%2008.jpg", "https://ver-id.s3.amazonaws.com/test_images/marcin/Photo%2031-05-2016%2C%2015%2021%2008.json", 1),
            ("noface", "https://ver-id.s3.amazonaws.com/test_images/noface/IMG_6748.jpg", nil, 0)
        ]
        var downloadedImages: [String:[UIImage?]] = [:]
        var downloadedJsonFaces: [String:[RecognizableFace?]] = [:]
        imageURLs.forEach({ image in
            let imageCount = imageURLs.filter({ $0.0 == image.0 }).count
            downloadedImages[image.0] = [UIImage?](repeating: nil, count: imageCount)
            let jsonFaceCount = imageURLs.filter({ $0.0 == image.0 && $0.2 != nil }).count
            if jsonFaceCount > 0 {
                downloadedJsonFaces[image.0] = [RecognizableFace?](repeating: nil, count: jsonFaceCount)
            }
        })
        let faceDownloads: [FaceDownloadOperation] = imageURLs.compactMap({
            guard let url = $0.2 else {
                return nil
            }
            return FaceDownloadOperation(url: url, user: $0.0, index: $0.3)
        })
        let imageDownloads: [ImageDownloadOperation] = imageURLs.map({
            return ImageDownloadOperation(url: $0.1, user: $0.0, index: $0.3)
        })
        let idCardDownload = DownloadOperation(url: "https://ver-id.s3.amazonaws.com/test_images/DL/front-1.png")
        let imageDownloadQueue = OperationQueue()
        imageDownloadQueue.maxConcurrentOperationCount = 10
        imageDownloadQueue.addOperations(imageDownloads+faceDownloads+[idCardDownload], waitUntilFinished: true)
        imageDownloads.forEach({ op in
            guard let image = op.image else {
                fatalError("Failed to download image from \(op.url)")
            }
            downloadedImages[op.user]?[op.index] = image
        })
        faceDownloads.forEach({ op in
            guard let face = op.face else {
                fatalError("Failed to download face from \(op.url)")
            }
            downloadedJsonFaces[op.user]?[op.index] = face
        })
        downloadedImages.forEach({
            let imgs = $0.value.compactMap({ $0 })
            VerIDBaseTest.images[$0.key] = imgs
        })
        downloadedJsonFaces.forEach({
            let faces = $0.value.compactMap({ $0 })
            VerIDBaseTest.faces[$0.key] = faces
        })
        guard let idCardImageData = idCardDownload.data, let idCardImage = UIImage(data: idCardImageData) else {
            fatalError("Failed to download ID card image")
        }
        VerIDBaseTest.dlImage = idCardImage
    }
    
    lazy var detRecFactory: VerIDFaceDetectionRecognitionFactory = {
        return VerIDFaceDetectionRecognitionFactory(apiSecret: "87d19186bb9bcc5c3bfc29e0a4eb5366652ba003b35398e56bc9f8f429a4bf1b")
    }()
    
    private var verid: VerID?
    
    func createVerID() throws -> VerID {
        if let verid = self.verid {
            return verid
        }
        let userManagement = VerIDUserManagementFactory(disableEncryption: true, isAutomaticFaceTemplateMigrationEnabled: true)
        let factory = VerIDFactory()
        detRecFactory.defaultFaceTemplateVersion = .V20
        self.configureFaceDetectionRecognitionFactory()
        factory.faceDetectionFactory = detRecFactory
        factory.faceRecognitionFactory = detRecFactory
        factory.userManagementFactory = userManagement
        verid = try factory.createVerIDSync()
        return verid!
    }
    
    func configureFaceDetectionRecognitionFactory() {
        
    }

    func veridImages(forUser user: String) throws -> [VerIDImage] {
        guard let userImages = VerIDBaseTest.images[user] else {
            throw TestingError(message: "User \(user) not found")
        }
        return try userImages.map({
            guard let image = VerIDImage(uiImage: $0) else {
                throw TestingError(message: "Failed to create VerIDImage")
            }
            return image
        })
    }
    
    func veridFaces(forUser user: String) throws -> [RecognizableFace] {
        guard let userFaces = VerIDBaseTest.faces[user] else {
            throw TestingError(message: "User \(user) has no faces")
        }
        return userFaces
    }
    
    func generateFace(faceTemplateVersion: VerIDFaceTemplateVersion) -> Recognizable? {
        guard let faceRecognition = self.verid?.faceRecognition as? VerIDFaceRecognition else {
            return nil
        }
        return try? faceRecognition.generateRandomFaceTemplate(version: faceTemplateVersion)
    }
    
    func generateFaceWithScore(_ score: Float, againstFace face: Recognizable) -> Recognizable? {
        guard let faceRecognition = self.verid?.faceRecognition as? VerIDFaceRecognition else {
            return nil
        }
        return try? faceRecognition.generateRandomFaceTemplateWithScore(NSNumber(value: score), againstFace: face)
    }
}

class TestingError: Error {
    
    private let message: String
    
    init(message: String) {
        self.message = message
    }
    
    var localizedDescription: String {
        return self.message
    }
}

enum ChannelLayout {
    case bgra, argb, abgr, rgba
}

class ImageDownloadOperation1: Operation {
    
    let url: String
    let user: String
    let index: Int
    let jsonURL: String?
    var error: Error?
    var image: UIImage?
    var face: RecognizableFace?
    private var _isExecuting: Bool = false
    private var _isFinished: Bool = false
    private var downloadTask: URLSessionDataTask?
    
    lazy var lockQueue = DispatchQueue(label: "imageDownload", qos: .default, attributes: .concurrent)
    
    override var isAsynchronous: Bool {
        true
    }
    
    override var isExecuting: Bool {
        get {
            return self.lockQueue.sync {
                return self._isExecuting
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            self.lockQueue.sync(flags: [.barrier]) {
                self._isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isFinished: Bool {
        get {
            return self.lockQueue.sync {
                return self._isFinished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            self.lockQueue.sync(flags: [.barrier]) {
                self._isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }
    
    init(url: String, user: String, index: Int, jsonURL: String?) {
        self.url = url
        self.user = user
        self.index = index
        self.jsonURL = jsonURL
    }
    
    override func start() {
        if isCancelled {
            self.finish()
        }
        self.isFinished = false
        self.isExecuting = true
        self.main()
    }
    
    override func main() {
        let session = URLSession(configuration: .ephemeral)
        guard let url = URL(string: self.url) else {
            self.error = TestingError(message: "Invalid URL: \(self.url)")
            return
        }
        self.downloadTask = session.dataTask(with: url) { data, response, error in
            if let err = error {
                self.error = err
            } else if let imageData = data {
                self.image = UIImage(data: imageData)
            } else {
                self.error = TestingError(message: "Image download timed out")
            }
            if let jsonURL = self.jsonURL, let url = URL(string: jsonURL) {
                self.downloadTask = session.dataTask(with: url) { data, response, error in
                    if let err = error {
                        self.error = err
                    } else if let jsonData = data {
                        do {
                            self.face = try JSONDecoder().decode(RecognizableFace.self, from: jsonData)
                        } catch {
                            self.error = error
                        }
                    } else {
                        self.error = TestingError(message: "JSON face download timed out")
                    }
                    self.finish()
                }
                self.downloadTask?.resume()
            } else {
                self.finish()
            }
        }
        if !self.isCancelled {
            self.downloadTask?.resume()
        }
    }
    
    override func cancel() {
        self.downloadTask?.cancel()
        super.cancel()
    }
    
    func finish() {
        self.isExecuting = false
        self.isFinished = true
    }
}
