//
//  VerIDSession.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 04/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit
import VerIDCore
import CoreMedia
import AVFoundation
import RxSwift
import os

/// Ver-ID session
@objc open class VerIDSession: NSObject, VerIDViewControllerDelegate, FaceDetectionAlertControllerDelegate, ResultViewControllerDelegate, TipsViewControllerDelegate, UIAdaptivePresentationControllerDelegate, SpeechDelegate, VerIDCore.SessionDelegate {
    
    @objc public enum SessionError: Int, Error {
        case failedToStart
    }
    
    // MARK: - Public properties
    
    /// Factory that creates video writer service
    @objc public var videoWriterFactory: VideoWriterServiceFactory
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
    
    /// Unique identifier for the session
    /// - Since: 2.0.0
    @objc public lazy var identifier: String = UUID().uuidString
    
    public var sessionFunctions: SessionFunctions
    
    private var viewController: (UIViewController & VerIDViewControllerProtocol)?
    
    // MARK: - Private properties
    
    private var videoWriterService: VideoWriterService?
    private var startTime: Double = 0
    private var startDispatchTime: DispatchTime = .now()
    
    private var navigationController: UINavigationController?
    
    private var image: VerIDImage?
    private let imageLock = DispatchSemaphore(value: 0)
    
    private let imageAcquisitionSignposting = Signposting(category: "Image acquisition")
    
    private var alertController: UIViewController?
    
    private lazy var speechSynthesizer = AVSpeechSynthesizer()
    private var lastSpokenText: String?
    
    private var session: VerIDCore.Session?
    private let sessionPrompts: SessionPrompts
    
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
        self.sessionPrompts = SessionPrompts(translatedStrings: translatedStrings)
        self.sessionViewControllersFactory = VerIDSessionViewControllersFactory(settings: settings, translatedStrings: translatedStrings)
        self.videoWriterFactory = VerIDVideoWriterServiceFactory()
        self.sessionFunctions = SessionFunctions(verID: environment, sessionSettings: settings)
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
            if self.delegate?.shouldRecordVideoOfSession?(self) == .some(true) {
                let videoURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
                self.videoWriterService = try? self.videoWriterFactory.makeVideoWriterService(url: videoURL)
            } else {
                self.videoWriterService = nil
            }
            do {
                let viewController = try self.sessionViewControllersFactory.makeVerIDViewController()
                viewController.delegate = self
                viewController.sessionSettings = self.settings
                viewController.cameraPosition = self.delegate?.cameraPositionForSession?(self) ?? .front
                self.presentVerIDViewController(viewController)
                self.viewController = viewController
                let imagePublisher = try self.imageObservable(for: viewController)
                self.session = VerIDCore.Session(verID: self.environment, settings: self.settings, imageObservable: imagePublisher)
                self.session?.videoWriterService = self.videoWriterService
                self.session?.sessionFunctions = self.sessionFunctions
                self.session?.delegate = self
                self.session?.start()
            } catch {
                self.finishWithResult(VerIDSessionResult(error: error))
                return
            }
        }
    }
    
    /// Cancel the session
    @objc public func cancel() {
        self.session?.cancel()
        self.session = nil
        self.viewController = nil
        DispatchQueue.main.async {
            self.closeViews {
                self.delegate?.didCancelSession?(self)
            }
        }
    }
    
    // MARK: - Override to provide a custom image observable
    
    public func imageObservable(for viewController: UIViewController & VerIDViewControllerProtocol) throws -> Observable<(VerIDImage, FaceBounds)> {
        if let publisher = (viewController as? ImagePublisher)?.imagePublisher {
            return publisher
        }
        throw VerIDSessionError.imageObservableUnavailable
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
                self.delegate?.didFinishSession(self, withResult: VerIDSessionResult(error: SessionError.failedToStart))
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
    
    // MARK: - Session delegate
    
    public func session(_ session: VerIDCore.Session, didFinishWithResult result: VerIDSessionResult) {
        DispatchQueue.main.async {
            session.delegate = nil
            if let err = result.error, self.delegate?.shouldRetrySession?(self, afterFailure: err) == .some(true) {
                func showErrorController() {
                    do {
                        let controller = try self.sessionViewControllersFactory.makeFaceDetectionAlertController(settings: self.settings, error: err)
                        controller.delegate = self
                        controller.modalPresentationStyle = .overFullScreen
                        if var speechDelegatable = controller as? SpeechDelegatable {
                            speechDelegatable.speechDelegate = self
                        }
                        self.alertController = controller
                        self.viewController?.present(controller, animated: true)
                    } catch {
                        self.session = nil
                        self.finishWithResult(result)
                    }
                }
                if case VerIDSessionError.faceIsCovered = err {
                    showErrorController()
                    return
                } else if err is AntiSpoofingError || err is FacePresenceError {
                    showErrorController()
                    return
                }
            }
            self.session = nil
            if self.delegate?.shouldDisplayResult?(result, ofSession: self) == .some(true) {
                do {
                    let resultViewController = try self.sessionViewControllersFactory.makeResultViewController(result: result)
                    resultViewController.delegate = self
                    self.presentResultViewController(resultViewController)
                    return
                } catch {
                }
            }
            self.finishWithResult(result)
        }
    }
    
    public func session(_ session: VerIDCore.Session, didProduceFaceDetectionResult result: FaceDetectionResult) {
        let prompt: String? = self.sessionPrompts.promptForFaceDetectionResult(result)
        if self.delegate?.shouldSpeakPromptsInSession?(self) == .some(true), let toSay = prompt {
            var language = self.sessionPrompts.translatedStrings.resolvedLanguage
            if let region = self.sessionPrompts.translatedStrings.resolvedRegion {
                language.append("-\(region)")
            }
            self.speak(toSay, language: language)
        }
        self.viewController?.addFaceDetectionResult?(result, prompt: prompt)
    }
    
    public func session(_ session: VerIDCore.Session, didProduceFaceCapture faceCapture: FaceCapture) {
        self.viewController?.addFaceCapture?(faceCapture)
    }
    
    // MARK: - Private methods
    
    private func restartSession() {
        guard let session = self.session, let viewController = self.viewController else {
            return
        }
        self.presentVerIDViewController(viewController)
        session.delegate = self
        session.start()
    }
    
    private func finishWithResult(_ result: VerIDSessionResult) {
        self.viewController = nil
        DispatchQueue.main.async {
            self.closeViews {
                self.delegate?.didFinishSession(self, withResult: result)
            }
        }
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
                self.restartSession()
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
        self.restartSession()
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
        guard self.delegate?.shouldSpeakPromptsInSession?(self) == .some(true) else {
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
