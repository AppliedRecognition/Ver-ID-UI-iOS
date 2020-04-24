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
@objc open class VerIDSession: NSObject, ImageProviderService, VerIDViewControllerDelegate, SessionOperationDelegate, FaceDetectionAlertControllerDelegate, ResultViewControllerDelegate, TipsViewControllerDelegate, UIAdaptivePresentationControllerDelegate, SpeechDelegate {
    
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
    
    /// Delegate that manages presenting the session views
    @objc public weak var viewDelegate: VerIDSessionViewDelegate?
    
    /// Session settings
    @objc public let settings: VerIDSessionSettings
    
    /// Instance of VerID associated with the session
    /// - Since: 1.12.0
    @objc public let environment: VerID
    
    private var viewController: (UIViewController & VerIDViewControllerProtocol)?
    
    // MARK: - Private properties
    
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
    
    private var imageQueue: DispatchQueue?
    private var alertController: UIViewController?
    
    private lazy var speechSynthesizer = AVSpeechSynthesizer()
    private var lastSpokenText: String?
    
    // MARK: - Constructor

    /// Session constructor
    ///
    /// - Parameters:
    ///   - environment: Ver-ID environment used by factory classes
    ///   - settings: Session settings
    ///   - translatedStrings: Translated strings for the session
    /// - Since: 1.8.0
    @objc public init(environment: VerID, settings: VerIDSessionSettings, translatedStrings: TranslatedStrings) {
        self.environment = environment
        self.settings = settings
        self.faceDetectionFactory = VerIDFaceDetectionServiceFactory(environment: environment)
        self.resultEvaluationFactory = VerIDResultEvaluationServiceFactory(environment: environment)
        self.imageWriterFactory = VerIDImageWriterServiceFactory()
        self.sessionViewControllersFactory = VerIDSessionViewControllersFactory(settings: settings, translatedStrings: translatedStrings)
        if settings.videoURL != nil {
            self.videoWriterFactory = VerIDVideoWriterServiceFactory()
        }
    }
    
    /// Session constructor
    ///
    /// - Parameters:
    ///   - environment: Ver-ID environment used by factory classes
    ///   - settings: Session settings
    @objc public convenience init(environment: VerID, settings: VerIDSessionSettings) {
        self.init(environment: environment, settings: settings, translatedStrings: TranslatedStrings())
    }
    
    // MARK: - Public methods
    
    /// Start the session
    @objc public func start() {
        DispatchQueue.main.async {
            if let videoURL = self.settings.videoURL, let videoWriterFactory = self.videoWriterFactory {
                if FileManager.default.isDeletableFile(atPath: videoURL.path) {
                    try? FileManager.default.removeItem(at: videoURL)
                }
                self.videoWriterService = try? videoWriterFactory.makeVideoWriterService(url: videoURL)
            }
            do {
                self.viewController = try self.sessionViewControllersFactory.makeVerIDViewController()
            } catch {
                self.finishWithResult(VerIDSessionResult(error: error))
                return
            }
            self.viewController?.delegate = self
            self.startOperations()
        }
    }
    
    /// Cancel the session
    @objc public func cancel() {
        self.operationQueue.cancelAllOperations()
        self.viewController = nil
        DispatchQueue.main.async {
            self.closeViews {
                self.delegate?.sessionWasCanceled(self)
            }
        }
    }
    
    // MARK: - Methods to overwrite to implement custom user interface
    
    /// Present view controller that provides images for face detection
    ///
    /// - Parameter viewController: Ver-ID view controller
    @objc private func presentVerIDViewController(_ viewController: UIViewController & VerIDViewControllerProtocol) {
        if var speechDelegatable = viewController as? SpeechDelegatable {
            speechDelegatable.speechDelegate = self
        }
        if let viewDelegate = self.viewDelegate {
            viewDelegate.presentVerIDViewController(viewController)
            return
        }
        if self.navigationController == nil {
            guard var root = UIApplication.shared.keyWindow?.rootViewController else {
                self.delegate?.session(self, didFinishWithResult: VerIDSessionResult(error: SessionError.failedToStart))
                return
            }
            while let presented = root.presentedViewController {
                root = presented
            }
            self.navigationController = UINavigationController(rootViewController: viewController)
            self.navigationController?.presentationController?.delegate = self
            root.present(self.navigationController!, animated: true)
        } else {
            self.navigationController!.viewControllers = [viewController]
        }
    }
    
    /// Present view controller showing the result of the session
    ///
    /// - Parameter viewController: Result view controller
    @objc private func presentResultViewController(_ viewController: UIViewController & ResultViewControllerProtocol) {
        if var speechDelegatable = viewController as? SpeechDelegatable {
            speechDelegatable.speechDelegate = self
        }
        if let viewDelegate = self.viewDelegate {
            viewDelegate.presentResultViewController(viewController)
            return
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// Present view controller showing tips on running Ver-ID sessions
    ///
    /// - Parameter viewController: Tips view controller
    @objc private func presentTipsViewController(_ viewController: UIViewController & TipsViewControllerProtocol) {
        if var speechDelegatable = viewController as? SpeechDelegatable {
            speechDelegatable.speechDelegate = self
        }
        if let viewDelegate = self.viewDelegate {
            viewDelegate.presentTipsViewController(viewController)
            return
        }
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// Close views when session finishes
    ///
    /// - Parameter callback: Callback to be issued when views are closed
    @objc private func closeViews(callback: @escaping () -> Void) {
        if let alert = self.alertController {
            alert.dismiss(animated: false, completion: nil)
            self.alertController = nil
        }
        if let viewDelegate = self.viewDelegate {
            viewDelegate.closeViews(callback: callback)
            return
        }
        guard let navController = self.navigationController else {
            callback()
            return
        }
        self.speechSynthesizer.stopSpeaking(at: .word)
        self.navigationController = nil
        navController.dismiss(animated: true) {
            callback()
        }
    }
    
    // MARK: - Private methods
    
    private func startOperations() {
        self.presentVerIDViewController(self.viewController!)
        self.imageQueue = DispatchQueue(label: "com.appliedrec.image", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
        self.viewController?.clearOverlays()
        self.startTime = CACurrentMediaTime()
        self.startDispatchTime = .now()
        self.faceDetection = nil
        do {
            self.faceDetection = try self.faceDetectionFactory.makeFaceDetectionService(settings: self.settings)
        } catch {
            self.showResult(VerIDSessionResult(error: error))
            return
        }
        let op = SessionOperation(environment: self.environment, imageProvider: self, faceDetection: self.faceDetection!, resultEvaluation: self.resultEvaluationFactory.makeResultEvaluationService(settings: self.settings), imageWriter: try? self.imageWriterFactory.makeImageWriterService())
        op.delegate = self
        let finishOp = BlockOperation()
        finishOp.addExecutionBlock { [weak finishOp, weak self] in
            if finishOp != nil && finishOp!.isCancelled {
                return
            }
            self?.imageQueue = nil
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
                    self.presentResultViewController(resultViewController)
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
            self.closeViews {
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
            throw VerIDError.sessionTimeout
        }
        guard let img = self.image else {
            throw NSError(domain: "com.appliedrec.verid", code: 1, userInfo: nil)
        }
        self.imageQueue?.async {
            self.image = nil
        }
        return img
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
        var isBufferCopied: Bool = false
        func copyBuffer() -> Bool {
            let copyBufferSignpost = self.imageAcquisitionSignposting.createSignpost(name: "Copy image buffer")
            self.imageAcquisitionSignposting.logStart(signpost: copyBufferSignpost)
            let status = CMSampleBufferCreateCopy(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleBufferOut: &buffer)
            self.imageAcquisitionSignposting.logEnd(signpost: copyBufferSignpost)
            return status == 0
        }
        if let videoWriter = self.videoWriterService {
            isBufferCopied = copyBuffer()
            if !isBufferCopied {
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
            }
            let writeVideoSignpost = imageAcquisitionSignposting.createSignpost(name: "Write video buffer")
            imageAcquisitionSignposting.logStart(signpost: writeVideoSignpost)
            let rotationRadians: CGFloat
            if #available(iOS 10.0, *) {
                rotationRadians = CGFloat(Measurement(value: Double(rotation), unit: UnitAngle.degrees).converted(to: .radians).value)
            } else {
                rotationRadians = rotation * CGFloat.pi / 180
            }
            videoWriter.writeSampleBuffer(buffer!, rotation: rotationRadians)
            imageAcquisitionSignposting.logEnd(signpost: writeVideoSignpost)
        }
        if !isBufferCopied {
            if !copyBuffer() {
                return
            }
        }
        self.imageQueue?.async {
            if self.image != nil {
                return
            }
            self.image = VerIDImage(sampleBuffer: buffer!, orientation: orientation)
            self.imageLock.signal()
        }
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
            self.operationQueue.cancelAllOperations()
            DispatchQueue.main.async {
                do {
                    self.viewController?.clearOverlays()
                    let alert = try self.sessionViewControllersFactory.makeFaceDetectionAlertController(settings: self.settings, faceDetectionResult: faceDetectionResult)
                    alert.delegate = self
                    alert.modalPresentationStyle = .overFullScreen
                    self.alertController = alert
                    if var speechDelegatable = alert as? SpeechDelegatable {
                        speechDelegatable.speechDelegate = self
                    }
                    self.viewController?.present(alert, animated: true, completion: nil)
                } catch {
                    self.finishWithResult(VerIDSessionResult(error: error))
                }
            }
        }
    }
    
    public func operationDidFinishWritingImage(_ url: URL, forFace face: Face) {
        DispatchQueue.main.async {
            self.viewController?.loadResultImage(url, forFace: face)
        }
    }
    
    // MARK: - Face detection alert controller delegate
    
    /// Called when the user dismisses the dialog that is shown when the session fails due to the user not fulfilling the liveness detection requirements.
    ///
    /// - Parameters:
    ///   - controller: Alert controller that's being dismissed
    ///   - action: Action the user selected to dismiss the alert controller
    public func faceDetectionAlertController(_ controller: FaceDetectionAlertControllerProtocol, didCloseDialogWithAction action: FaceDetectionAlertControllerAction) {
        self.alertController = nil
        self.viewController?.dismiss(animated: true) {
            switch action {
            case .showTips:
                do {
                    let tipsController = try self.sessionViewControllersFactory.makeTipsViewController()
                    tipsController.tipsViewControllerDelegate = self
                    self.presentTipsViewController(tipsController)
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
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.cancel()
    }
    
    // MARK: - Speech delegate
    
    public func speak(_ text: String, language: String) {
        guard self.settings.speakPrompts else {
            return
        }
        if let lastSpoken = self.lastSpokenText, lastSpoken == text {
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        self.speechSynthesizer.stopSpeaking(at: .word)
        self.speechSynthesizer.speak(utterance)
        self.lastSpokenText = text
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
