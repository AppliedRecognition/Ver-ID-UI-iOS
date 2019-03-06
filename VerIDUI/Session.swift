//
//  Session.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 04/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit
import VerIDCore
import CoreMedia
import AVFoundation
import os

/// Ver-ID session
public class Session: NSObject, ImageProviderService, VerIDViewControllerDelegate, SessionOperationDelegate, FaceDetectionAlertControllerDelegate, ResultViewControllerDelegate, TipsViewControllerDelegate {
    // MARK: - Public properties
    
    /// Factory that creates face detection service
    public var faceDetectionFactory: FaceDetectionServiceFactory
    /// Factory that creates result evaluation service
    public var resultEvaluationFactory: ResultEvaluationServiceFactory
    /// Factory that creates image writer service
    public var imageWriterFactory: ImageWriterServiceFactory
    /// Factory that creates video writer service
    public var videoWriterFactory: VideoWriterServiceFactory?
    /// Factory that creates view controllers used in the session
    public var sessionViewControllersFactory: SessionViewControllersFactory
    
    /// Session delegate
    public weak var delegate: VerIDUI.SessionDelegate?
    
    /// Session settings
    public let settings: SessionSettings
    
    // MARK: - Private properties
    
    private var viewController: (UIViewController & VerIDViewControllerProtocol & ImageProviderService)?
    
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var videoWriterService: VideoWriterService?
    private var faceDetection: FaceDetectionService?
    private var retryCount = 0
    private var startTime: Double = 0
    
    private var navigationController: UINavigationController?
    
    // MARK: - Constructor

    /// Session constructor
    ///
    /// - Parameters:
    ///   - environment: Ver-ID environment used by factory classes
    ///   - settings: Session settings
    public init(environment: VerID, settings: SessionSettings) {
        self.settings = settings
        self.faceDetectionFactory = VerIDFaceDetectionServiceFactory(environment: environment)
        if settings is RegistrationSessionSettings {
            self.resultEvaluationFactory = VerIDRegistrationEvaluationServiceFactory(environment: environment)
        } else if settings is AuthenticationSessionSettings {
            self.resultEvaluationFactory = VerIDAuthenticationEvaluationServiceFactory(environment: environment)
        } else {
            self.resultEvaluationFactory = VerIDLivenessDetectionEvaluationServiceFactory(environment: environment)
        }
        self.imageWriterFactory = VerIDImageWriterServiceFactory()
        self.sessionViewControllersFactory = VerIDSessionViewControllersFactory(settings: settings)
    }
    
    // MARK: - Public methods
    
    /// Start the session
    public func start() {
        DispatchQueue.main.async {
            if let videoURL = self.settings.videoURL, let videoWriterFactory = self.videoWriterFactory {
                if FileManager.default.isDeletableFile(atPath: videoURL.path) {
                    try? FileManager.default.removeItem(at: videoURL)
                }
                self.videoWriterService = try? videoWriterFactory.makeVideoWriterService(url: videoURL)
            }
            guard var root = UIApplication.shared.keyWindow?.rootViewController else {
                // TODO
                self.delegate?.session(self, didFailWithError: NSError(domain: "com.appliedrec.verid", code: 1, userInfo: nil))
                return
            }
            do {
                self.viewController = try self.sessionViewControllersFactory.makeVerIDViewController()
            } catch {
                self.finishWithError(error)
                return
            }
            self.viewController?.delegate = self
            while let presented = root.presentedViewController {
                root = presented
            }
            self.navigationController = UINavigationController(rootViewController: self.viewController!)
            root.present(self.navigationController!, animated: true)
            self.startOperations()
        }
    }
    
    /// Cancel the session
    public func cancel() {
        self.operationQueue.cancelAllOperations()
        self.viewController = nil
        DispatchQueue.main.async {
            guard let navController = self.navigationController else {
                self.delegate?.sessionWasCanceled(self)
                return
            }
            self.navigationController = nil
            navController.dismiss(animated: true) {
                self.delegate?.sessionWasCanceled(self)
            }
        }
    }
    
    // MARK: - Private methods
    
    private func startOperations() {
        self.startTime = CACurrentMediaTime()
        self.faceDetection = nil
        self.faceDetection = self.faceDetectionFactory.makeFaceDetectionService(settings: self.settings)
        let op = SessionOperation(imageProvider: self, faceDetection: self.faceDetection!, resultEvaluation: self.resultEvaluationFactory.makeResultEvaluationService(settings: self.settings), imageWriter: try? self.imageWriterFactory.makeImageWriterService())
        op.delegate = self
        let finishOp = BlockOperation()
        finishOp.addExecutionBlock {
            if finishOp.isCancelled || op.result.isCanceled {
                return
            }
            if let videoWriter = self.videoWriterService {
                videoWriter.finish() { url in
                    op.result.videoURL = url
                    self.showResult(op.result)
                }
            } else {
                self.showResult(op.result)
            }
        }
        finishOp.addDependency(op)
        self.operationQueue.addOperations([op, finishOp], waitUntilFinished: false)
    }
    
    private func showResult(_ result: SessionResult) {
        self.operationQueue.cancelAllOperations()
        if self.settings.showResult {
            DispatchQueue.main.async {
                do {
                    let resultViewController = try self.sessionViewControllersFactory.makeResultViewController(result: result)
                    resultViewController.delegate = self
                    self.navigationController?.pushViewController(resultViewController, animated: true)
                } catch {
                    self.finishWithError(error)
                }
            }
        } else {
            self.finishWithResult(result)
        }
    }
    
    private func finishWithResult(_ result: SessionResult) {
        self.operationQueue.cancelAllOperations()
        self.viewController = nil
        if let error = result.error {
            self.finishWithError(error)
            return
        }
        DispatchQueue.main.async {
            guard let navController = self.navigationController else {
                self.delegate?.session(self, didFinishWithResult: result)
                return
            }
            self.navigationController = nil
            navController.dismiss(animated: true) {
                self.delegate?.session(self, didFinishWithResult: result)
            }
        }
    }
    
    private func finishWithError(_ error: Error) {
        self.operationQueue.cancelAllOperations()
        self.viewController = nil
        DispatchQueue.main.async {
            guard let navController = self.navigationController else {
                self.delegate?.session(self, didFailWithError: error)
                return
            }
            self.navigationController = nil
            navController.dismiss(animated: true) {
                self.delegate?.session(self, didFailWithError: error)
            }
        }
    }
    
    // MARK: - Image provider
    
    /// Dequeue an image from the Ver-ID view controller
    ///
    /// - Returns: Image to be used for face detection
    /// - Throws: Error if the view controller is nil or if the session expired
    public func dequeueImage() throws -> VerIDImage {
        if self.startTime + self.settings.expiryTime < CACurrentMediaTime() {
            // Session expired
            // TODO
            throw NSError(domain: "com.appliedrec.verid", code: 1, userInfo: nil)
        }
        guard let vc = self.viewController else {
            // TODO
            throw NSError(domain: "com.appliedrec.verid", code: 1, userInfo: nil)
        }
        return try vc.dequeueImage()
    }
    
    // MARK: - Ver-ID view controller delegate
    
    /// User requested to cancel the session in the view controller
    ///
    /// - Parameter viewController: View controller that wants to cancel the session
    public func viewControllerDidCancel(_ viewController: VerIDViewControllerProtocol) {
        self.cancel()
    }
    
    /// View controller failed
    ///
    /// - Parameters:
    ///   - viewController: View controller that failed
    ///   - error: Description of the failure
    public func viewController(_ viewController: VerIDViewControllerProtocol, didFailWithError error: Error) {
        self.finishWithError(error)
    }
    
    /// View controller captured a sample buffer from the camera
    ///
    /// - Parameters:
    ///   - viewController: View controller that captured the sample buffer
    ///   - sampleBuffer: Sample buffer received from the camera
    ///   - rotation: Angle of rotation of the data in the sample buffer
    public func viewController(_ viewController: VerIDViewControllerProtocol, didCaptureSampleBuffer sampleBuffer: CMSampleBuffer, withRotation rotation: CGFloat) {
        self.videoWriterService?.writeSampleBuffer(sampleBuffer, rotation: rotation)
    }
    
    // MARK: - Session operation delegate
    
    /// Session operation evaluated the face detection result and produced a session result
    ///
    /// - Parameters:
    ///   - result: Session result
    ///   - faceDetectionResult: Face detection result used to generate the session result
    /// - Note: This method is called as the session progresses. The final session result is be obtained at the end of the session operation. You can use this method, for example, to prevent the session from finishing in some circumstances.
    public func operationDidOutputSessionResult(_ result: SessionResult, fromFaceDetectionResult faceDetectionResult: FaceDetectionResult) {
        guard let defaultFaceBounds = self.faceDetection?.defaultFaceBounds(in: faceDetectionResult.imageSize) else {
            return
        }
        let offsetAngleFromBearing: EulerAngle? = faceDetectionResult.status == .faceMisaligned ? self.faceDetection?.offsetFromAngle(faceDetectionResult.faceAngle ?? EulerAngle(yaw: 0, pitch: 0, roll: 0), toBearing: faceDetectionResult.requestedBearing) : nil
        DispatchQueue.main.async {
            self.viewController?.drawFaceFromResult(faceDetectionResult, sessionResult: result, defaultFaceBounds: defaultFaceBounds, offsetAngleFromBearing: offsetAngleFromBearing)
        }
        if result.error != nil {
            if self.retryCount < self.settings.maxRetryCount {
                let bundle = Bundle(for: type(of: self))
                let message: String
                if faceDetectionResult.status == .faceTurnedTooFar {
                    message = NSLocalizedString("You may have turned too far. Only turn in the requested direction until the oval turns green.", tableName: nil, bundle: bundle, value: "You may have turned too far. Only turn in the requested direction until the oval turns green.", comment: "Shown in a dialog as an explanation of why the face session is failing")
                } else if faceDetectionResult.status == .faceTurnedOpposite || faceDetectionResult.status == .faceLost {
                    message = NSLocalizedString("Turn your head in the direction of the arrow", tableName: nil, bundle: bundle, value: "Turn your head in the direction of the arrow", comment: "Shown in a dialog as an instruction")
                } else {
                    return
                }
                self.operationQueue.cancelAllOperations()
                DispatchQueue.main.async {
                    let density = UIScreen.main.scale
                    let densityInt = density > 2 ? 3 : 2
                    let videoFileName = self.settings is RegistrationSessionSettings ? "registration" : "liveness_detection"
                    let videoName = String(format: "%@_%d", videoFileName, densityInt)
                    let url = bundle.url(forResource: videoName, withExtension: "mp4")
                    let alert = FaceDetectionAlertController(message: message, videoURL: url, delegate: self)
                    alert.modalPresentationStyle = .overFullScreen
                    self.viewController?.present(alert, animated: true, completion: nil)
                }
            }
            return
        }
    }
    
    // MARK: - Face detection alert controller delegate
    
    /// Called when the user dismisses the dialog that is shown when the session fails due to the user not fulfilling the liveness detection requirements.
    ///
    /// - Parameters:
    ///   - controller: Alert controller that's being dismissed
    ///   - action: Action the user selected to dismiss the alert controller
    func faceDetectionAlertController(_ controller: FaceDetectionAlertController, didCloseDialogWithAction action: FaceDetectionAlertControllerAction) {
        self.viewController?.dismiss(animated: true) {
            switch action {
            case .showTips:
                do {
                    let tipsController = try self.sessionViewControllersFactory.makeTipsViewController()
                    tipsController.tipsViewControllerDelegate = self
                    self.navigationController?.pushViewController(tipsController, animated: true)
                } catch {
                    self.finishWithError(error)
                }
            case .retry:
                self.retryCount += 1
                self.startOperations()
            case .cancel:
                self.cancel()
            }
        }
    }
    
    // MARK: - Tips view controller delegate
    
    /// Called after the user views liveness detection session tips
    ///
    /// - Parameter viewController: Tips view controller that's being dismissed
    public func didDismissTipsInViewController(_ viewController: TipsViewControllerProtocol) {
        self.retryCount += 1
        self.startOperations()
    }
    
    // MARK: - Result view controller delegate
    
    /// Called when the user cancels the session while viewing the result of the session
    ///
    /// - Parameter viewController: View controller that requested to cancel the session
    /// - Note: This will be only be called on failed sessions. Sessions that succeed do not offer the option to cancel.
    public func resultViewControllerDidCancel(_ viewController: ResultViewControllerProtocol) {
        self.cancel()
    }
    
    /// Called when the user acknowledges the result of the session
    ///
    /// - Parameters:
    ///   - viewController: View controller that was dismissed after the user viewed the result
    ///   - result: Session result
    public func resultViewController(_ viewController: ResultViewControllerProtocol, didFinishWithResult result: SessionResult) {
        self.finishWithResult(result)
    }
}

/// Session delegate protocol
public protocol SessionDelegate: class {
    /// Called when the session successfully finishes
    ///
    /// - Parameters:
    ///   - session: Session that finished
    ///   - result: Session result
    func session(_ session: Session, didFinishWithResult result: SessionResult)
    /// Called when the session fails
    ///
    /// - Parameters:
    ///   - session: Session that failed
    ///   - error: Error that caused the failure
    func session(_ session: Session, didFailWithError error: Error)
    /// Called when the session was canceled
    ///
    /// - Parameter session: Session that was canceled
    func sessionWasCanceled(_ session: Session)
}
