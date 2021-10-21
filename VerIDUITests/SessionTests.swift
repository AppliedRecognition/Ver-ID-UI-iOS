//
//  SessionTests.swift
//  VerIDCoreTests
//
//  Created by Jakub Dolejs on 17/03/2021.
//  Copyright © 2021 Applied Recognition Inc. All rights reserved.
//

import XCTest
import RxSwift
import VerIDCore

class SessionTests: VerIDBaseTest {
    
    var images: [Bearing:VerIDImage] = [:]
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let poseImages = ["left","right","straight"]
        let downloads = poseImages.map({
            DownloadOperation(url: "https://ver-id.s3.amazonaws.com/test_images/poses_01/\($0).jpg")
        })
        let downloadQueue = OperationQueue()
        downloadQueue.maxConcurrentOperationCount = poseImages.count
        downloadQueue.addOperations(downloads, waitUntilFinished: true)
        try downloads.forEach { op in
            guard let data = op.data, let image = UIImage(data: data), let veridImage = VerIDImage(uiImage: image) else {
                throw TestingError(message: "Failed to download test image from \(op.url)")
            }
            if op.url.contains("left.jpg") {
                self.images[.left] = veridImage
            } else if op.url.contains("right.jpg") {
                self.images[.right] = veridImage
            } else if op.url.contains("straight.jpg") {
                self.images[.straight] = veridImage
            }
        }
    }
    
    func test_livenessDetectionSession_succeeds() throws {
        let verID = try self.createVerID()        
        let sessionTester = SessionTester(images: self.images)
        let sessionSettings = LivenessDetectionSessionSettings()
        sessionSettings.maxDuration = 10
        sessionSettings.bearings = [.straight, .left, .right]
        let session = Session(verID: verID, settings: sessionSettings, imageObservable: sessionTester.imageObservable)
        session.delegate = sessionTester
        session.start()
        try sessionTester.start()
        wait(for: [sessionTester.expectation], timeout: sessionSettings.maxDuration)
    }

}

class SessionTester: SessionDelegate {
    
    let images: [Bearing:VerIDImage]
    let imageObservable = PublishSubject<(VerIDImage,FaceBounds)>()
    let expectation: XCTestExpectation
    var bearing: Bearing = .straight
    var isStopped = false
    
    init(images: [Bearing:VerIDImage]) {
        self.images = images
        self.expectation = XCTestExpectation()
    }
    
    func start() throws {
        DispatchQueue.global().async {
            while (!self.isStopped) {
                guard let image = self.images[self.bearing], let imageSize = image.size else {
                    return
                }
                self.imageObservable.onNext((image,FaceBounds(viewSize: imageSize, faceExtents: .defaultExtents)))
            }
        }
    }
    
    func session(_ session: Session, didProduceFaceDetectionResult result: FaceDetectionResult) {
        self.bearing = result.requestedBearing
    }
    
    func session(_ session: Session, didFinishWithResult result: VerIDSessionResult) {
        isStopped = true
        self.expectation.fulfill()
    }
}
