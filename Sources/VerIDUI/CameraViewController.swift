//
//  StillCameraViewController.swift
//  DetRecLib
//
//  Created by Jakub Dolejs on 24/11/2016.
//  Copyright © 2016 Applied Recognition. All rights reserved.
//

import UIKit
import AVFoundation

/// View controller that displays a camera preview
@objc open class CameraViewController: UIViewController {
    
    /// Translated strings
    public var translatedStrings: TranslatedStrings?
    /// Background colour of the camera preview view
    /// - Since: 2.12.1
    public var cameraPreviewBackgroundColor: UIColor = .red {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            self.view.subviews.first?.backgroundColor = self.cameraPreviewBackgroundColor
        }
    }
    
    public let captureSessionQueue = DispatchQueue(label: "com.appliedrec.avcapture")
    private let captureSession = AVCaptureSession()
    private var setupResult: SessionSetupResult = .success
    private(set) var isSessionRunning = false
    private(set) public var cameraPreviewView: CameraPreviewView!
    
    private enum SessionSetupResult {
        case success, notAuthorized, configurationFailed
    }
    
    /// Override this if you want to use other than than the back (selfie) camera
    @objc open var captureDevice: AVCaptureDevice! {
        if #available(iOS 10.0, *) {
            return AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        } else {
            let devices = AVCaptureDevice.devices(for: .video)
            for device in devices {
                if device.position == .front {
                    return device
                }
            }
            return nil
        }
    }
    
    open var videoDataOutput: AVCaptureVideoDataOutput?
    open var metadataOutput: AVCaptureMetadataOutput?
    
    public var avCaptureVideoOrientation: AVCaptureVideoOrientation {
        if #available(iOS 13, *) {
            if let orientation = self.view.window?.windowScene?.interfaceOrientation {
                switch orientation {
                case .portraitUpsideDown:
                    return .portraitUpsideDown
                case .landscapeLeft:
                    return .landscapeLeft
                case .landscapeRight:
                    return .landscapeRight
                default:
                    return .portrait
                }
            } else {
                return .portrait
            }
        } else {
            switch UIApplication.shared.statusBarOrientation {
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            default:
                return .portrait
            }
        }
    }
    
    private (set) public var imageOrientation: CGImagePropertyOrientation = .right
    
    var videoGravity: AVLayerVideoGravity {
        return .resizeAspectFill
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.cameraPreviewView = CameraPreviewView(frame: CGRect(origin: CGPoint.zero, size: self.view.frame.size))
        self.cameraPreviewView.isHidden = true
        self.cameraPreviewView.session = self.captureSession
        let cameraPreviewParent = UIView(frame: CGRect(origin: CGPoint.zero, size: self.view.frame.size))
        cameraPreviewParent.backgroundColor = self.cameraPreviewBackgroundColor
        cameraPreviewParent.addSubview(self.cameraPreviewView)
        cameraPreviewParent.isHidden = true
        self.view.insertSubview(cameraPreviewParent, at: 0)
        
        self.updateImageOrientation()
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            break
        case .notDetermined:
            self.captureSessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [weak self] granted in
                guard let `self` = self else {
                    return
                }
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.captureSessionQueue.resume()
            })
        default:
            setupResult = .notAuthorized
        }
        self.captureSessionQueue.async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateImageOrientation()
        self.updateVideoRotation()
        self.resizeCameraPreviewToViewSize()
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.view, animation: nil, completion: { context in
            if !context.isCancelled {
                self.updateImageOrientation()
                self.resizeCameraPreviewToViewSize()
                if let preview = self.cameraPreviewView {
                    preview.frame.size = size
                    preview.videoPreviewLayer.videoGravity = self.videoGravity
                }
                self.updateVideoRotation()
                if let videoPreviewLayerConnection = self.cameraPreviewView.videoPreviewLayer.connection, videoPreviewLayerConnection.isVideoOrientationSupported {
                    videoPreviewLayerConnection.videoOrientation = self.avCaptureVideoOrientation
                }
            }
        })
    }
    
    private var _videoRotation: CGFloat = 0
    private let videoRotationLock = DispatchSemaphore(value: 1)
    
    private func resizeCameraPreviewToViewSize() {
        self.cameraPreviewView.superview?.frame.size = self.view.frame.size
        self.cameraPreviewView.frame.size = self.view.frame.size
    }
    
    private func updateImageOrientation() {
        let orientation: UIInterfaceOrientation
        if #available(iOS 13, *) {
            orientation = self.view.window?.windowScene?.interfaceOrientation ?? UIApplication.shared.statusBarOrientation
        } else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        switch (orientation, self.captureDevice.position == .front) {
        case (.portraitUpsideDown, true):
            self.imageOrientation = .leftMirrored
        case (.portraitUpsideDown, false):
            self.imageOrientation = .left
        case (.landscapeLeft, true):
            self.imageOrientation = .upMirrored
        case (.landscapeLeft, false):
            self.imageOrientation = .up
        case (.landscapeRight, true):
            self.imageOrientation = .downMirrored
        case (.landscapeRight, false):
            self.imageOrientation = .down
        case (.portrait, true):
            self.imageOrientation = .rightMirrored
        default:
            self.imageOrientation = .right
        }
    }
    
    private func updateVideoRotation() {
        let rotation: CGFloat
        switch (self.avCaptureVideoOrientation, self.captureDevice.position) {
        case (.portrait,.front), (.portrait,.back), (.portrait,.unspecified):
            rotation = 90
        case (.portraitUpsideDown, .front), (.portraitUpsideDown, .back), (.portraitUpsideDown, .unspecified):
            rotation = 270
        case (.landscapeLeft, .back), (.landscapeRight, .front), (.landscapeLeft, .unspecified):
            rotation = 180
        case (.landscapeRight, .back), (.landscapeLeft, .front), (.landscapeRight, .unspecified):
            rotation = 0
        @unknown default:
            rotation = 0
        }
        videoRotationLock.wait()
        defer {
            videoRotationLock.signal()
        }
        _videoRotation = rotation
    }
    
    public var videoRotation: CGFloat {
        videoRotationLock.wait()
        defer {
            videoRotationLock.signal()
        }
        return _videoRotation
    }
    
    private func configureCaptureSession() {
        if self.setupResult != .success {
            return
        }
        
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        
        do {
            guard let camera = self.captureDevice else {
                self.setupResult = .configurationFailed
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            
            guard self.captureSession.canAddInput(videoDeviceInput) else {
                print("Could not add video device input to the session")
                self.setupResult = .configurationFailed
                return
            }
            self.captureSession.addInput(videoDeviceInput)
            
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self, self.isViewLoaded else {
                    return
                }
                self.cameraPreviewView.videoPreviewLayer.videoGravity = self.videoGravity
                self.cameraPreviewView.videoPreviewLayer.connection?.videoOrientation = self.avCaptureVideoOrientation
                self.updateVideoRotation()
            }
        } catch {
            print("Could not create video device input: \(error)")
            self.setupResult = .configurationFailed
            return
        }
        
        if let output = self.metadataOutput {
            guard self.captureSession.canAddOutput(output) else {
                print("Could not add metadata output to the session")
                self.setupResult = .configurationFailed
                return
            }
            self.captureSession.addOutput(output)
        }
        
        if let output = self.videoDataOutput {
            guard self.captureSession.canAddOutput(output) else {
                print("Could not add video data output to the session")
                self.setupResult = .configurationFailed
                return
            }
            self.captureSession.addOutput(output)
        }
        
        self.configureOutputs()
        
        if let output = self.videoDataOutput, output.sampleBufferDelegate == nil {
            self.captureSession.removeOutput(output)
        }
        
        if let output = self.metadataOutput, output.metadataObjectsDelegate == nil {
            self.captureSession.removeOutput(output)
        }
    }
    
    final public func startCamera() {
        self.captureSessionQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.startObservingCameraSession()
                do {
                    try self.captureDevice.lockForConfiguration()
                    if self.captureDevice.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) {
                        self.captureDevice.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    }
                    if self.captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus) {
                        self.captureDevice.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                    } else if self.captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
                        self.captureDevice.focusMode = AVCaptureDevice.FocusMode.autoFocus
                    }
                    if self.captureDevice.isFocusPointOfInterestSupported {
                        self.captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    }
                } catch {
                    
                }
                self.captureDevice.unlockForConfiguration()
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self, self.isViewLoaded else {
                        return
                    }
                    self.cameraBecameAvailable()
                }
            case .notAuthorized:
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self, self.isViewLoaded else {
                        return
                    }
                    let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
                    self.cameraBecameUnavailable(reason: "\(appName) doesn't have permission to use the camera, please change privacy settings.")
                }
                
            case .configurationFailed:
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self, self.isViewLoaded else {
                        return
                    }
                    self.cameraBecameUnavailable(reason: "Unable to configure camera session.")
                }
            }
        }
    }
    
    final public func stopCamera() {
        self.captureSessionQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.setupResult == .success {
                self.captureSession.stopRunning()
                self.isSessionRunning = self.captureSession.isRunning
                self.stopObservingCameraSession()
            }
        }
    }
    
    // MARK: Override in subclasses
    
    open func configureOutputs() {
        let pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        guard self.videoDataOutput != nil else {
            return
        }
//        assert(self.videoDataOutput!.availableVideoPixelFormatTypes.contains(pixelFormatType))
        self.videoDataOutput!.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): pixelFormatType]
    }
    
    private func captureSessionInterrupted() {
        self.cameraPreviewView?.isHidden = true
    }
    
    private func resumeInterruptedCaptureSession() {
        self.captureSessionQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            /*
             The session might fail to start running, e.g., if a phone or FaceTime call is still
             using audio or video. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.captureSession.startRunning()
            self.isSessionRunning = self.captureSession.isRunning
            if !self.captureSession.isRunning {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    let message = self.translatedStrings?["Unable to resume"]
                    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: self.translatedStrings?["OK"], style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            else {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    self.cameraBecameAvailable()
                }
            }
        }
    }
    
    open func cameraBecameUnavailable(reason: String) {
        self.cameraPreviewView.isHidden = true
    }
    
    open func cameraBecameAvailable() {
        self.cameraPreviewView.superview?.isHidden = false
        self.cameraPreviewView.isHidden = false
    }
    
    // MARK: KVO and Notifications
    
    private var captureSessionObservation: NSKeyValueObservation?
    
    private func startObservingCameraSession() {
        self.captureSessionObservation = self.captureSession.observe(\.isRunning, options: [.new]) { session, change in
            guard let isSessionRunning = change.newValue else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self, self.isViewLoaded else {
                    return
                }
                if isSessionRunning {
                    self.cameraBecameAvailable()
                }
                self.isSessionRunning = isSessionRunning
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: self.captureSession)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: self.captureSession)
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: self.captureSession)
    }
    
    private func stopObservingCameraSession() {
        self.captureSessionObservation = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            self.captureSessionQueue.async { [weak self] in
                if self?.isSessionRunning == true {
                    self?.captureSession.startRunning()
                    self?.isSessionRunning = self!.captureSession.isRunning
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.cameraBecameUnavailable(reason: "Capture session error.")
                    }
                }
            }
        } else {
            self.cameraBecameUnavailable(reason: "Capture session error")
        }
    }
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
        }
        self.captureSessionInterrupted()
    }
    
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        self.cameraBecameAvailable()
    }
}
