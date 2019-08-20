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

/// Ver-ID view controller protocol – displays the Ver-ID session progress
@objc public protocol VerIDViewControllerProtocol: class {
    /// View controller delegate
    @objc var delegate: VerIDViewControllerDelegate? { get set }
    /// Draw a representation of a face detection result collected during Ver-ID session
    ///
    /// - Parameters:
    ///   - faceDetectionResult: Face detection result to relay to the user
    ///   - sessionResult: Current result of the session
    ///   - defaultFaceBounds: Face bounds to display if the result does not contain a face
    ///   - offsetAngleFromBearing: Difference between the angle of the requested bearing and the angle of the detected face – use this to show the user where to move
    @objc func drawFaceFromResult(_ faceDetectionResult: FaceDetectionResult, sessionResult: VerIDSessionResult, defaultFaceBounds: CGRect, offsetAngleFromBearing: EulerAngle?)
    @objc func loadResultImage(_ url: URL, forFace face: Face)
    @objc func clearOverlays()
}

/// Ver-ID SDK's default implementation of the `VerIDViewControllerProtocol`
@objc open class VerIDViewController: CameraViewController, VerIDViewControllerProtocol, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// The view that holds the camera feed.
    @IBOutlet var noCameraLabel: UILabel!
    @IBOutlet var directionLabel: PaddedRoundedLabel!
    @IBOutlet var directionLabelYConstraint: NSLayoutConstraint!
    @IBOutlet var overlayView: UIView!
    
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
    
    private let synth: AVSpeechSynthesizer
    private var lastSpokenText: String?
    
    /// The Ver-ID view controller delegate
    public var delegate: VerIDViewControllerDelegate?
    
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
    
    public init(nibName: String? = nil) {
        let nib = nibName ?? "VerIDViewController"
        self.synth = AVSpeechSynthesizer()
        super.init(nibName: nib, bundle: Bundle(for: type(of: self)))
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
        self.currentImageOrientation = imageOrientation
        let bundle = Bundle(for: type(of: self))
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            self.noCameraLabel.text = String(format: NSLocalizedString("Please go to settings and enable camera in the settings for app.", tableName: nil, bundle: bundle, value: "Please go to settings and enable camera in the settings for %@.", comment: "Instruction displayed to the user if they disable access to the camera"), appName)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        directionLabel.isHidden = false
        let bundle = Bundle(for: type(of: self))
        directionLabel.text = NSLocalizedString("Preparing face detection", tableName: nil, bundle: bundle, value: "Preparing face detection", comment: "Displayed in the camera view when the app is preparing face detection")
        directionLabel.backgroundColor = UIColor.white
        self.startCamera()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.currentImageOrientation = imageOrientation
        coordinator.animateAlongsideTransition(in: self.view, animation: nil) { [weak self] context in
            guard self != nil else {
                return
            }
            if !context.isCancelled {
                // TODO: Set detected face view to
                // self.cameraPreviewView.frame.size
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
        if let pixelFormats = self.videoDataOutput?.availableVideoPixelFormatTypes, pixelFormats.contains(kCVPixelFormatType_32BGRA) {
            self.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
        }
        self.videoDataOutput?.setSampleBufferDelegate(self, queue: self.captureSessionQueue)
    }
    
    override open func cameraBecameUnavailable(reason: String) {
        super.cameraBecameUnavailable(reason: reason)
        self.noCameraLabel.isHidden = false
        self.noCameraLabel.text = reason
    }
    
    // MARK: -
    
    @IBAction func cancel(_ sender: Any? = nil) {
        self.stopCamera()
        self.delegate?.viewControllerDidCancel(self)
    }
    
    private func speakText(_ text: String?) {
        if self.delegate?.settings.speakPrompts == true, let toSay = text, self.lastSpokenText == nil || self.lastSpokenText! != toSay {
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
    
    open override var captureDevice: AVCaptureDevice! {
        guard let delegate = self.delegate else {
            return super.captureDevice
        }
        let camPosition: AVCaptureDevice.Position = delegate.settings.useFrontCamera ? .front : .back
        if #available(iOS 10.0, *) {
            return AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: camPosition)
        } else {
            let devices = AVCaptureDevice.devices(for: .video)
            for device in devices {
                if device.position == camPosition {
                    return device
                }
            }
            return nil
        }
    }
    
    // MARK: - Drawing face guide oval and arrows
    
    /// Draw a face from the face detection result on top of the camera view
    ///
    /// - Parameters:
    ///   - faceDetectionResult: Face detection result
    ///   - sessionResult: Interim session result
    ///   - defaultFaceBounds: Face bounds that will be displayed if no face is detected or before it's inside the oval
    ///   - offsetAngleFromBearing: Angle to use to draw the arrow showing the user where to move
    open func drawFaceFromResult(_ faceDetectionResult: FaceDetectionResult, sessionResult: VerIDSessionResult, defaultFaceBounds: CGRect, offsetAngleFromBearing: EulerAngle?) {
        let bundle = Bundle(for: type(of: self))
        let labelText: String?
        let isHighlighted: Bool
        let ovalBounds: CGRect
        let cutoutBounds: CGRect?
        let faceAngle: EulerAngle?
        let showArrow: Bool
        let spokenText: String?
        if let settings = self.delegate?.settings, sessionResult.attachments.count >= settings.numberOfResultsToCollect {
            labelText = NSLocalizedString("Please wait", tableName: nil, bundle: bundle, value: "Please wait", comment: "Displayed above the face when the session is finishing.")
            isHighlighted = true
            ovalBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
            cutoutBounds = nil
            faceAngle = nil
            showArrow = false
            spokenText = nil
        } else {
            switch faceDetectionResult.status {
            case .faceFixed, .faceAligned:
                labelText = NSLocalizedString("Great, hold it", tableName: nil, bundle: bundle, value: "Great, hold it", comment: "Displayed above the face when the user correctly followed the directions and should stay still.")
                isHighlighted = true
                ovalBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
                cutoutBounds = nil
                faceAngle = nil
                showArrow = false
                spokenText = NSLocalizedString("Hold it", tableName: nil, bundle: bundle, value: "Hold it", comment: "Spoken direction when the user correctly follows the directions and should stay still.")
            case .faceMisaligned:
                labelText = NSLocalizedString("Slowly turn to follow the arrow", tableName: nil, bundle: bundle, value: "Slowly turn to follow the arrow", comment: "Displayed as an instruction during face detection along with an arrow indicating direction")
                isHighlighted = false
                ovalBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
                cutoutBounds = nil
                faceAngle = faceDetectionResult.faceAngle
                showArrow = true
                spokenText = NSLocalizedString("Slowly turn to follow the arrow", tableName: nil, bundle: bundle, value: "Slowly turn to follow the arrow", comment: "")
            case .faceTurnedTooFar:
                labelText = nil
                isHighlighted = false
                ovalBounds = faceDetectionResult.faceBounds.isNull ? defaultFaceBounds : faceDetectionResult.faceBounds
                cutoutBounds = nil
                faceAngle = nil
                showArrow = false
                spokenText = nil
            default:
                labelText = NSLocalizedString("Align your face with the oval", tableName: nil, bundle: bundle, value: "Align your face with the oval", comment: "")
                isHighlighted = false
                ovalBounds = defaultFaceBounds
                cutoutBounds = faceDetectionResult.faceBounds.isNull ? nil : faceDetectionResult.faceBounds
                faceAngle = nil
                showArrow = false
                spokenText = NSLocalizedString("Align your face with the oval", tableName: nil, bundle: bundle, value: "Align your face with the oval", comment: "")
            }
        }
        let transform = self.imageScaleTransformAtImageSize(faceDetectionResult.imageSize)
        self.drawCameraOverlay(bearing: faceDetectionResult.requestedBearing, text: labelText, isHighlighted: isHighlighted, ovalBounds: ovalBounds.applying(transform), cutoutBounds: cutoutBounds?.applying(transform), faceAngle: faceAngle, showArrow: showArrow, offsetAngleFromBearing: offsetAngleFromBearing)
        self.speakText(spokenText)
    }
    
    open func loadResultImage(_ url: URL, forFace face: Face) {
        
    }
    
    public func clearOverlays() {
        
    }
    
    // MARK: - Sample Capture
    
    /// Called when the camera returns an image
    ///
    /// - Parameters:
    ///   - output: output by which the image was collected
    ///   - sampleBuffer: image sample buffer
    ///   - connection: capture connection
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.delegate?.viewController(self, didCaptureSampleBuffer: sampleBuffer, withOrientation: self.currentImageOrientation)
    }
    
    // MARK: -
    
    private func drawCameraOverlay(bearing: Bearing, text: String?, isHighlighted: Bool, ovalBounds: CGRect, cutoutBounds: CGRect?, faceAngle: EulerAngle?, showArrow: Bool, offsetAngleFromBearing: EulerAngle?) {
        self.directionLabel.textColor = isHighlighted ? highlightedTextColour : neutralTextColour
        self.directionLabel.text = text
        self.directionLabel.backgroundColor = isHighlighted ? highlightedColour : neutralColour
        self.directionLabel.isHidden = text == nil
        
        self.directionLabelYConstraint.constant = max(ovalBounds.minY - self.directionLabel.frame.height - 16, 0)
        
        let angle: CGFloat?
        let distance: CGFloat?
        if showArrow, let offsetAngle = offsetAngleFromBearing {
            angle = atan2(CGFloat(0.0-offsetAngle.pitch), CGFloat(offsetAngle.yaw))
            distance = hypot(offsetAngle.yaw, 0-offsetAngle.pitch) * 2;
        } else {
            angle = nil
            distance = nil
        }
        
        self.faceOvalLayer.setOvalBounds(ovalBounds, cutoutBounds: cutoutBounds, angle: angle, distance: distance, strokeColour: isHighlighted ? highlightedColour : neutralColour)
    }
    
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
    
    /// Affine transform to be used when scaling detected faces to fit the display
    ///
    /// - Parameter size: Size of the image where the face was detected
    /// - Returns: Affine transform to be used when scaling detected faces to fit the display
    private func imageScaleTransformAtImageSize(_ size: CGSize) -> CGAffineTransform {
        let rect = AVMakeRect(aspectRatio: self.overlayView.bounds.size, insideRect: CGRect(origin: CGPoint.zero, size: size))
        let scale = self.overlayView.bounds.width / rect.width
        var scaleTransform: CGAffineTransform = CGAffineTransform(translationX: 0-rect.minX, y: 0-rect.minY).concatenating(CGAffineTransform(scaleX: scale, y: scale))
        if self.captureDevice.position == .front {
            scaleTransform = scaleTransform.concatenating(CGAffineTransform(scaleX: -1, y: 1)).concatenating(CGAffineTransform(translationX: self.overlayView.bounds.width, y: 0))
        }
        return scaleTransform
    }
}
