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

public class Session: NSObject, ImageProviderService, VerIDViewControllerDelegate, SessionOperationDelegate, FaceDetectionAlertControllerDelegate, ResultViewControllerDelegate, TipsViewControllerDelegate {
    
    // MARK: - Public properties
    
    public var faceDetectionFactory: FaceDetectionServiceFactory
    public var resultEvaluationFactory: ResultEvaluationServiceFactory
    public var imageWriterFactory: ImageWriterServiceFactory
    public var videoWriterFactory: VideoWriterServiceFactory?
    public var sessionViewControllersFactory: SessionViewControllersFactory
    
    public weak var delegate: VerIDUI.SessionDelegate?
    
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
    
    private let synth: AVSpeechSynthesizer
    private var lastSpokenText: String?
    
    private var navigationController: UINavigationController?
    
    // MARK: - Constructor

    public init(environment: VerID, settings: SessionSettings) {
        self.synth = AVSpeechSynthesizer()
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
    
    private func speakText(_ text: String?) {
        if self.settings.speakPrompts, let toSay = text, self.lastSpokenText == nil || self.lastSpokenText! != toSay {
            self.lastSpokenText = toSay
            let utterance = AVSpeechUtterance(string: toSay)
            if let language = Locale.current.languageCode, language.starts(with: "en") || language.starts(with: "fr") {
                utterance.voice = AVSpeechSynthesisVoice(language: language)
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }
            self.synth.speak(utterance)
        }
    }
    
    // MARK: - Image provider
    
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
    
    public func viewControllerDidCancel(_ viewController: VerIDViewControllerProtocol) {
        self.cancel()
    }
    
    public func viewController(_ viewController: VerIDViewControllerProtocol, didFailWithError error: Error) {
        self.finishWithError(error)
    }
    
    public func viewController(_ viewController: VerIDViewControllerProtocol, didCaptureSampleBuffer sampleBuffer: CMSampleBuffer, withRotation rotation: CGFloat) {
        self.videoWriterService?.writeSampleBuffer(sampleBuffer, rotation: rotation)
    }
    
    // MARK: - Session operation delegate
    
    public func operationDidOutputSessionResult(_ result: SessionResult, fromFaceDetectionResult faceDetectionResult: FaceDetectionResult) {
        guard let defaultFaceBounds = self.faceDetection?.defaultFaceBounds(in: faceDetectionResult.imageSize) else {
            return
        }
        let bundle = Bundle(for: type(of: self))
        let labelText: String?
        let isHighlighted: Bool
        let ovalBounds: CGRect
        let cutoutBounds: CGRect?
        let faceAngle: EulerAngle?
        let showArrow: Bool
        let offsetAngleFromBearing: EulerAngle?
        let spokenText: String?
        DispatchQueue.main.async {
            self.viewController?.didProduceSessionResult(result, from: faceDetectionResult)
        }
        if result.isProcessing {
            labelText = NSLocalizedString("Please wait", tableName: nil, bundle: bundle, value: "Please wait", comment: "Displayed above the face when the session is finishing.")
            isHighlighted = true
            ovalBounds = faceDetectionResult.faceBounds ?? defaultFaceBounds
            cutoutBounds = nil
            faceAngle = nil
            showArrow = false
            offsetAngleFromBearing = nil
            spokenText = nil
        } else {
            switch faceDetectionResult.status {
            case .faceFixed, .faceAligned:
                labelText = NSLocalizedString("Great, hold it", tableName: nil, bundle: bundle, value: "Great, hold it", comment: "Displayed above the face when the user correctly followed the directions and should stay still.")
                isHighlighted = true
                ovalBounds = faceDetectionResult.faceBounds ?? defaultFaceBounds
                cutoutBounds = nil
                faceAngle = nil
                showArrow = false
                offsetAngleFromBearing = nil
                spokenText = NSLocalizedString("Hold it", tableName: nil, bundle: bundle, value: "Hold it", comment: "Spoken direction when the user correctly follows the directions and should stay still.")
            case .faceMisaligned:
                labelText = NSLocalizedString("Slowly turn to follow the arrow", tableName: nil, bundle: bundle, value: "Slowly turn to follow the arrow", comment: "Displayed as an instruction during face detection along with an arrow indicating direction")
                isHighlighted = false
                ovalBounds = faceDetectionResult.faceBounds ?? defaultFaceBounds
                cutoutBounds = nil
                faceAngle = faceDetectionResult.faceAngle
                showArrow = true
                offsetAngleFromBearing = self.faceDetection?.offsetFromAngle(faceAngle ?? EulerAngle(yaw: 0, pitch: 0, roll: 0), toBearing: faceDetectionResult.requestedBearing)
                spokenText = NSLocalizedString("Slowly turn to follow the arrow", tableName: nil, bundle: bundle, value: "Slowly turn to follow the arrow", comment: "")
            case .faceTurnedTooFar:
                labelText = nil
                isHighlighted = false
                ovalBounds = faceDetectionResult.faceBounds ?? defaultFaceBounds
                cutoutBounds = nil
                faceAngle = nil
                showArrow = false
                offsetAngleFromBearing = nil
                spokenText = nil
            default:
                labelText = NSLocalizedString("Align your face with the oval", tableName: nil, bundle: bundle, value: "Align your face with the oval", comment: "")
                isHighlighted = false
                ovalBounds = defaultFaceBounds
                cutoutBounds = faceDetectionResult.faceBounds
                faceAngle = nil
                showArrow = false
                offsetAngleFromBearing = nil
                spokenText = NSLocalizedString("Align your face with the oval", tableName: nil, bundle: bundle, value: "Align your face with the oval", comment: "")
            }
        }
        DispatchQueue.main.async {
            guard let transform = self.viewController?.imageScaleTransformAtImageSize(faceDetectionResult.imageSize) else {
                return
            }
            self.viewController?.drawCameraOverlay(bearing: faceDetectionResult.requestedBearing, text: labelText, isHighlighted: isHighlighted, ovalBounds: ovalBounds.applying(transform), cutoutBounds: cutoutBounds?.applying(transform), faceAngle: faceAngle, showArrow: showArrow, offsetAngleFromBearing: offsetAngleFromBearing)
        }
        if result.error != nil {
            if self.retryCount < self.settings.maxRetryCount {
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
        self.speakText(spokenText)
    }
    
    // MARK: - Face detection alert controller delegate
    
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
    
    public func didDismissTipsInViewController(_ viewController: TipsViewControllerProtocol) {
        self.retryCount += 1
        self.startOperations()
    }
    
    // MARK: - Result view controller delegate
    
    public func resultViewControllerDidCancel(_ viewController: ResultViewController) {
        self.cancel()
    }
    
    public func resultViewController(_ viewController: ResultViewController, didFinishWithResult result: SessionResult) {
        self.finishWithResult(result)
    }
}

public protocol SessionDelegate: class {
    func session(_ session: Session, didFinishWithResult result: SessionResult)
    func session(_ session: Session, didFailWithError error: Error)
    func sessionWasCanceled(_ session: Session)
}
