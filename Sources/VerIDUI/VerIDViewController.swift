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
import SceneKit
import SceneKit.ModelIO
import VerIDCore
import RxCocoa
import RxSwift
import Combine

/// Ver-ID view controller protocol – displays the Ver-ID session progress
@objc public protocol VerIDViewControllerProtocol: AnyObject {
    /// View controller delegate
    @objc var delegate: VerIDViewControllerDelegate? { get set }
    @objc var sessionSettings: VerIDSessionSettings? { get set }
    @objc var cameraPosition: AVCaptureDevice.Position { get set }
    @objc var videoWriter: VideoWriterService? { get set }
    @objc var shouldDisplayCGHeadGuidance: Bool { get set }
    @objc optional func addFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult, prompt: String?)
    @objc optional func addFaceCapture(_ faceCapture: FaceCapture)
    @objc optional func clearOverlays()
    @objc optional func willFinishWithResult(_ result: VerIDSessionResult, completion: @escaping () -> Void)
}

public protocol ImagePublisher {
    
    var imagePublisher: PublishSubject<(Image,FaceBounds)> { get }
}

public protocol ImageCapturePublisher {
    
    var imageCapture: AnyPublisher<ImageCapture,Error> { get }
}

/// Ver-ID SDK's default implementation of the `VerIDViewControllerProtocol`
@objc open class VerIDViewController: CameraViewController, VerIDViewControllerProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, SpeechDelegatable, ImagePublisher, ImageCapturePublisher {
    
    private var imageCaptureSubject: PassthroughSubject<VerIDCore.ImageCapture, Error> = PassthroughSubject()
    public var imageCapture: AnyPublisher<VerIDCore.ImageCapture, Error> {
        self.imageCaptureSubject.eraseToAnyPublisher()
    }
    
    /// The view that holds the camera feed.
    @IBOutlet var noCameraLabel: UILabel!
    @IBOutlet var directionLabel: UILabel!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var faceViewsContainer: UIView!
    @IBOutlet private var faceOvalView: FaceOvalView!
    @IBOutlet private var headSceneView: HeadView!
    @IBOutlet private var faceImageView: UIImageView!
    @IBOutlet private var faceOvalWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var faceOvalHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var cancelButton: UIButton!
    private var nextAvailableViewChangeTime: CFTimeInterval?
    private var latestMisalignTime: CFTimeInterval?
    private var faceImageViewAnimator: UIViewPropertyAnimator?
    
    // MARK: - Colours
    
    /// Colour behind the face 'cutout'
    @available(*, deprecated)
    public var backgroundColour = UIColor.clear
    /// Colour of the face oval and label background when the face is aligned
    @available(*, deprecated)
    public var highlightedColour = UIColor(red: 0.21176470588235, green: 0.68627450980392, blue: 0.0, alpha: 1.0)
    /// Colour of the text when the face is aligned
    @available(*, deprecated)
    public var highlightedTextColour = UIColor.white
    /// Colour of the face oval and label background when the face is not aligned or not detected
    @available(*, deprecated)
    public var neutralColour = UIColor.white
    /// Colour of the text when the face is not aligned or not detected
    @available(*, deprecated)
    public var neutralTextColour = UIColor.black
    
    public var shouldShowCancelButton: Bool = true
    /// Set to `false` to disable visual tracking of the detected face prior to alignment in the requested face bounds
    /// - Since: 2.13.0
    public var isTrackedFaceHighlightEnabled: Bool = true
    
    // MARK: -
    
    private var lastSpokenText: String?
    
    /// The Ver-ID view controller delegate
    public weak var delegate: VerIDViewControllerDelegate?
    
    public var sessionSettings: VerIDSessionSettings?
    
    public var cameraPosition: AVCaptureDevice.Position = .front
    
    public var videoWriter: VideoWriterService?
    
    weak var speechDelegate: SpeechDelegate?
    
    public var shouldDisplayCGHeadGuidance: Bool = true
    
    public var sessionTheme: SessionTheme = .default {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            self.view.backgroundColor = self.sessionTheme.backgroundColor
            self.faceOvalView?.sessionTheme = self.sessionTheme
            self.cancelButton.setTitleColor(self.sessionTheme.textColor, for: .normal)
        }
    }
    
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
    private var faceMisalignTime: CFTimeInterval?
    private var faceCaptureCount = 0
    
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
        self.view.backgroundColor = self.sessionTheme.backgroundColor
        self.cancelButton.setTitleColor(self.sessionTheme.textColor, for: .normal)
        self.faceOvalView.isHidden = true
        self.noCameraLabel.isHidden = true
        self.noCameraLabel.text = self.translatedStrings?["Camera access denied"]
        self.updateImageOrientation()
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            self.noCameraLabel.text = self.translatedStrings?["Please go to settings and enable camera in the settings for %@.", appName]
        }
        self.directionLabel.text = self.translatedStrings?["Preparing face detection"]
        self.directionLabel.textColor = self.sessionTheme.textColor
        self.directionLabel.isHidden = true
        self.faceViewsContainer.isHidden = true
        self.faceOvalView.sessionTheme = self.sessionTheme
        self.cancelButton.isHidden = !self.shouldShowCancelButton
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateViewSizes()
        self.directionLabel.isHidden = directionLabel.text == nil
        self.faceCaptureCount = 0
        self.startCamera()
    }
    
    func updateFaceOvalDimensions() {
        if let faceExtents = self.sessionSettings?.expectedFaceExtents {
//            let faceAspectRatio: CGFloat = 4 / 5
//            let viewAspectRatio = self.viewSize.width / self.viewSize.height
//            let faceSize: CGSize
//            if viewAspectRatio > faceAspectRatio {
//                let ovalHeight = self.viewSize.height * faceExtents.proportionOfViewHeight
//                faceSize = CGSize(width: ovalHeight * faceAspectRatio, height: ovalHeight)
//            } else {
//                let ovalWidth = self.viewSize.width * faceExtents.proportionOfViewWidth
//                faceSize = CGSize(width: ovalWidth, height: ovalWidth / faceAspectRatio)
//            }
            self.faceOvalWidthConstraint = self.faceOvalWidthConstraint.copyWithMultiplier(faceExtents.proportionOfViewWidth)
            self.faceOvalHeightConstraint = self.faceOvalHeightConstraint.copyWithMultiplier(faceExtents.proportionOfViewHeight)
//            self.faceViewsContainer.translatesAutoresizingMaskIntoConstraints = true
//            self.faceViewsContainer.frame = CGRect(origin: CGPoint(x: self.view.bounds.midX - faceSize.width / 2, y: self.view.bounds.midY - faceSize.height / 2), size: faceSize)
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.view, animation: nil) { [weak self] context in
            guard let `self` = self else {
                return
            }
            if !context.isCancelled {
                self.updateViewSizes()
            }
        }
    }
    
    func updateViewSizes() {
        self.overlayView.frame = self.view.bounds
        self.updateImageOrientation()
        self.viewSize = self.overlayView.bounds.size
        self.updateFaceOvalDimensions()
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
    
    open override func cameraBecameAvailable() {
        super.cameraBecameAvailable()
        self.cameraPreviewView.superview?.isHidden = true
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
        OperationQueue.main.addOperation { [weak self] in
            guard let `self` = self, self.isViewLoaded && !self.isFinishing else {
                return
            }
            guard let settings = self.sessionSettings else {
                return
            }
            if self.faceCaptureCount >= settings.faceCaptureCount {
                return
            }
            if faceDetectionResult.status != .faceAligned, let nextAvailableViewChangeTime = self.nextAvailableViewChangeTime, nextAvailableViewChangeTime > CACurrentMediaTime() {
                return
            }
            self.faceViewsContainer.isHidden = false
            self.activityIndicator.stopAnimating()
            self.cameraPreviewView.superview?.isHidden = false
            self.overlayView.isHidden = false
            self.directionLabel.text = prompt
            self.directionLabel.isHidden = prompt == nil || prompt!.isEmpty
            
            
            self.cameraPreviewView.transform = self.cameraViewTransformFromFaceDetectionResult(faceDetectionResult)
            self.maskCameraPreviewFromFaceDetectionResult(faceDetectionResult)
            self.drawArrowFromFaceDetectionResult(faceDetectionResult)
            
            switch (faceDetectionResult.status, self.isTrackedFaceHighlightEnabled) {
            case (.faceAligned, _):
                self.latestMisalignTime = nil
                self.headSceneView.isHidden = true
                self.faceCaptureCount += 1
                if let image = try? faceDetectionResult.image.provideUIImage(), let face = faceDetectionResult.face, let faceImage = ImageUtil.image(image, croppedToFace: self.cameraPosition == .front ? face.flipped(imageSize: image.size) : face) {
                    if self.cameraPosition == .front {
                        self.faceImageView.image = faceImage.withHorizontallyFlippedOrientation()
                    } else {
                        self.faceImageView.image = faceImage
                    }
                    let imageMask = CAShapeLayer()
                    imageMask.path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: self.faceImageView.bounds.size)).cgPath
                    self.faceImageView.layer.mask = imageMask
                    self.faceImageView.isHidden = false
                    let scale: CGFloat = 0.9
                    self.faceImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
                    self.cameraPreviewView.superview?.isHidden = true
                    let animationDuration: TimeInterval = 1.0
                    if let animator = self.faceImageViewAnimator {
                        animator.stopAnimation(false)
                        animator.finishAnimation(at: .end)
                    }
                    let animator = UIViewPropertyAnimator(duration: animationDuration, dampingRatio: 0.4) {
                        self.faceImageView.transform = .identity
                    }
                    animator.addCompletion { [weak self] position in
                        guard let `self` = self, position == .end else {
                            return
                        }
                        if self.faceCaptureCount < settings.faceCaptureCount {
                            self.faceImageView.isHidden = true
                            self.cameraPreviewView.superview?.isHidden = false
                            self.faceImageViewAnimator = nil
                        } else {
                            self.directionLabel.isHidden = true
                            self.showAnimatedProgressOnImageViewUsingFace(face)
                        }
                    }
                    animator.startAnimation()
                    self.faceImageViewAnimator = animator
                    self.nextAvailableViewChangeTime = CACurrentMediaTime() + animationDuration
                }
            case (.faceFixed, true):
                self.latestMisalignTime = nil
                self.faceOvalView.isHidden = true
                self.headSceneView.isHidden = true
            case (.faceMisaligned, _):
                self.faceOvalView.isHidden = false
                if self.shouldDisplayCGHeadGuidance, let time = self.latestMisalignTime, time + 2.0 < CACurrentMediaTime(), let fromAngle = faceDetectionResult.faceAngle, let toAngle = faceDetectionResult.requestedAngle {
                    let turnDuration: CFTimeInterval = 1.0
                    self.headSceneView.isHidden = false
                    self.cameraPreviewView.superview?.isHidden = true
                    self.nextAvailableViewChangeTime = CACurrentMediaTime() + turnDuration
                    self.headSceneView.animateFromAngle(fromAngle, toAngle: toAngle, duration: turnDuration) { [weak self] in
                        self?.headSceneView.isHidden = true
                        self?.faceOvalView.isHidden = false
                        self?.cameraPreviewView.superview?.isHidden = false
                        self?.latestMisalignTime = nil
                    }
                } else {
                    self.headSceneView.isHidden = true
                }
                if self.latestMisalignTime == nil {
                    self.latestMisalignTime = CACurrentMediaTime()
                }
            case (_, false):
                self.latestMisalignTime = nil
                self.faceOvalView.isHidden = true
                self.headSceneView.isHidden = true
            default:
                self.latestMisalignTime = nil
                self.headSceneView.isHidden = true
                if faceDetectionResult.faceBounds.isNull {
                    self.faceOvalView.isHidden = true
                } else {
                    self.faceOvalView.isHidden = false
                    self.faceOvalView.isStrokeVisible = true
                }
            }
        }
    }
    
    private func showAnimatedProgressOnImageViewUsingFace(_ face: Face) {
        let scale = self.faceImageView.bounds.width / face.bounds.width
        let landmarkTransform = CGAffineTransform(translationX: 0-face.bounds.minX, y: 0-face.bounds.minY).concatenating(CGAffineTransform(scaleX: scale, y: scale))
        let landmarks = face.landmarks.map({ $0.applying(landmarkTransform) })
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = nil
        shapeLayer.strokeColor = sessionTheme.accentColor.withAlphaComponent(0.5).cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = self.faceImageView.bounds.width / 60
        shapeLayer.lineJoin = .round
        let startPoints: [Int] = [0,17,22,27,31,36,42,48,60]
        let closePoints: [Int] = [41,47,59,67]
        let landmarkPath = UIBezierPath()
        for i in 17..<landmarks.count {
            let point = landmarks[i]
            if startPoints.contains(i) {
                landmarkPath.move(to: point)
            } else {
                landmarkPath.addLine(to: point)
            }
            if closePoints.contains(i) {
                landmarkPath.close()
            }
        }
        shapeLayer.path = landmarkPath.cgPath
        self.faceImageView.layer.addSublayer(shapeLayer)
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0.0
        strokeStartAnimation.toValue = 0.9
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0.1
        strokeEndAnimation.toValue = 1.0
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.repeatCount = .infinity
        group.duration = 1.0
        group.animations = [strokeStartAnimation, strokeEndAnimation]
        shapeLayer.add(group, forKey: "stroke")
    }
    
    private func drawArrowFromFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult) {
        if faceDetectionResult.status == .faceMisaligned, let offsetAngle = faceDetectionResult.offsetAngleFromBearing {
            let angle: CGFloat = atan2(CGFloat(0.0-offsetAngle.pitch), CGFloat(offsetAngle.yaw))
            let distance: CGFloat = hypot(offsetAngle.yaw, 0-offsetAngle.pitch) * 2
            self.faceOvalView.isStrokeVisible = false
            self.faceOvalView.isHidden = false
            self.faceOvalView.drawArrow(angle: angle, distance: distance)
        } else {
            self.faceOvalView.isHidden = true
            self.faceOvalView.removeArrow()
        }
    }
    
    private func defaultFaceRectFromFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult) -> CGRect {
        return faceDetectionResult.defaultFaceBounds.translatedToImageSize(self.viewSize)
    }
    
    private func cameraViewTransformFromFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult) -> CGAffineTransform {
        switch faceDetectionResult.status {
        case .faceFixed, .faceAligned, .faceMisaligned:
            guard let faceBounds = self.faceBoundsFromFaceDetectionResult(faceDetectionResult) else {
                return .identity
            }
            let faceRect = self.defaultFaceRectFromFaceDetectionResult(faceDetectionResult)
            let viewScale = faceRect.width / faceBounds.width
            return CGAffineTransform(translationX: faceRect.midX - faceBounds.midX, y: faceRect.midY - faceBounds.midY).concatenating(CGAffineTransform(scaleX: viewScale, y: viewScale))
        default:
            return .identity
        }
    }
    
    private func faceBoundsFromFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult) -> CGRect? {
        if faceDetectionResult.faceBounds.isNull {
            return nil
        }
        let imageSize = CGSize(width: faceDetectionResult.image.width, height: faceDetectionResult.image.height)
        let scale = max(self.viewSize.width / imageSize.width, self.viewSize.height / imageSize.height)
        let transform = CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: self.viewSize.width / 2 - imageSize.width * scale / 2, y: self.viewSize.height / 2 - imageSize.height * scale / 2))
        return faceDetectionResult.faceBounds.applying(transform)
    }
    
    private func maskCameraPreviewFromFaceDetectionResult(_ faceDetectionResult: FaceDetectionResult) {
        let defaultFaceBounds = self.defaultFaceRectFromFaceDetectionResult(faceDetectionResult)
        if !self.isTrackedFaceHighlightEnabled {
            self.maskCameraPreviewWithOval(in: defaultFaceBounds)
        } else {
            switch faceDetectionResult.status {
            case .faceFixed, .faceMisaligned, .faceAligned:
                self.maskCameraPreviewWithOval(in: defaultFaceBounds)
            default:
                if let bounds = self.faceBoundsFromFaceDetectionResult(faceDetectionResult) {
                    self.maskCameraPreviewWithOval(in: bounds)
                } else {
                    self.maskCameraPreviewWithOval(in: defaultFaceBounds)
                }
            }
        }
    }
    
    private func maskCameraPreviewWithOval(in bounds: CGRect) {
        let maskView = self.cameraPreviewView.superview?.mask ?? UIView(frame: bounds)
        maskView.frame = bounds
        maskView.backgroundColor = .clear
        let faceOvalPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: maskView.bounds.size))
        if let maskViewLayer: CAShapeLayer = maskView.layer.sublayers?.first(where: { $0 is CAShapeLayer }) as? CAShapeLayer {
            maskViewLayer.path = faceOvalPath.cgPath
        } else {
            let maskViewLayer = CAShapeLayer()
            maskViewLayer.path = faceOvalPath.cgPath
            maskViewLayer.fillColor = UIColor.white.cgColor
            maskView.layer.addSublayer(maskViewLayer)
        }
        self.cameraPreviewView.superview?.mask = maskView
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
        self.headSceneView?.isHidden = true
        self.faceOvalView?.isHidden = true
        self.faceImageView?.isHidden = true
        self.faceCaptureCount = 0
        self.nextAvailableViewChangeTime = nil
    }
    
    private var isFinishing = false
    
    public func willFinishWithResult(_ result: VerIDSessionResult, completion: @escaping () -> Void) {
        self.directionLabel.isHidden = true
        self.isFinishing = true
        self.cameraPreviewView.superview?.removeFromSuperview()
        self.headSceneView.isHidden = true
        if result.error == nil, let faceCapture = result.faceCaptures.last {
            if self.cameraPosition == .front {
                self.faceImageView.image = faceCapture.faceImage.withHorizontallyFlippedOrientation()
            } else {
                self.faceImageView.image = faceCapture.faceImage
            }
            self.faceOvalView.isHidden = true
            self.onCompletionAnimateView(self.faceImageView, completion: completion)
        } else {
            self.faceImageView.isHidden = true
            self.onCompletionAnimateView(self.faceOvalView, completion: completion)
        }
    }
    
    private func onCompletionAnimateView(_ view: UIView, completion: @escaping () -> Void) {
        if let animator = self.faceImageViewAnimator, animator.isRunning {
            animator.addCompletion { position in
                if position == .end {
                    self.faceImageViewAnimator = nil
                    self.onCompletionAnimateView(view, completion: completion)
                }
            }
            return
        }
        view.isHidden = false
        view.transform = .identity
        let scale: CGFloat = 0.01
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
            view.transform = scaleTransform
        }
        animator.addCompletion { position in
            if position == .end {
                view.isHidden = true
                self.isFinishing = false
                completion()
            }
        }
        animator.startAnimation()
        self.faceImageViewAnimator = animator
    }
    
    // MARK: - Sample Capture
    
    /// Called when the camera returns an image
    ///
    /// - Parameters:
    ///   - output: output by which the image was collected
    ///   - sampleBuffer: image sample buffer
    ///   - connection: capture connection
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let videoWriter = self.videoWriter {
            videoWriter.writeSampleBuffer(sampleBuffer, rotation: self.videoRotation)
        }
        guard let image = try? ImageUtil.imageFromSampleBuffer(sampleBuffer, orientation: self.imageOrientation) else {
            return
        }
        image.isMirrored = cameraPosition == .front
        let imageCapture = ImageCapture(image: image, faceBounds: FaceBounds(viewSize: self.viewSize, faceExtents: self.sessionSettings?.expectedFaceExtents ?? FaceExtents.defaultExtents))
        self.imageCaptureSubject.send(imageCapture)
        self.imagePublisher.onNext((image,FaceBounds(viewSize: self.viewSize, faceExtents: self.sessionSettings?.expectedFaceExtents ?? FaceExtents.defaultExtents)))
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
    
    @IBOutlet private var helpButton: UIImageView!
    
    @IBAction func toggleHelp() {
        self.headSceneView.isHidden = !self.headSceneView.isHidden
        self.faceOvalView.isHidden = !self.faceOvalView.isHidden
    }
}
