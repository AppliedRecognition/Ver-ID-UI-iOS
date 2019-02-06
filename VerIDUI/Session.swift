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

public class Session: NSObject, ImageProviderService, VerIDViewControllerDelegate, SessionOperationDelegate, FaceDetectionAlertControllerDelegate, ResultViewControllerDelegate {
    
    // MARK: - Public properties
    
    public var faceDetectionFactory: FaceDetectionServiceFactory
    public var resultEvaluationFactory: ResultEvaluationServiceFactory
    public var imageWriterFactory: ImageWriterServiceFactory
    public var videoWriterFactory: VideoWriterServiceFactory?
    
    public weak var delegate: VerIDUI.SessionDelegate?
    
    public let settings: SessionSettings
    
    // MARK: - Private properties
    
    private var viewController: VerIDViewController?
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
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
    }
    
    // MARK: - Public methods
    
    public func start() {
        DispatchQueue.main.async {
            self.startTime = CACurrentMediaTime()
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
            self.viewController = VerIDViewController(nibName: nil)
            self.viewController?.delegate = self
            self.faceDetection = self.faceDetectionFactory.makeFaceDetectionService(settings: self.settings)
            while let presented = root.presentedViewController {
                root = presented
            }
            self.navigationController = UINavigationController(rootViewController: self.viewController!)
            root.present(self.navigationController!, animated: true) {
                let op = SessionOperation(imageProvider: self, faceDetection: self.faceDetection!, resultEvaluation: self.resultEvaluationFactory.makeResultEvaluationService(settings: self.settings), imageWriter: try? self.imageWriterFactory.makeImageWriterService())
                op.delegate = self
                let finishOp = BlockOperation()
                finishOp.addExecutionBlock { [unowned finishOp] in
                    if finishOp.isCancelled {
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
        }
    }
    
    public func cancel() {
        self.operationQueue.cancelAllOperations()
        DispatchQueue.main.async {
            self.navigationController?.dismiss(animated: true) {
                self.delegate?.sessionWasCanceled(self)
            }
            self.navigationController = nil
        }
    }
    
    // MARK: - Private methods
    
    private func showResult(_ result: SessionResult) {
        self.operationQueue.cancelAllOperations()
        if self.settings.showResult {
            DispatchQueue.main.async {
                let bundle = Bundle(for: type(of: self))
                let storyboard = UIStoryboard(name: "Result", bundle: bundle)
                let storyboardId = result.error != nil ? "failure" : "success"
                let resultViewController = storyboard.instantiateViewController(withIdentifier: storyboardId) as! ResultViewController
                resultViewController.result = result
                resultViewController.settings = self.settings
                resultViewController.delegate = self
                self.navigationController?.pushViewController(resultViewController, animated: true)
            }
        } else {
            self.finishWithResult(result)
        }
    }
    
    private func finishWithResult(_ result: SessionResult) {
        DispatchQueue.main.async {
            self.navigationController?.dismiss(animated: true) {
                if let error = result.error {
                    self.delegate?.session(self, didFailWithError: error)
                } else {
                    self.delegate?.session(self, didFinishWithResult: result)
                }
            }
            self.navigationController = nil
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
    
    func viewControllerDidCancel(_ viewController: VerIDViewController) {
        self.cancel()
    }
    
    func viewController(_ viewController: VerIDViewController, didFailWithError error: Error) {
        self.operationQueue.cancelAllOperations()
        self.delegate?.session(self, didFailWithError: error)
    }
    
    func viewController(_ viewController: VerIDViewController, didCaptureSampleBuffer sampleBuffer: CMSampleBuffer, withRotation rotation: CGFloat) {
        self.videoWriterService?.writeSampleBuffer(sampleBuffer, rotation: rotation)
    }
    
    // MARK: - Session operation delegate
    
    public func operationDidOutputSessionResult(_ result: SessionResult, fromFaceDetectionResult faceDetectionResult: FaceDetectionResult) {
        guard let defaultFaceBounds = self.faceDetection?.defaultFaceBounds(in: faceDetectionResult.imageSize) else {
            return
        }
        guard let transform = self.viewController?.imageScaleTransformAtImageSize(faceDetectionResult.imageSize) else {
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
            self.viewController?.didProduceSessionResult(result, from: faceDetectionResult)
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
        self.viewController?.drawCameraOverlay(bearing: faceDetectionResult.requestedBearing, text: labelText, isHighlighted: isHighlighted, ovalBounds: ovalBounds.applying(transform), cutoutBounds: cutoutBounds?.applying(transform), faceAngle: faceAngle, showArrow: showArrow, offsetAngleFromBearing: offsetAngleFromBearing)
        if let error = result.error {
            self.operationQueue.cancelAllOperations()
            if self.retryCount < self.settings.maxRetryCount {
                let message: String
                if faceDetectionResult.status == .faceTurnedTooFar {
                    message = NSLocalizedString("You may have turned too far. Only turn in the requested direction until the oval turns green.", tableName: nil, bundle: bundle, value: "You may have turned too far. Only turn in the requested direction until the oval turns green.", comment: "Shown in a dialog as an explanation of why the face session is failing")
                } else {
                    message = NSLocalizedString("Turn your head in the direction of the arrow", tableName: nil, bundle: bundle, value: "Turn your head in the direction of the arrow", comment: "Shown in a dialog as an instruction")
                }
                let density = UIScreen.main.scale
                let densityInt = density > 2 ? 3 : 2
                let videoFileName = self.settings is RegistrationSessionSettings ? "registration" : "liveness_detection"
                let videoName = String(format: "%@_%d", videoFileName, densityInt)
                let url = bundle.url(forResource: videoName, withExtension: "mp4")
                let alert = FaceDetectionAlertController(message: message, videoURL: url, delegate: self)
                alert.modalPresentationStyle = .overFullScreen
                self.viewController?.present(alert, animated: true, completion: nil)
            } else {
                // TODO: Hide view controller
                // Return failure
                self.delegate?.session(self, didFailWithError: error)
            }
            return
        }
        self.speakText(spokenText)
    }
    
    // MARK: - Face detection alert controller delegate
    
    func faceDetectionAlertController(_ controller: FaceDetectionAlertController, didCloseDialogWithAction action: FaceDetectionAlertControllerAction) {
        self.viewController?.dismiss(animated: true) {
            if action == .showTips {
                self.retryCount += 1
                let bundle = Bundle(for: type(of: self))
                if let tipsController = UIStoryboard(name: "Tips", bundle: bundle).instantiateInitialViewController() {
                    self.navigationController?.pushViewController(tipsController, animated: true)
                }
            } else if action == .retry {
                self.retryCount += 1
                self.start()
            }
        }
        if action == .cancel {
            self.cancel()
        }
    }
    
    // MARK: - Result view controller delegate
    
    func resultViewControllerDidCancel(_ viewController: ResultViewController) {
        self.cancel()
    }
    
    func resultViewController(_ viewController: ResultViewController, didFinishWithResult result: SessionResult) {
        self.finishWithResult(result)
    }
}

public protocol SessionDelegate: class {
    func session(_ session: Session, didFinishWithResult result: SessionResult)
    func session(_ session: Session, didFailWithError error: Error)
    func sessionWasCanceled(_ session: Session)
}
