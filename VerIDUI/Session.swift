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
@objc public class VerIDSession: NSObject, ImageProviderService, VerIDViewControllerDelegate, SessionOperationDelegate, FaceDetectionAlertControllerDelegate, ResultViewControllerDelegate, TipsViewControllerDelegate {
    
    @objc public enum SessionError: Int, Error {
        case failedToStart
    }
    
    // MARK: - Public properties
    
    /// Factory that creates face detection service
    @objc public var faceDetectionFactory: FaceDetectionServiceFactory
    /// Factory that creates result evaluation service
    @objc public var resultEvaluationFactory: ResultEvaluationServiceFactory
    /// Factory that creates image writer service
    @objc public var imageWriterFactory: ImageWriterServiceFactory
    /// Factory that creates video writer service
    @objc public var videoWriterFactory: VideoWriterServiceFactory?
    /// Factory that creates view controllers used in the session
    @objc public var sessionViewControllersFactory: SessionViewControllersFactory
    
    /// Session delegate
    @objc public weak var delegate: VerIDSessionDelegate?
    
    /// Session settings
    @objc public let settings: VerIDSessionSettings
    
    // MARK: - Private properties
    
    private var viewController: (UIViewController & VerIDViewControllerProtocol)?
    
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
    private var startDispatchTime: DispatchTime = .now()
    
    private var navigationController: UINavigationController?
    
    private var image: VerIDImage?
    private let imageLock = DispatchSemaphore(value: 0)
    
    private let imageAcquisitionSignposting = Signposting(category: "Image acquisition")
    
    // MARK: - Constructor

    /// Session constructor
    ///
    /// - Parameters:
    ///   - environment: Ver-ID environment used by factory classes
    ///   - settings: Session settings
    public init(environment: VerID, settings: VerIDSessionSettings) {
        self.settings = settings
        self.faceDetectionFactory = VerIDFaceDetectionServiceFactory(environment: environment)
        self.resultEvaluationFactory = VerIDResultEvaluationServiceFactory(environment: environment)
        self.imageWriterFactory = VerIDImageWriterServiceFactory()
        self.sessionViewControllersFactory = VerIDSessionViewControllersFactory(settings: settings)
        if settings.videoURL != nil {
            self.videoWriterFactory = VerIDVideoWriterServiceFactory()
        }
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
                self.delegate?.session(self, didFinishWithResult: VerIDSessionResult(error: SessionError.failedToStart))
                return
            }
            do {
                self.viewController = try self.sessionViewControllersFactory.makeVerIDViewController()
            } catch {
                self.finishWithResult(VerIDSessionResult(error: error))
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
        self.startDispatchTime = .now()
        self.faceDetection = nil
        do {
            self.faceDetection = try self.faceDetectionFactory.makeFaceDetectionService(settings: self.settings)
        } catch {
            self.showResult(VerIDSessionResult(error: error))
            return
        }
        let op = SessionOperation(imageProvider: self, faceDetection: self.faceDetection!, resultEvaluation: self.resultEvaluationFactory.makeResultEvaluationService(settings: self.settings), imageWriter: try? self.imageWriterFactory.makeImageWriterService())
        op.delegate = self
        let finishOp = BlockOperation()
        finishOp.addExecutionBlock { [weak finishOp, weak self] in
            if finishOp != nil && finishOp!.isCancelled {
                return
            }
            if let videoWriter = self?.videoWriterService {
                videoWriter.finish() { url in
                    op.result.videoURL = url
                    self?.showResult(op.result)
                }
            } else {
                self?.showResult(op.result)
            }
        }
        finishOp.addDependency(op)
        self.operationQueue.addOperations([op, finishOp], waitUntilFinished: false)
    }
    
    private func showResult(_ result: VerIDSessionResult) {
        self.operationQueue.cancelAllOperations()
        if self.settings.showResult {
            DispatchQueue.main.async {
                do {
                    let resultViewController = try self.sessionViewControllersFactory.makeResultViewController(result: result)
                    resultViewController.delegate = self
                    self.navigationController?.pushViewController(resultViewController, animated: true)
                } catch {
                    self.finishWithResult(VerIDSessionResult(error: error))
                }
            }
        } else {
            self.finishWithResult(result)
        }
    }
    
    private func finishWithResult(_ result: VerIDSessionResult) {
        self.operationQueue.cancelAllOperations()
        self.viewController = nil
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
    
    // MARK: - Image provider
    
    /// Dequeue an image from the Ver-ID view controller
    ///
    /// - Returns: Image to be used for face detection
    /// - Throws: Error if the view controller is nil or if the session expired
    public func dequeueImage() throws -> VerIDImage {
        if imageLock.wait(timeout: self.startDispatchTime+self.settings.expiryTime) == .timedOut {
            // Session expired
            // TODO
            throw NSError(domain: "com.appliedrec.verid", code: 1, userInfo: nil)
        }
        return image!
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
        self.finishWithResult(VerIDSessionResult(error: error))
    }
    
    /// View controller captured a sample buffer from the camera
    ///
    /// - Parameters:
    ///   - viewController: View controller that captured the sample buffer
    ///   - sampleBuffer: Sample buffer received from the camera
    ///   - orientation: Image orientation of the data in the sample buffer
    public func viewController(_ viewController: VerIDViewControllerProtocol, didCaptureSampleBuffer sampleBuffer: CMSampleBuffer, withOrientation orientation: CGImagePropertyOrientation) {
        var buffer: CMSampleBuffer?
        let copyBufferSignpost = imageAcquisitionSignposting.createSignpost(name: "Copy image buffer")
        imageAcquisitionSignposting.logStart(signpost: copyBufferSignpost)
        let status = CMSampleBufferCreateCopy(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleBufferOut: &buffer)
        imageAcquisitionSignposting.logEnd(signpost: copyBufferSignpost)
        guard status == 0 else {
            return
        }
        let rotation: CGFloat
        switch orientation {
        case .right, .rightMirrored:
            rotation = 90
        case .left, .leftMirrored:
            rotation = 270
        case .down, .downMirrored:
            rotation = 0
        case .up, .upMirrored:
            rotation = 180
        @unknown default:
            rotation = 0
        }
        let writeVideoSignpost = imageAcquisitionSignposting.createSignpost(name: "Write video buffer")
        imageAcquisitionSignposting.logStart(signpost: writeVideoSignpost)
        self.videoWriterService?.writeSampleBuffer(buffer!, rotation: CGFloat(Measurement(value: Double(rotation), unit: UnitAngle.degrees).converted(to: .radians).value))
        imageAcquisitionSignposting.logEnd(signpost: writeVideoSignpost)
        image = VerIDImage(sampleBuffer: buffer!, orientation: orientation)
        let convertToGrayscaleSignpost = imageAcquisitionSignposting.createSignpost(name: "Convert image to grayscale")
        imageAcquisitionSignposting.logStart(signpost: convertToGrayscaleSignpost)
        let _ = image!.grayscalePixels
        imageAcquisitionSignposting.logEnd(signpost: convertToGrayscaleSignpost)
        imageLock.signal()
    }
    
    // MARK: - Session operation delegate
    
    /// Session operation evaluated the face detection result and produced a session result
    ///
    /// - Parameters:
    ///   - result: Session result
    ///   - faceDetectionResult: Face detection result used to generate the session result
    /// - Note: This method is called as the session progresses. The final session result is be obtained at the end of the session operation. You can use this method, for example, to prevent the session from finishing in some circumstances.
    public func operationDidOutputSessionResult(_ result: VerIDSessionResult, fromFaceDetectionResult faceDetectionResult: FaceDetectionResult) {
        guard let defaultFaceBounds = self.faceDetection?.faceAlignmentDetection.defaultFaceBounds(in: faceDetectionResult.imageSize) else {
            return
        }
        let offsetAngleFromBearing: EulerAngle? = faceDetectionResult.status == .faceMisaligned ? self.faceDetection?.angleBearingEvaluation.offsetFromAngle(faceDetectionResult.faceAngle ?? EulerAngle(yaw: 0, pitch: 0, roll: 0), toBearing: faceDetectionResult.requestedBearing) : nil
        DispatchQueue.main.async {
            self.viewController?.drawFaceFromResult(faceDetectionResult, sessionResult: result, defaultFaceBounds: defaultFaceBounds, offsetAngleFromBearing: offsetAngleFromBearing)
        }
        if result.error != nil && self.retryCount < self.settings.maxRetryCount && (faceDetectionResult.status == .faceTurnedTooFar || faceDetectionResult.status == .faceTurnedOpposite || faceDetectionResult.status == .faceLost || faceDetectionResult.status == .movedTooFast) {
            do {
                let alert = try self.sessionViewControllersFactory.makeFaceDetectionAlertController(settings: self.settings, faceDetectionResult: faceDetectionResult)
                self.operationQueue.cancelAllOperations()
                DispatchQueue.main.async {
                    alert.delegate = self
                    alert.modalPresentationStyle = .overFullScreen
                    self.viewController?.present(alert, animated: true, completion: nil)
                }
            } catch {
            }
        }
    }
    
    // MARK: - Face detection alert controller delegate
    
    /// Called when the user dismisses the dialog that is shown when the session fails due to the user not fulfilling the liveness detection requirements.
    ///
    /// - Parameters:
    ///   - controller: Alert controller that's being dismissed
    ///   - action: Action the user selected to dismiss the alert controller
    public func faceDetectionAlertController(_ controller: FaceDetectionAlertControllerProtocol, didCloseDialogWithAction action: FaceDetectionAlertControllerAction) {
        self.viewController?.dismiss(animated: true) {
            switch action {
            case .showTips:
                do {
                    let tipsController = try self.sessionViewControllersFactory.makeTipsViewController()
                    tipsController.tipsViewControllerDelegate = self
                    self.navigationController?.pushViewController(tipsController, animated: true)
                } catch {
                    let result = VerIDSessionResult(error: error)
                    self.finishWithResult(result)
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
    public func resultViewController(_ viewController: ResultViewControllerProtocol, didFinishWithResult result: VerIDSessionResult) {
        self.finishWithResult(result)
    }
}

/// Session delegate protocol
@objc public protocol VerIDSessionDelegate: class {
    /// Called when the session successfully finishes
    ///
    /// - Parameters:
    ///   - session: Session that finished
    ///   - result: Session result
    @objc func session(_ session: VerIDSession, didFinishWithResult result: VerIDSessionResult)
    /// Called when the session was canceled
    ///
    /// - Parameter session: Session that was canceled
    @objc func sessionWasCanceled(_ session: VerIDSession)
}

@available(*, deprecated, renamed: "VerIDSession") public typealias Session = VerIDSession

@available(*, deprecated, renamed: "VerIDSessionDelegate") public typealias SessionDelegate = VerIDSessionDelegate
