//
//  SessionViewControllersFactory.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 06/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit
import VerIDCore

/// Protocol for a factory that creates view controllers used by Ver-ID session
@objc public protocol SessionViewControllersFactory {
    /// Make an instance of a view controller that collects images from the camera and displays the session progress
    ///
    /// - Returns: View controller that conforms to the `VerIDViewControllerProtocol` protocol
    /// - Throws: Error if the creation fails
    @objc func makeVerIDViewController() throws -> UIViewController & VerIDViewControllerProtocol
    /// Make an instance of a view controller that shows the result of a Ver-ID session and
    ///
    /// - Parameter result: Session result that should be displayed by the view controller
    /// - Returns: View controller that conforms to the `ResultViewControllerProtocol` protocol
    /// - Throws: Error if the creation fails
    @objc func makeResultViewController(result: VerIDSessionResult) throws -> UIViewController & ResultViewControllerProtocol
    /// Make an instance of a view controller that shows tips on how to successfully finish a Ver-ID session
    ///
    /// - Returns: View controller that conforms to the `TipsViewControllerProtocol` protocol
    /// - Throws: Error if the creation fails
    @objc func makeTipsViewController() throws -> UIViewController & TipsViewControllerProtocol
    /// Make an instance of an alert view controller shown in a dialog if the session fails and the session settings allow the user to retry the session
    ///
    /// - Parameters:
    ///   - settings: Session settings
    ///   - faceDetectionResult: The face detection result that lead to the session failure
    /// - Returns: View controller that conforms to the `FaceDetectionAlertControllerProtocol` protocol
    /// - Throws: Error if the creation fails
    @objc func makeFaceDetectionAlertController(settings: VerIDSessionSettings, faceDetectionResult: FaceDetectionResult) throws -> UIViewController & FaceDetectionAlertControllerProtocol
}

public enum VerIDSessionViewControllersFactoryError: Int, Error {
    case failedToCreateInstance
}

class VerIDSessionViewControllersFactory: SessionViewControllersFactory {
    
    public let settings: VerIDSessionSettings
    
    public init(settings: VerIDSessionSettings) {
        self.settings = settings
    }
    
    func makeVerIDViewController() throws -> UIViewController & VerIDViewControllerProtocol {
        if self.settings is RegistrationSessionSettings {
            return VerIDRegistrationViewController()
        } else {
            return VerIDViewController(nibName: nil)
        }
    }
    
    func makeResultViewController(result: VerIDSessionResult) throws -> UIViewController & ResultViewControllerProtocol {
        let bundle = Bundle(for: type(of: self))
        let storyboard = UIStoryboard(name: "Result", bundle: bundle)
        let storyboardId = result.error != nil ? "failure" : "success"
        guard let resultViewController = storyboard.instantiateViewController(withIdentifier: storyboardId) as? ResultViewController else {
            throw VerIDSessionViewControllersFactoryError.failedToCreateInstance
        }
        resultViewController.result = result
        resultViewController.settings = self.settings
        return resultViewController
    }
    
    func makeTipsViewController() throws -> UIViewController & TipsViewControllerProtocol {
        let bundle = Bundle(for: type(of: self))
        guard let tipsController = UIStoryboard(name: "Tips", bundle: bundle).instantiateInitialViewController() as? TipsViewController else {
            throw VerIDSessionViewControllersFactoryError.failedToCreateInstance
        }
        return tipsController
    }
    
    func makeFaceDetectionAlertController(settings: VerIDSessionSettings, faceDetectionResult: FaceDetectionResult) throws -> UIViewController & FaceDetectionAlertControllerProtocol {
        let bundle = Bundle(for: type(of: self))
        let message: String
        if faceDetectionResult.status == .faceTurnedTooFar {
            message = NSLocalizedString("You may have turned too far. Only turn in the requested direction until the oval turns green.", tableName: nil, bundle: bundle, value: "You may have turned too far. Only turn in the requested direction until the oval turns green.", comment: "Shown in a dialog as an explanation of why the face session is failing")
        } else if faceDetectionResult.status == .faceTurnedOpposite || faceDetectionResult.status == .faceLost {
            message = NSLocalizedString("Turn your head in the direction of the arrow", tableName: nil, bundle: bundle, value: "Turn your head in the direction of the arrow", comment: "Shown in a dialog as an instruction")
        } else if faceDetectionResult.status == .movedTooFast {
            message = NSLocalizedString("Please turn slowly", comment: "Shown in a dialog as an explanation why the face session is failing")
        } else {
            throw VerIDSessionViewControllersFactoryError.failedToCreateInstance
        }
        let density = UIScreen.main.scale
        let densityInt = density > 2 ? 3 : 2
        let videoFileName: String
        switch faceDetectionResult.requestedBearing {
        case .left:
            videoFileName = "left"
        case .right:
            videoFileName = "right"
        case .down:
            videoFileName = "down"
        case .up:
            videoFileName = "up"
        case .rightUp:
            videoFileName = "right_up"
        case .rightDown:
            videoFileName = "right_down"
        case .leftDown:
            videoFileName = "left_down"
        case .leftUp:
            videoFileName = "left_up"
        default:
            videoFileName = "up_to_centre"
        }
        let videoName = String(format: "%@_%d", videoFileName, densityInt)
        let url = bundle.url(forResource: videoName, withExtension: "mp4")
        return FaceDetectionAlertController(message: message, videoURL: url)
    }
    
}
