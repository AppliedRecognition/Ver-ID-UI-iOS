//
//  TestSessionViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 15/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDUI
import VerIDCore

class TestSessionViewController: UIViewController, VerIDViewControllerProtocol {
    
    var delegate: VerIDViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13, *) {
            self.view.backgroundColor = UIColor.systemBackground
        } else {
            self.view.backgroundColor = UIColor.white
        }
    }
    
    func drawFaceFromResult(_ faceDetectionResult: FaceDetectionResult, sessionResult: VerIDSessionResult, defaultFaceBounds: CGRect, offsetAngleFromBearing: EulerAngle?) {
        
    }
    
    func loadResultImage(_ url: URL, forFace face: Face) {
        
    }
    
    func clearOverlays() {
        
    }
    
}

class TestSessionViewControllersFactory: SessionViewControllersFactory {
    
    let defaultFactory: VerIDSessionViewControllersFactory
    
    init(settings: VerIDSessionSettings) {
        self.defaultFactory = VerIDSessionViewControllersFactory(settings: settings, translatedStrings: TranslatedStrings())
    }
    
    func makeVerIDViewController() throws -> UIViewController & VerIDViewControllerProtocol {
        TestSessionViewController()
    }
    
    func makeResultViewController(result: VerIDSessionResult) throws -> UIViewController & ResultViewControllerProtocol {
        try self.defaultFactory.makeResultViewController(result: result)
    }
    
    func makeTipsViewController() throws -> UIViewController & TipsViewControllerProtocol {
        try self.defaultFactory.makeTipsViewController()
    }
    
    func makeFaceDetectionAlertController(settings: VerIDSessionSettings, faceDetectionResult: FaceDetectionResult) throws -> UIViewController & FaceDetectionAlertControllerProtocol {
        try self.defaultFactory.makeFaceDetectionAlertController(settings: settings, faceDetectionResult: faceDetectionResult)
    }
    
    
}
