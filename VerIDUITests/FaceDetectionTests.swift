//
//  FaceDetectionTests.swift
//  VerIDCoreTests
//
//  Created by Jakub Dolejs on 26/11/2019.
//  Copyright © 2019 Applied Recognition Inc. All rights reserved.
//

import XCTest
import VerIDCore

class FaceDetectionTests: VerIDBaseTest {

    func test_detectFacesInImage_returnsFace() {
        do {
            let verid = try self.createVerID()
            let image = try self.veridImages(forUser: "user2")[0]
            let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
            XCTAssertFalse(faces.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_detectFacesInImageWithoutFace_returnsEmptyArray() {
        do {
            let verid = try self.createVerID()
            let image = try self.veridImages(forUser: "noface")[0]
            let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
            
            XCTAssertTrue(faces.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_trackFaceInImage_returnsFace() {
        do {
            let verid = try self.createVerID()
            let image = try self.veridImages(forUser: "user2")[0]
            let faceTracking = verid.faceDetection.startFaceTracking()
            let _ = try faceTracking.trackFaceInImage(image)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_detectFaceInImage_returnsExpectedLandmarks() throws {
        self.detRecFactory.faceDetectionImageProcessors = [PassThroughImageProcessorService()]
        let verid = try self.createVerID()
        let image = try self.veridImages(forUser: "user1")[0]
        let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
        XCTAssertEqual(faces.count, 1)
        guard let face = faces.first else {
            return
        }
        let delta: CGFloat = 0.01
        let leftEye = CGPoint(x: 373.5, y: 648)
        let rightEye = CGPoint(x: 589, y: 643.5)
        XCTAssertEqual(leftEye.x, face.leftEye.x, accuracy: delta)
        XCTAssertEqual(leftEye.y, face.leftEye.y, accuracy: delta)
        XCTAssertEqual(rightEye.x, face.rightEye.x, accuracy: delta)
        XCTAssertEqual(rightEye.y, face.rightEye.y, accuracy: delta)
        // Angle
        let angle = EulerAngle(yaw: -1.768096923828125, pitch: -6.613119125366211, roll: -1.1374866962432861)
        XCTAssertEqual(angle.yaw, face.angle.yaw, accuracy: delta)
        XCTAssertEqual(angle.pitch, face.angle.pitch, accuracy: delta)
        XCTAssertEqual(angle.roll, face.angle.roll, accuracy: delta)
        // Landmarks
        let landmarks: [CGPoint] = [
            CGPoint(x: 253.000000, y: 675.000000),
            CGPoint(x: 257.000000, y: 743.000000),
            CGPoint(x: 266.000000, y: 812.000000),
            CGPoint(x: 275.000000, y: 880.000000),
            CGPoint(x: 294.000000, y: 945.000000),
            CGPoint(x: 328.000000, y: 1004.000000),
            CGPoint(x: 371.000000, y: 1051.000000),
            CGPoint(x: 421.000000, y: 1089.000000),
            CGPoint(x: 486.000000, y: 1098.000000),
            CGPoint(x: 553.000000, y: 1086.000000),
            CGPoint(x: 602.000000, y: 1050.000000),
            CGPoint(x: 648.000000, y: 999.000000),
            CGPoint(x: 682.000000, y: 939.000000),
            CGPoint(x: 699.000000, y: 871.000000),
            CGPoint(x: 710.000000, y: 801.000000),
            CGPoint(x: 719.000000, y: 730.000000),
            CGPoint(x: 720.000000, y: 659.000000),
            CGPoint(x: 278.000000, y: 632.000000),
            CGPoint(x: 300.000000, y: 593.000000),
            CGPoint(x: 344.000000, y: 577.000000),
            CGPoint(x: 393.000000, y: 577.000000),
            CGPoint(x: 441.000000, y: 587.000000),
            CGPoint(x: 512.000000, y: 583.000000),
            CGPoint(x: 562.000000, y: 569.000000),
            CGPoint(x: 613.000000, y: 567.000000),
            CGPoint(x: 662.000000, y: 584.000000),
            CGPoint(x: 691.000000, y: 622.000000),
            CGPoint(x: 472.000000, y: 634.000000),
            CGPoint(x: 471.000000, y: 673.000000),
            CGPoint(x: 469.000000, y: 713.000000),
            CGPoint(x: 467.000000, y: 755.000000),
            CGPoint(x: 427.000000, y: 800.000000),
            CGPoint(x: 449.000000, y: 807.000000),
            CGPoint(x: 474.000000, y: 811.000000),
            CGPoint(x: 500.000000, y: 806.000000),
            CGPoint(x: 525.000000, y: 800.000000),
            CGPoint(x: 331.000000, y: 648.000000),
            CGPoint(x: 356.000000, y: 631.000000),
            CGPoint(x: 387.000000, y: 630.000000),
            CGPoint(x: 416.000000, y: 648.000000),
            CGPoint(x: 387.000000, y: 654.000000),
            CGPoint(x: 356.000000, y: 657.000000),
            CGPoint(x: 544.000000, y: 647.000000),
            CGPoint(x: 575.000000, y: 627.000000),
            CGPoint(x: 608.000000, y: 627.000000),
            CGPoint(x: 634.000000, y: 640.000000),
            CGPoint(x: 609.000000, y: 652.000000),
            CGPoint(x: 576.000000, y: 652.000000),
            CGPoint(x: 397.000000, y: 916.000000),
            CGPoint(x: 422.000000, y: 892.000000),
            CGPoint(x: 455.000000, y: 881.000000),
            CGPoint(x: 483.000000, y: 888.000000),
            CGPoint(x: 510.000000, y: 880.000000),
            CGPoint(x: 546.000000, y: 891.000000),
            CGPoint(x: 578.000000, y: 913.000000),
            CGPoint(x: 548.000000, y: 939.000000),
            CGPoint(x: 511.000000, y: 950.000000),
            CGPoint(x: 482.000000, y: 951.000000),
            CGPoint(x: 454.000000, y: 950.000000),
            CGPoint(x: 422.000000, y: 939.000000),
            CGPoint(x: 411.000000, y: 914.000000),
            CGPoint(x: 455.000000, y: 909.000000),
            CGPoint(x: 482.000000, y: 910.000000),
            CGPoint(x: 511.000000, y: 907.000000),
            CGPoint(x: 562.000000, y: 913.000000),
            CGPoint(x: 510.000000, y: 914.000000),
            CGPoint(x: 482.000000, y: 915.000000),
            CGPoint(x: 455.000000, y: 914.000000)
        ]
        for i in 0..<landmarks.count {
            XCTAssertEqual(landmarks[i].x, face.landmarks[i].x, accuracy: delta)
            XCTAssertEqual(landmarks[i].y, face.landmarks[i].y, accuracy: delta)
        }
    }
    
    func testClassifiersContainLicence() throws {
        let verid = try self.createVerID()
        guard let faceDetection = verid.faceDetection as? VerIDFaceDetection else {
            return
        }
        XCTAssertTrue(faceDetection.faceAttributeClassifiers.contains("licence"))
    }
    
    func testLicenceClassifier() throws {
        let verid = try self.createVerID()
        guard let faceDetection = verid.faceDetection as? VerIDFaceDetection else {
            return
        }
        guard let verIDImage = VerIDImage(uiImage: VerIDBaseTest.dlImage!) else {
            XCTFail("Failed to create VerIDImage")
            return
        }
        guard let face = try faceDetection.detectFacesInImage(verIDImage, limit: 1, options: 0).first else {
            XCTFail("Failed to detect a face in image")
            return
        }
        let score = try faceDetection.extractAttributeFromFace(face, image: verIDImage, using: "licence").floatValue
        XCTAssertLessThan(score, 0.5)
    }
    
    override func configureFaceDetectionRecognitionFactory() {
        guard let authModelPath = Bundle(for: type(of: self)).path(forResource: "license01-20210720ay-vh2ukei%2200-q08", ofType: "nv") else {
            return
        }
        let classifier = Classifier(name: "licence", filename: authModelPath)
        self.detRecFactory.additionalFaceClassifiers.append(classifier)
    }
}
