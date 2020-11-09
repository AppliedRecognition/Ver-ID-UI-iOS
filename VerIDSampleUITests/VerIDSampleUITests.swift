//
//  VerIDSampleUITests.swift
//  VerIDSampleUITests
//
//  Created by Jakub Dolejs on 24/04/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import XCTest

class VerIDSampleUITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        addUIInterruptionMonitor(withDescription: "“Ver-ID Sample” Would Like to Access the Camera") { alert in
            alert.buttons["OK"].tap()
            return true
        }
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app.launchArguments.append("--test")
    }
    
    func testRegisterFace() {
        app.launch()
        app.navigationBars["Ver-ID Sample"].buttons["Register"].tap()
        
        XCTAssertTrue(app.navigationBars["Ver-ID Sample"].buttons["Share"].waitForExistence(timeout: 30))
    }
    
    func testSettingsAbout() {
        app.launch()
        
        app.navigationBars["Ver-ID Sample"].buttons["Settings"].tap()
        app.tables.cells.matching(identifier: "about").firstMatch.tap()
        
        XCTAssertTrue(app.images.matching(identifier: "guide_head_straight").firstMatch.exists)
    }
    
    func testImportRegistration() {
        app.launch()
        
        app.navigationBars["Ver-ID Sample"].buttons["Import"].tap()
        
        XCTAssertTrue(app.navigationBars["Registration Import"].buttons["Register"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.switches.matching(identifier: "overwriteSwitch").firstMatch.exists)
        app.navigationBars["Registration Import"].buttons["Register"].tap()
        
        XCTAssertTrue(app.navigationBars["Ver-ID Sample"].buttons["Share"].waitForExistence(timeout: 2))
    }
    
    func testImportMoreFaces() {
        self.testImportRegistration()
        
        app.buttons["Import more faces"].tap()
        
        XCTAssertTrue(app.navigationBars["Registration Import"].buttons["Register"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.switches.matching(identifier: "overwriteSwitch").firstMatch.exists)
        app.navigationBars["Registration Import"].buttons["Register"].tap()
        
        XCTAssertTrue(app.alerts["Registration imported"].buttons["OK"].waitForExistence(timeout: 2))
        app.alerts["Registration imported"].buttons["OK"].tap()
        
        XCTAssertTrue(app.navigationBars["Ver-ID Sample"].buttons["Share"].waitForExistence(timeout: 5))
    }
    
    func testUnregister() {
        self.testImportRegistration()
        app.images.matching(identifier: "unregister").firstMatch.tap()
        
        XCTAssertTrue(app.buttons["Unregister"].waitForExistence(timeout: 2))
        app.buttons["Unregister"].tap()
        
        XCTAssertTrue(app.navigationBars["Ver-ID Sample"].buttons["Register"].waitForExistence(timeout: 2))
    }
    
    func testExportFaces() {
        self.testImportRegistration()
        app.navigationBars["Ver-ID Sample"].buttons["Share"].tap()
        
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 5))
        
        app.buttons["Copy"].tap()
        
        XCTAssertTrue(UIPasteboard.general.items.contains(where: { $0.keys.contains("com.appliedrec.verid.registration") }))
    }
    
    func testAuthenticate() {
        self.testImportRegistration()
        app.buttons["Authenticate"].tap()
        
        XCTAssertTrue(app.navigationBars["Success"].waitForExistence(timeout: 30))
    }
    
    func testFailAuthentication() {
        app.launchArguments.append("--fail-authentication")
        self.testImportRegistration()
        app.buttons["Authenticate"].tap()
        
        XCTAssertTrue(app.navigationBars["Session Failed"].waitForExistence(timeout: 30))
    }
    
    func testCancelAuthentication() {
        app.launchArguments.append("--cancel-authentication")
        self.testImportRegistration()
        app.buttons["Authenticate"].tap()
        
        app.swipeDown()
        
        XCTAssertTrue(app.navigationBars["Ver-ID Sample"].buttons["Share"].exists)
    }
    
    func testSettingsSecurityPresets() throws {
        app.launch()
        
        app.navigationBars["Ver-ID Sample"].buttons["Settings"].tap()
        
        app.tables.cells.matching(identifier: "securityProfile").firstMatch.tap()
        
        app.segmentedControls.firstMatch.buttons["High"].tap()
        
        var preset = SecuritySettingsPreset.high
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "poseCount").staticTexts["\(preset.poseCount)"].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "yawThreshold").staticTexts[String(format: "%.01f", preset.yawThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "pitchThreshold").staticTexts[String(format: "%.01f", preset.pitchThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "scoreThreshold").staticTexts[String(format: "%.01f", preset.authThreshold)].exists)
        
        app.segmentedControls.firstMatch.buttons["Low"].tap()
        
        preset = SecuritySettingsPreset.low
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "poseCount").staticTexts["\(preset.poseCount)"].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "yawThreshold").staticTexts[String(format: "%.01f", preset.yawThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "pitchThreshold").staticTexts[String(format: "%.01f", preset.pitchThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "scoreThreshold").staticTexts[String(format: "%.01f", preset.authThreshold)].exists)
        
        app.segmentedControls.firstMatch.buttons["Normal"].tap()
        
        preset = SecuritySettingsPreset.normal
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "poseCount").staticTexts["\(preset.poseCount)"].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "yawThreshold").staticTexts[String(format: "%.01f", preset.yawThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "pitchThreshold").staticTexts[String(format: "%.01f", preset.pitchThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "scoreThreshold").staticTexts[String(format: "%.01f", preset.authThreshold)].exists)
        
        app.tables.cells.matching(identifier: "poseCount").firstMatch.tap()
        
        app.tables.cells.element(boundBy: 0).tap()
        
        XCTAssertTrue(app.segmentedControls.buttons["Custom"].isSelected)
        
        app.navigationBars.buttons["Settings"].tap()
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "securityProfile").staticTexts["Custom"].exists)
    }
    
    func testSettingsFaceDetectionPresets() throws {
        app.launch()
        
        app.navigationBars["Ver-ID Sample"].buttons["Settings"].tap()
        
        app.tables.cells.matching(identifier: "faceDetectionProfile").firstMatch.tap()
        
        app.segmentedControls.buttons["Restrictive"].tap()
        
        var preset = FaceDetectionSettingsPreset.restrictive
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "templateExtractionThreshold").staticTexts[String(format: "%.01f", preset.templateExtractionThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "confidenceThreshold").staticTexts[String(format: "%.01f", preset.confidenceThreshold)].exists)
        
        app.segmentedControls.buttons["Permissive"].tap()
        
        preset = .permissive
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "templateExtractionThreshold").staticTexts[String(format: "%.01f", preset.templateExtractionThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "confidenceThreshold").staticTexts[String(format: "%.01f", preset.confidenceThreshold)].exists)
        
        app.segmentedControls.buttons["Normal"].tap()
        
        preset = .normal
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "templateExtractionThreshold").staticTexts[String(format: "%.01f", preset.templateExtractionThreshold)].exists)
        XCTAssertTrue(app.tables.cells.matching(identifier: "confidenceThreshold").staticTexts[String(format: "%.01f", preset.confidenceThreshold)].exists)
        
        app.tables.cells.matching(identifier: "templateExtractionThreshold").firstMatch.tap()
        
        app.tables.cells.element(boundBy: 0).tap()
        
        XCTAssertTrue(app.segmentedControls.buttons["Custom"].isSelected)
        
        app.navigationBars.buttons["Settings"].tap()
        
        XCTAssertTrue(app.tables.cells.matching(identifier: "faceDetectionProfile").staticTexts["Custom"].exists)
    }
    
    func testSettingsFaceWidth() {
        app.launch()
        app.navigationBars["Ver-ID Sample"].buttons["Settings"].tap()
        app.tables.cells.matching(identifier: "faceWidth").firstMatch.tap()
        app.sliders.firstMatch.adjust(toNormalizedSliderPosition: 0.0)
        app.navigationBars.buttons["Settings"].tap()
        XCTAssertTrue(app.tables.cells.matching(identifier: "faceWidth").staticTexts["10%"].exists)
    }
    
    func testSettingsFaceHeight() {
        app.launch()
        app.navigationBars["Ver-ID Sample"].buttons["Settings"].tap()
        app.tables.cells.matching(identifier: "faceHeight").firstMatch.tap()
        app.sliders.firstMatch.adjust(toNormalizedSliderPosition: 0.0)
        app.navigationBars.buttons["Settings"].tap()
        XCTAssertTrue(app.tables.cells.matching(identifier: "faceHeight").staticTexts["10%"].exists)
    }
}
