//
//  FaceRecognitionTests.swift
//  VerIDCoreTests
//
//  Created by Jakub Dolejs on 29/11/2019.
//  Copyright © 2019 Applied Recognition Inc. All rights reserved.
//

import XCTest
import VerIDCore
import FaceTemplateUtility

class FaceRecognitionTests: VerIDBaseTest {
    
    var verid: VerID!
    
    override func setUp() {
        XCTAssertNoThrow(self.verid = try createVerID())
    }

    func test_createRecognizableFaceFromFace_returnsFace() {
        do {
            let image = try self.veridImages(forUser: "user1")[0]
            let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
            let recognizableFaces = try verid.faceRecognition.createRecognizableFacesFromFaces(faces, inImage: image)
            XCTAssertEqual(1, faces.count)
            XCTAssertEqual(faces.count, recognizableFaces.count)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_rawTemplateFromFace_returnsFaceTemplate() {
        do {
            guard let face = try (verid.faceRecognition as? VerIDFaceRecognition)?.generateRandomFaceTemplate(version: .V20) else {
                XCTFail()
                return
            }
            guard let template = try (verid.faceRecognition as? VerIDFaceRecognition)?.rawFaceTemplate(fromFace: face) else {
                XCTFail()
                return
            }
            XCTAssertGreaterThan(template.count, 100)
        } catch {
           XCTFail(error.localizedDescription)
        }
    }
    
    func test_compareSubjectFacesToFaces_returnsScoreAboveThreshold() {
        do {
            let requestedScore: Float = ((verid.faceRecognition as? VerIDFaceRecognition)?.authenticationScoreThreshold(faceTemplateVersion: .V20).floatValue ?? verid.faceRecognition.authenticationScoreThreshold.floatValue) + 1.0
            guard let face1 = self.generateFace(faceTemplateVersion: .V20), let face2 = self.generateFaceWithScore(requestedScore, againstFace: face1) else {
                XCTFail()
                return
            }
            let score = try verid.faceRecognition.compareSubjectFaces([face1], toFaces: [face2])
            XCTAssertGreaterThan(score.floatValue, verid.faceRecognition.authenticationScoreThreshold.floatValue)
        } catch {
           XCTFail(error.localizedDescription)
        }
    }
    
    func test_createRecognizableFace_returnsFaceTemplate() throws {
        self.detRecFactory.faceDetectionImageProcessors = [PassThroughImageProcessorService()]
        let image = try veridImages(forUser: "user1")[0]
        let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
        XCTAssertEqual(1, faces.count)
        let recognizableFaces = try (verid.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces(faces, inImage: image, faceTemplateVersion: .V20)
        XCTAssertEqual(1, recognizableFaces.count)
        guard let expectedTemplate = Data(base64Encoded: "CgsBC3Byb3RvDIIZFAAQAYAAAACvZNo61M/R2bP4CNIT7jfUQb3n6LoLyNvVHZUFyE8x2VdDMU8XBjDG0yBFEmnGKdQdrH/N5KPcL8Eq4s7gQc8DMqDZ4DEuGEQuliO/zjsNGwv5PM08yBcP7e7bNc3NrsNE0RZRr0cpu8YYGCi1bBoMyewbN/qM6SzMwOEzykZKL/Bl2CwJdXVpZAwhmaAzW3GfXiNGFW3YcbEfawE=") else {
            XCTFail()
            return
        }
        guard let faceTemplate = recognizableFaces.first else {
            XCTFail()
            return
        }
        let expectedFace = RecognitionFace(recognitionData: expectedTemplate, version: .v20Unencrypted)
        let score = try compareFaceTemplate(expectedFace, to: faceTemplate)
        XCTAssertGreaterThan(score, 4.99)
    }
    
    func test_compareFacesFromImages_returnsExactScore() throws {
        self.detRecFactory.faceDetectionImageProcessors = [PassThroughImageProcessorService()]
        let images = try self.veridImages(forUser: "user1")
        try self.compareImage(images[0], to: images[1], expectedScore: 5.041674)
    }
    
    func test_compareSubjectFacesToFaces_returnsScoreBelowThreshold() {
        do {
            let requestedScore: Float = ((verid.faceRecognition as? VerIDFaceRecognition)?.authenticationScoreThreshold(faceTemplateVersion: .V20).floatValue ?? verid.faceRecognition.authenticationScoreThreshold.floatValue) - 1.0
            guard let face1 = self.generateFace(faceTemplateVersion: .V20), let face2 = self.generateFaceWithScore(requestedScore, againstFace: face1) else {
                XCTFail()
                return
            }
            let score = try verid.faceRecognition.compareSubjectFaces([face1], toFaces: [face2])
            XCTAssertLessThan(score.floatValue, verid.faceRecognition.authenticationScoreThreshold.floatValue)
        } catch {
           XCTFail(error.localizedDescription)
        }
    }
    
    func test_compareIDCardWithPortrait_returnsExactScore() throws {
        guard #available(iOS 13.0, *) else {
            return
        }
        guard let cardImage = VerIDImage(uiImage: VerIDBaseTest.dlImage!) else {
            XCTFail()
            return
        }
        let cardFaces = try self.verid.faceDetection.detectFacesInImage(cardImage, limit: 1, options: 0)
        XCTAssertGreaterThanOrEqual(cardFaces.count, 1)
        guard let selfieImage = try self.veridImages(forUser: "user1").first else {
            XCTFail()
            return
        }
        let selfieFaces = try self.verid.faceDetection.detectFacesInImage(selfieImage, limit: 1, options: 0)
        XCTAssertGreaterThanOrEqual(selfieFaces.count, 1)
        guard let cardFace = try self.verid.faceRecognition.createRecognizableFacesFromFaces(cardFaces, inImage: cardImage).first else {
            XCTFail()
            return
        }
        guard let selfieFace = try self.verid.faceRecognition.createRecognizableFacesFromFaces(selfieFaces, inImage: selfieImage).first else {
            XCTFail()
            return
        }
        let score = try self.verid.faceRecognition.compareSubjectFaces([selfieFace], toFaces: [cardFace]).floatValue
        XCTAssertGreaterThanOrEqual(score, 4.0)
    }
    
    func test_compareIDCardWithPortraitJD_returnsExactScore() throws {
//        try compareImage("test-images/jakub/selfie1.png", to: "test-images/jakub/card1.png", expectedScore: 4.313399)
    }
    
    func test_compareIDCardWithPortraitJD2_returnsExactScore() throws {
//        try compareImage("test-images/jakub/selfie2.png", to: "test-images/jakub/card2.png", expectedScore: 4.3557186)
    }
    
    func test_extractV20FaceTemplate() throws {
        let image = try self.veridImages(forUser: "user1")[0]
        let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
        let recognizableFaces = try (verid.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces(faces, inImage: image, faceTemplateVersion: .V20)
        XCTAssertGreaterThan(recognizableFaces.count, 0)
        let templateVersion = try (verid.faceRecognition as! VerIDFaceRecognition).versionOfFaceTemplate(recognizableFaces.first!)
        XCTAssertEqual(templateVersion, .V20)
    }
    
    func test_extractV16FaceTemplate() throws {
        let image = try self.veridImages(forUser: "user1")[0]
        let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
        let recognizableFaces = try (verid.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces(faces, inImage: image, faceTemplateVersion: .V16)
        XCTAssertGreaterThan(recognizableFaces.count, 0)
        let templateVersion = try (verid.faceRecognition as! VerIDFaceRecognition).versionOfFaceTemplate(recognizableFaces.first!)
        XCTAssertEqual(templateVersion, .V16)
    }
    
    func test_compareV16AndV20FaceTemplates_fails() throws {
        let image = try self.veridImages(forUser: "user1")[0]
        let faces = try verid.faceDetection.detectFacesInImage(image, limit: 1, options: 0)
        let recognizableFacesV16 = try (verid.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces(faces, inImage: image, faceTemplateVersion: .V16)
        XCTAssertGreaterThan(recognizableFacesV16.count, 0)
        let recognizableFacesV20 = try (verid.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces(faces, inImage: image, faceTemplateVersion: .V20)
        XCTAssertGreaterThan(recognizableFacesV20.count, 0)
        XCTAssertThrowsError(try verid.faceRecognition.compareSubjectFaces(recognizableFacesV16, toFaces: recognizableFacesV20))
    }
    
    func test_identifyUserAmongFaces_succeeds() throws {
        guard let faceRecognition = self.verid.faceRecognition as? VerIDFaceRecognition else {
            return
        }
        try self.deleteAllUsers()
        defer {
            try? self.deleteAllUsers()
        }
        let challengeFace = try faceRecognition.generateRandomFaceTemplate(version: .V20)
        let score = NSNumber(value: faceRecognition.authenticationScoreThreshold(faceTemplateVersion: challengeFace.faceTemplateVersion).floatValue + 0.5)
        let similarUserFace = try faceRecognition.generateRandomFaceTemplateWithScore(score, againstFace: challengeFace)
        let similarUserId = "The One"
        let numberOfUsersToGenerate = 500
        let assignFacesToUsersExpectation = XCTestExpectation(description: "Assign faces to users")
        let identifyUsersExpectation = XCTestExpectation(description: "Identify users in face")
        var userFaces: [(face:Recognizable,user:String)] = [(face: similarUserFace, user: similarUserId)]
        for _ in 0..<numberOfUsersToGenerate {
            userFaces.append((face: try faceRecognition.generateRandomFaceTemplate(version: .V20), user: UUID().uuidString))
        }
        self.assignFacesToUsers(userFaces) { result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success():
                assignFacesToUsersExpectation.fulfill()
            }
        }
        wait(for: [assignFacesToUsersExpectation], timeout: 10.0)
        let userIdentification = UserIdentification(verid: self.verid)
        userIdentification.identifyUsersInFace(similarUserFace) { result in
            switch result {
            case .success(let identifiedUsers):
                XCTAssertTrue(identifiedUsers.keys.contains(similarUserId))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            identifyUsersExpectation.fulfill()
        }
        wait(for: [identifyUsersExpectation], timeout: 60.0)
    }
    
    func test_findSimilarFaceAmongFaces_succeeds() throws {
        guard let faceRecognition = self.verid.faceRecognition as? VerIDFaceRecognition else {
            return
        }
        let challengeFace = try faceRecognition.generateRandomFaceTemplate(version: .V20)
        var faces: [Recognizable] = []
        for _ in 0..<10_000 {
            faces.append(try faceRecognition.generateRandomFaceTemplate(version: .V20))
        }
        let score = NSNumber(value: faceRecognition.authenticationScoreThreshold(faceTemplateVersion: challengeFace.faceTemplateVersion).floatValue + 0.5)
        let similarFace = try faceRecognition.generateRandomFaceTemplateWithScore(score, againstFace: challengeFace)
        XCTAssertGreaterThanOrEqual(try faceRecognition.compareSubjectFaces([similarFace], toFaces: [challengeFace]).floatValue, faceRecognition.authenticationScoreThreshold(faceTemplateVersion: challengeFace.faceTemplateVersion).floatValue)
        faces.append(similarFace)
        let identification = UserIdentification(verid: self.verid)
        let expectation = XCTestExpectation()
        var error: Error?
        var similarFaces: [FaceWithScore]?
        identification.findFacesSimilarTo(challengeFace, in: faces) { result in
            switch result {
            case .success(let similar):
                similarFaces = similar
            case .failure(let err):
                error = err
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(error)
        XCTAssertNotNil(similarFaces)
        guard let faceCount = similarFaces?.count else {
            XCTFail()
            return
        }
        XCTAssertGreaterThanOrEqual(faceCount, 0)
    }
    
    func test_callIdentifyUsersOnMainThread_failsWithError() throws {
        guard let faceRecognition = self.verid.faceRecognition as? VerIDFaceRecognition else {
            return
        }
        defer {
            try? deleteAllUsers()
        }
        try deleteAllUsers()
        let challengeFace = try faceRecognition.generateRandomFaceTemplate(version: .V20)
        var userFaces: [(face: Recognizable, user: String)] = []
        for _ in 0..<3 {
            userFaces.append((face: try faceRecognition.generateRandomFaceTemplate(version: challengeFace.faceTemplateVersion), user: UUID().uuidString))
        }
        let exp = XCTestExpectation(description: "Assign faces to users")
        self.assignFacesToUsers(userFaces) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        let identification = UserIdentification(verid: self.verid)
        XCTAssertThrowsError(try identification.identifyUsersInFace(challengeFace))
    }
    
    private func assignFacesToUsers(_ faces: [(face:Recognizable,user:String)], index: Int = 0, callback: @escaping (Result<Void,Error>) -> Void) {
        if index < faces.count {
            self.verid.userManagement.assignFaces([faces[index].face], toUser: faces[index].user) { error in
                if let err = error {
                    callback(.failure(err))
                    return
                }
                self.assignFacesToUsers(faces, index: index + 1, callback: callback)
            }
        } else {
            callback(.success(()))
        }
    }
    
    func test_callFindSimilarFacesOnMainThread_failsWithError() throws {
        guard let faceRecognition = self.verid.faceRecognition as? VerIDFaceRecognition else {
            return
        }
        let challengeFace = try faceRecognition.generateRandomFaceTemplate(version: .V20)
        var faces: [Recognizable] = []
        for _ in 0..<3 {
            faces.append(try faceRecognition.generateRandomFaceTemplate(version: challengeFace.faceTemplateVersion))
        }
        let identification = UserIdentification(verid: self.verid)
        XCTAssertThrowsError(try identification.findFacesSimilarTo(challengeFace, in: faces))
    }
    
    private func deleteAllUsers() throws {
        let users = try self.verid.userManagement.users()
        if !users.isEmpty {
            let deleteUsersExpectation = XCTestExpectation(description: "Delete all users")
            self.verid.userManagement.deleteUsers(users) { error in
                deleteUsersExpectation.fulfill()
            }
            wait(for: [deleteUsersExpectation], timeout: 2.0)
        }
    }
    
    private func compareImage(_ image1: VerIDImage, to image2: VerIDImage, expectedScore: Float, faceTemplateVersion: VerIDFaceTemplateVersion = .V20) throws {
        let verid = try self.createVerID()
        guard let face1 = try verid.faceDetection.detectFacesInImage(image1, limit: 1, options: 0).first else {
            XCTFail()
            return
        }
        guard let face2 = try verid.faceDetection.detectFacesInImage(image2, limit: 1, options: 0).first else {
            XCTFail()
            return
        }
        let faces1 = try (verid.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces([face1], inImage: image1, faceTemplateVersion: faceTemplateVersion)
        let faces2 = try (verid.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces([face2], inImage: image2, faceTemplateVersion: faceTemplateVersion)
        let score = try verid.faceRecognition.compareSubjectFaces(faces1, toFaces: faces2)
        XCTAssertEqual(expectedScore, score.floatValue, accuracy: 0.08)
    }
    
    private func compareFaceTemplate(_ faceTemplate1: Recognizable, to faceTemplate2: Recognizable) throws -> Float {
        return try self.verid.faceRecognition.compareSubjectFaces([faceTemplate1], toFaces: [faceTemplate2]).floatValue
    }
}
