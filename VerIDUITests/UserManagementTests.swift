//
//  UserManagementTests.swift
//  VerIDCoreTests
//
//  Created by Jakub Dolejs on 29/11/2019.
//  Copyright © 2019 Applied Recognition Inc. All rights reserved.
//

import XCTest
import VerIDCore

class UserManagementTests: VerIDBaseTest {
    
    let testUser1 = "testUser1"
    
    override func tearDown() {
        super.tearDown()
        do {
            let verid = try self.createVerID()
            let expectation = self.expectation(description: "Delete users")
            let users = try verid.userManagement.users()
            verid.userManagement.deleteUsers(users) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                expectation.fulfill()
            }
            self.wait(for: [expectation], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_assignFaceToUser_succeeds() {
        do {
            let verid = try self.createVerID()
            let faces = try self.veridFaces(forUser: "user1")
            let expectation = self.expectation(description: "Assign faces to user")
            verid.userManagement.assignFaces(faces, toUser: self.testUser1) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_deleteFaces_succeeds() {
        do {
            let verid = try self.createVerID()
            let faces = try self.veridFaces(forUser: "user1")
            let assignFacesExpectation = self.expectation(description: "Assign faces to user")
            verid.userManagement.assignFaces(faces, toUser: self.testUser1) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                assignFacesExpectation.fulfill()
            }
            wait(for: [assignFacesExpectation], timeout: 20.0)
            let deleteFacesExpectation = self.expectation(description: "Delete faces")
            verid.userManagement.deleteFaces(faces) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                deleteFacesExpectation.fulfill()
            }
            wait(for: [deleteFacesExpectation], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_deleteUsers_succeeds() {
        do {
            let verid = try self.createVerID()
            let faces = try self.veridFaces(forUser: "user1")
            let assignFacesExpectation = self.expectation(description: "Assign faces to user")
            verid.userManagement.assignFaces(faces, toUser: self.testUser1) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                assignFacesExpectation.fulfill()
            }
            wait(for: [assignFacesExpectation], timeout: 20.0)
            let deleteFacesExpectation = self.expectation(description: "Delete users")
            verid.userManagement.deleteUsers([self.testUser1]) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                deleteFacesExpectation.fulfill()
            }
            wait(for: [deleteFacesExpectation], timeout: 20.0)
            XCTAssertTrue(try verid.userManagement.users().isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_deleteFakeUsers_succeeds() {
        do {
            let verid = try self.createVerID()
            let expectation = self.expectation(description: "Delete users")
            verid.userManagement.deleteUsers([self.testUser1]) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_deleteEmptyUsers_succeeds() {
        do {
            let verid = try self.createVerID()
            let expectation = self.expectation(description: "Delete users")
            verid.userManagement.deleteUsers([]) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 20.0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_getFaces_returnsFaces() {
        do {
            let verid = try self.createVerID()
            var faces: [Recognizable] = try self.veridFaces(forUser: "user1")
            XCTAssertEqual(faces.count, 2)
            let assignFacesExpectation = self.expectation(description: "Assign faces to user")
            verid.userManagement.assignFaces(faces, toUser: self.testUser1) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                assignFacesExpectation.fulfill()
            }
            wait(for: [assignFacesExpectation], timeout: 20.0)
            faces = try verid.userManagement.faces()
            XCTAssertEqual(faces.count, 2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_getFacesOfUser_returnsFaces() {
        do {
            let verid = try self.createVerID()
            var faces: [Recognizable] = try self.veridFaces(forUser: "user1")
            XCTAssertEqual(faces.count, 2)
            let assignFacesExpectation = self.expectation(description: "Assign faces to user")
            verid.userManagement.assignFaces(faces, toUser: self.testUser1) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                assignFacesExpectation.fulfill()
            }
            wait(for: [assignFacesExpectation], timeout: 20.0)
            faces = try verid.userManagement.facesOfUser(self.testUser1)
            XCTAssertEqual(faces.count, 2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_getFacesOfFakeUser_returnsEmptyArray() {
        do {
            let verid = try self.createVerID()
            let faces = try verid.userManagement.facesOfUser(self.testUser1)
            XCTAssertTrue(faces.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_getUsers_returnsUsers() {
        do {
            let verid = try self.createVerID()
            let faces = try self.veridFaces(forUser: "user1")
            XCTAssertEqual(faces.count, 2)
            let assignFacesExpectation = self.expectation(description: "Assign faces to user")
            verid.userManagement.assignFaces(faces, toUser: self.testUser1) { error in
                if let err = error {
                    XCTFail(err.localizedDescription)
                }
                assignFacesExpectation.fulfill()
            }
            wait(for: [assignFacesExpectation], timeout: 20.0)
            let users = try verid.userManagement.users()
            XCTAssertEqual(users.count, 1)
            XCTAssertEqual(users[0], self.testUser1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_getUsers_returnsEmptyArray() {
        do {
            let verid = try self.createVerID()
            let users = try verid.userManagement.users()
            XCTAssertTrue(users.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func test_v16ToV20Migration_deletesV16FaceTemplates() throws {
        guard #available(iOS 13.0, *) else {
            return
        }
        let verid = try self.createVerID()
        let user1 = "user1"
        let user2 = "user2"
        guard let user1FaceV16 = self.generateFace(faceTemplateVersion: .V16), let user2FaceV16 = self.generateFace(faceTemplateVersion: .V16), let user1FaceV20 = self.generateFace(faceTemplateVersion: .V20), let user2FaceV20 = self.generateFace(faceTemplateVersion: .V20) else {
            XCTFail()
            return
        }
        // Register v16 face of user1
        self.assignFaces([user1FaceV16], toUser: user1, verID: verid)
        // Ensure user1 has 1 v16 face
        XCTAssertEqual(1, try (verid.userManagement as! UserManagement2).facesOfUser(user1, faceTemplateVersion: .V16).count)
        // Register v16 face of user2
        self.assignFaces([user2FaceV16], toUser: user2, verID: verid)
        // Ensure user2 has 1 v16 face
        XCTAssertEqual(1, try (verid.userManagement as! UserManagement2).facesOfUser(user2, faceTemplateVersion: .V16).count)
        // Register v20 face of user1
        self.assignFaces([user1FaceV20], toUser: user1, verID: verid)
        // Ensure there are 2 users with v16 faces
        var v16Users = try (verid.userManagement as! UserManagement2).users(faceTemplateVersion: .V16)
        XCTAssertEqual(2, v16Users.count)
        // Ensure there is 1 user with v20 face
        var v20Users = try (verid.userManagement as! UserManagement2).users(faceTemplateVersion: .V20)
        XCTAssertEqual(1, v20Users.count)
        // Register v20 face of user2
        self.assignFaces([user2FaceV20], toUser: user2, verID: verid)
        // After registering the last v20 face both users have v20 faces and v16 should be automatically deleted
        v16Users = try (verid.userManagement as! UserManagement2).users(faceTemplateVersion: .V16)
        v20Users = try (verid.userManagement as! UserManagement2).users(faceTemplateVersion: .V20)
        XCTAssertEqual(v16Users.count, 0)
        XCTAssertEqual(v20Users.count, 2)
    }
    
    private func assignFaces(_ faces: [Recognizable], toUser user: String, verID: VerID) {
        let assignFacesExpectation = XCTestExpectation()
        verID.userManagement.assignFaces(faces, toUser: user) { error in
            if error != nil {
                XCTFail(error!.localizedDescription)
                return
            }
            assignFacesExpectation.fulfill()
        }
        wait(for: [assignFacesExpectation], timeout: 5.0)
    }
}
