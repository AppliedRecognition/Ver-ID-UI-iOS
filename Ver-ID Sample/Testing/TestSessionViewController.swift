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
import AVFoundation
import RxSwift

class TestSessionViewController: UIViewController, VerIDViewControllerProtocol, ImagePublisher {
    
    var imagePublisher: PublishSubject<(VerIDImage, FaceBounds)> = PublishSubject()
    
    var delegate: VerIDViewControllerDelegate?
    
    var sessionSettings: VerIDSessionSettings?
    
    var cameraPosition: AVCaptureDevice.Position = .front
    
    lazy var queue = DispatchQueue(label: "Test session view controller", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13, *) {
            self.view.backgroundColor = UIColor.systemBackground
        } else {
            self.view.backgroundColor = UIColor.white
        }
        self.queue.async {
            while !self.imagePublisher.isDisposed {
                guard let faceExtents = self.sessionSettings?.expectedFaceExtents else {
                    return
                }
                let size = CGSize(width: 750, height: 1000)
                let image = VerIDImage(grayscalePixels: [UInt8](repeating: 0, count: Int(size.width*size.height)), size: size)
                DispatchQueue.main.async {
                    let viewSize = self.view.bounds.size
                    self.queue.async {
                        self.imagePublisher.onNext((image,FaceBounds(viewSize: viewSize, faceExtents: faceExtents)))
                    }
                }
                sleep(1)
            }
        }
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
    
    func makeFaceDetectionAlertController(settings: VerIDSessionSettings, error: Error) throws -> UIViewController & FaceDetectionAlertControllerProtocol {
        try self.defaultFactory.makeFaceDetectionAlertController(settings: settings, error: error)
    }
    
    
}
