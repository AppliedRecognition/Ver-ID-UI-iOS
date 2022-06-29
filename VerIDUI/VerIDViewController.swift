//
//  VerIDViewController.swift
//  VerID
//
//  Created by Jakub Dolejs on 15/12/2015.
//  Copyright © 2015 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import ImageIO
import Accelerate
import VerIDCore
import RxCocoa
import RxSwift

/// Ver-ID view controller protocol – displays the Ver-ID session progress
@objc public protocol VerIDViewControllerProtocol: AnyObject {
    /// View controller delegate
    @objc var delegate: VerIDViewControllerDelegate? { get set }
    @objc var sessionSettings: VerIDSessionSettings? { get set }
    @objc var cameraPosition: AVCaptureDevice.Position { get set }
    @objc optional func addFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult, prompt: String?)
    @objc optional func addFaceCapture(_ faceCapture: FaceCapture)
    @objc optional func clearOverlays()
}

public protocol ImagePublisher {
    
    var imagePublisher: PublishSubject<(Image,FaceBounds)> { get }
}

/// Ver-ID SDK's default implementation of the `VerIDViewControllerProtocol`
@objc open class VerIDViewController: CameraViewController, VerIDViewControllerProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, SpeechDelegatable, ImagePublisher {
    
    /// The view that holds the camera feed.
    @IBOutlet var noCameraLabel: UILabel!
    @IBOutlet var directionLabel: PaddedRoundedLabel!
    @IBOutlet var directionLabelYConstraint: NSLayoutConstraint!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var cancelButton: UIButton!
    
    // MARK: - Colours
    
    /// Colour behind the face 'cutout'
    public var backgroundColour = UIColor(white: 0, alpha: 0.5)
    /// Colour of the face oval and label background when the face is aligned
    public var highlightedColour = UIColor(red: 0.21176470588235, green: 0.68627450980392, blue: 0.0, alpha: 1.0)
    /// Colour of the text when the face is aligned
    public var highlightedTextColour = UIColor.white
    /// Colour of the face oval and label background when the face is not aligned or not detected
    public var neutralColour = UIColor.white
    /// Colour of the text when the face is not aligned or not detected
    public var neutralTextColour = UIColor.black
    
    // MARK: -
    
    private var lastSpokenText: String?
    
    /// The Ver-ID view controller delegate
    public weak var delegate: VerIDViewControllerDelegate?
    
    public var sessionSettings: VerIDSessionSettings?
    
    public var cameraPosition: AVCaptureDevice.Position = .front
    
    weak var speechDelegate: SpeechDelegate?
    
    var focusPointOfInterest: CGPoint? {
        didSet {
            if self.captureDevice != nil && self.captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                do {
                    try self.captureDevice.lockForConfiguration()
                    if let pt = focusPointOfInterest {
                        self.captureDevice.focusPointOfInterest = pt
                    } else {
                        self.captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    }
                    self.captureDevice.focusMode = .continuousAutoFocus
                    self.captureDevice.unlockForConfiguration()
                } catch {
                    
                }
            }
        }
    }
    var currentImageOrientation: CGImagePropertyOrientation = .right
    var _viewSize: CGSize = .zero
    var viewSize: CGSize {
        get {
            let size: CGSize
            self.viewSizeLock.lock()
            size = _viewSize
            self.viewSizeLock.unlock()
            return size
        }
        set {
            self.viewSizeLock.lock()
            self._viewSize = newValue
            self.viewSizeLock.unlock()
        }
    }
    let viewSizeLock: NSLock = .init()
    
    public let imagePublisher = PublishSubject<(Image,FaceBounds)>()
    
    public init(nibName: String? = nil) {
        let nib = nibName ?? "VerIDViewController"
        super.init(nibName: nib, bundle: ResourceHelper.bundle)
        self.videoDataOutput = AVCaptureVideoDataOutput()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Views
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.directionLabel.horizontalInset = 8.0
        self.directionLabel.layer.masksToBounds = true
        self.directionLabel.layer.cornerRadius = 10.0
        self.directionLabel.textColor = UIColor.black
        self.directionLabel.backgroundColor = UIColor.white
        self.noCameraLabel.isHidden = true
        self.noCameraLabel.text = self.translatedStrings?["Camera access denied"]
        self.updateImageOrientation()
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            self.noCameraLabel.text = self.translatedStrings?["Please go to settings and enable camera in the settings for %@.", appName]
        }
        self.directionLabel.text = self.translatedStrings?["Preparing face detection"]
        self.cancelButton.setTitle(self.translatedStrings?["Cancel"], for: .normal)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewSize = self.overlayView.bounds.size
        directionLabel.text = self.translatedStrings?["Preparing face detection"]
        directionLabel.isHidden = directionLabel.text == nil
        directionLabel.backgroundColor = UIColor.white
        directionLabel.textColor = UIColor.black
        cancelButton.isHidden = false
        self.startCamera()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.view, animation: nil) { [weak self] context in
            guard let `self` = self else {
                return
            }
            if !context.isCancelled {
                self.updateImageOrientation()
                self.faceOvalLayer.frame = self.overlayView.layer.bounds
                self.viewSize = self.overlayView.bounds.size
            }
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        return true
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.stopCamera()
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override open func configureOutputs() {
        super.configureOutputs()
        self.videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        let pixelFormat: OSType = kCVPixelFormatType_32BGRA
//        let pixelFormat: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
//        if let pixelFormats = self.videoDataOutput?.availableVideoPixelFormatTypes, pixelFormats.contains(pixelFormat) {
            self.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:pixelFormat]
//        }
        self.videoDataOutput?.setSampleBufferDelegate(self, queue: self.captureSessionQueue)
    }
    
    override open func cameraBecameUnavailable(reason: String) {
        super.cameraBecameUnavailable(reason: reason)
        self.noCameraLabel.isHidden = false
        self.noCameraLabel.text = reason
    }
    
    private func updateImageOrientation() {
        if self.cameraPosition == .back {
            self.currentImageOrientation = self.imageOrientation
        } else {
            switch self.imageOrientation {
            case .up:
                self.currentImageOrientation = .upMirrored
            case .down:
                self.currentImageOrientation = .downMirrored
            case .left:
                self.currentImageOrientation = .leftMirrored
            case .right:
                self.currentImageOrientation = .rightMirrored
            default:
                self.currentImageOrientation = self.imageOrientation
            }
        }
    }
    
    // MARK: -
    
    @IBAction func cancel(_ sender: Any? = nil) {
        self.stopCamera()
        self.delegate?.viewControllerDidCancel(self)
    }
    
    open override var captureDevice: AVCaptureDevice! {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: self.cameraPosition)
    }
    
    // MARK: - Drawing face guide oval and arrows
    
    public func addFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult, prompt: String?) {
        OperationQueue.main.addOperation {
            guard self.isViewLoaded else {
                return
            }
            self.overlayView.isHidden = false
            self.cancelButton.isHidden = false
            self.directionLabel.text = prompt
            self.directionLabel.isHidden = prompt == nil || prompt!.isEmpty
            self.directionLabel.textColor = self.textColourFromFaceDetectionStatus(faceDetectionResult.status)
            self.directionLabel.backgroundColor = self.ovalColourFromFaceDetectionStatus(faceDetectionResult.status)
            let imageSize = CGSize(width: faceDetectionResult.image.width, height: faceDetectionResult.image.height)
            let defaultFaceBounds = faceDetectionResult.defaultFaceBounds.translatedToImageSize(imageSize)
            var ovalBounds: CGRect
            var cutoutBounds: CGRect?
            switch faceDetectionResult.status {
            case .faceFixed, .faceAligned:
                ovalBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
                cutoutBounds = faceDetectionResult.faceBounds
            case .faceMisaligned:
                ovalBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
                cutoutBounds = faceDetectionResult.faceBounds
            case .faceTurnedTooFar:
                ovalBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
                cutoutBounds = ovalBounds
            default:
                ovalBounds = defaultFaceBounds
                cutoutBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
            }
            let scale = max(self.overlayView.bounds.width / imageSize.width, self.overlayView.bounds.height / imageSize.height)
            let transform = CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: self.overlayView.bounds.width / 2 - imageSize.width * scale / 2, y: self.overlayView.bounds.height / 2 - imageSize.height * scale / 2))
            ovalBounds = ovalBounds.applying(transform)
            cutoutBounds = cutoutBounds?.applying(transform)
            
            self.directionLabelYConstraint.constant = min(self.view.bounds.height - self.directionLabel.frame.height, max(ovalBounds.minY - self.directionLabel.frame.height - 16, 0))
            
            let angle: CGFloat?
            let distance: CGFloat?
            if let offsetAngle = faceDetectionResult.offsetAngleFromBearing {
                angle = atan2(CGFloat(0.0-offsetAngle.pitch), CGFloat(offsetAngle.yaw))
                distance = hypot(offsetAngle.yaw, 0-offsetAngle.pitch) * 2;
            } else {
                angle = nil
                distance = nil
            }
            let landmarks: [CGPoint] = []//faceDetectionResult.faceLandmarks.map({ $0.applying(transform) })
            self.faceOvalLayer.setOvalBounds(ovalBounds, cutoutBounds: cutoutBounds, backgroundColour: self.backgroundColour, strokeColour: self.ovalColourFromFaceDetectionStatus(faceDetectionResult.status), faceLandmarks: landmarks, angle: angle, distance: distance)
        }
    }
    
    public func addFaceCapture(_ faceCapture: FaceCapture) {
    }
    
    open func textColourFromFaceDetectionStatus(_ faceDetectionStatus: FaceDetectionStatus) -> UIColor {
        switch faceDetectionStatus {
        case .faceFixed, .faceAligned:
            return self.highlightedTextColour
        default:
            return self.neutralTextColour
        }
    }
    
    open func ovalColourFromFaceDetectionStatus(_ faceDetectionStatus: FaceDetectionStatus) -> UIColor {
        switch faceDetectionStatus {
        case .faceFixed, .faceAligned:
            return self.highlightedColour
        default:
            return self.neutralColour
        }
    }
    
    public func clearOverlays() {
        self.directionLabel?.isHidden = true
        self.overlayView?.isHidden = true
        self.cancelButton?.isHidden = true
    }
    
    // MARK: - Sample Capture
    
    /// Called when the camera returns an image
    ///
    /// - Parameters:
    ///   - output: output by which the image was collected
    ///   - sampleBuffer: image sample buffer
    ///   - connection: capture connection
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = try? VerIDImage(sampleBuffer: sampleBuffer, orientation: self.currentImageOrientation).provideVerIDImage() else {
            return
        }
        image.isMirrored = cameraPosition == .front
        self.imagePublisher.onNext((image,FaceBounds(viewSize: self.viewSize, faceExtents: self.sessionSettings?.expectedFaceExtents ?? FaceExtents.defaultExtents)))
    }
    
    // MARK: -
    
    private var faceOvalLayer: FaceOvalLayer {
        if let subs = self.overlayView.layer.sublayers, let faceLayer = subs.compactMap({ $0 as? FaceOvalLayer }).first {
            faceLayer.frame = self.overlayView.layer.bounds
            return faceLayer
        } else {
            let detectedFaceLayer = FaceOvalLayer(strokeColor: UIColor.black, backgroundColor: UIColor(white: 0, alpha: 0.5))
            //            detectedFaceLayer.text = self.faceOvalText
            self.overlayView.layer.addSublayer(detectedFaceLayer)
            detectedFaceLayer.frame = self.overlayView.layer.bounds
            return detectedFaceLayer
        }
    }
    
    // MARK: - AV capture session errors
    
    override func sessionRuntimeError(notification: NSNotification) {
        self.stopCamera()
        let error: Error
        if let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError {
            error = AVError(_nsError: errorValue)
        } else {
            error = VerIDUISessionError.captureSessionRuntimeError
        }
        self.delegate?.viewController(self, didFailWithError: error)
    }
    
    override func sessionWasInterrupted(notification: NSNotification) {
        self.stopCamera()
        let error: VerIDUISessionError
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            switch reason {
            case .videoDeviceInUseByAnotherClient, .audioDeviceInUseByAnotherClient:
                error = .cameraInUseByAnotherClient
            case .videoDeviceNotAvailableDueToSystemPressure:
                error = .cameraNotAvailableDueToSystemPressure
            case .videoDeviceNotAvailableInBackground:
                error = .cameraNotAvailableInBackground
            case .videoDeviceNotAvailableWithMultipleForegroundApps:
                error = .cameraNotAvailableWithMultipleForegroundApps
            default:
                error = .captureSessionInterrupted
            }
        } else {
            error = .captureSessionInterrupted
        }
        self.delegate?.viewController(self, didFailWithError: error)
    }
    
    override func sessionInterruptionEnded(notification: NSNotification) {
    }
}
