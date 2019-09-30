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
    
    let captureSessionQueue = DispatchQueue(label: "com.appliedrec.avcapture")
    private let captureSession = AVCaptureSession()
    private var cameraInput: AVCaptureDeviceInput!
    private var setupResult: SessionSetupResult = .success
    private(set) var isSessionRunning = false
    private(set) internal var cameraPreviewView: CameraPreviewView!
    
    private enum SessionSetupResult {
        case success, notAuthorized, configurationFailed
    }
    
    private var observeSession: Bool = false {
        didSet {
            if oldValue != observeSession && observeSession {
                self.captureSession.addObserver(self, forKeyPath: "running", options: .new, context: &self.sessionRunningObserveContext)
                
                NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: self.captureSession)
                
                /*
                 A session can only run when the app is full screen. It will be interrupted
                 in a multi-app layout, introduced in iOS 9, see also the documentation of
                 AVCaptureSessionInterruptionReason. Add observers to handle these session
                 interruptions and show a preview is paused message. See the documentation
                 of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
                 */
                NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: self.captureSession)
                NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: self.captureSession)
            } else if oldValue != observeSession {
                NotificationCenter.default.removeObserver(self)
                
                self.captureSession.removeObserver(self, forKeyPath: "running", context: &sessionRunningObserveContext)
            }
        }
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
    
    var videoDataOutput: AVCaptureVideoDataOutput?
    var metadataOutput: AVCaptureMetadataOutput?
    
    var avCaptureVideoOrientation: AVCaptureVideoOrientation {
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
    
    private (set) internal var imageOrientation: CGImagePropertyOrientation = .right
    
    var videoGravity: AVLayerVideoGravity {
        return .resizeAspectFill
    }
    
    deinit {
        self.observeSession = false
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.cameraPreviewView = CameraPreviewView(frame: CGRect(origin: CGPoint.zero, size: self.view.frame.size))
        self.cameraPreviewView.isHidden = true
        self.cameraPreviewView.session = self.captureSession
        self.view.insertSubview(self.cameraPreviewView, at: 0)
        
        switch UIApplication.shared.statusBarOrientation {
        case .portraitUpsideDown:
            self.imageOrientation = .left
        case .landscapeLeft:
            self.imageOrientation = .up
        case .landscapeRight:
            self.imageOrientation = .down
        default:
            self.imageOrientation = .right
        }
        
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
        self.cameraPreviewView.frame.size = self.view.frame.size
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.view, animation: nil, completion: { context in
            if !context.isCancelled {
                switch UIApplication.shared.statusBarOrientation {
                case .portraitUpsideDown:
                    self.imageOrientation = .left
                case .landscapeLeft:
                    self.imageOrientation = .up
                case .landscapeRight:
                    self.imageOrientation = .down
                default:
                    self.imageOrientation = .right
                }
                if let preview = self.cameraPreviewView {
                    preview.frame.size = size
                    preview.videoPreviewLayer.videoGravity = self.videoGravity
                }
                self.updateVideoRotation()
                if let videoPreviewLayerConnection = self.cameraPreviewView.videoPreviewLayer.connection {
                    videoPreviewLayerConnection.videoOrientation = self.avCaptureVideoOrientation
                }
            }
        })
    }
    
    private var _videoRotation: CGFloat = 0
    private let videoRotationLock = DispatchSemaphore(value: 1)
    
    private func updateVideoRotation() {
        let rotation: CGFloat
        switch self.avCaptureVideoOrientation {
        case .portrait:
            rotation = 90
        case .portraitUpsideDown:
            rotation = 270
        case .landscapeLeft:
            rotation = 180
        case .landscapeRight:
            rotation = 0
        @unknown default:
            fatalError()
        }
        videoRotationLock.wait()
        defer {
            videoRotationLock.signal()
        }
        _videoRotation = rotation
    }
    
    var videoRotation: CGFloat {
        var rotation: CGFloat = 0
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
        
        self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        do {
            guard let camera = self.captureDevice else {
                setupResult = .configurationFailed
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            
            guard self.captureSession.canAddInput(videoDeviceInput) else {
                print("Could not add video device input to the session")
                self.setupResult = .configurationFailed
                return
            }
            self.captureSession.addInput(videoDeviceInput)
            self.cameraInput = videoDeviceInput
            
            DispatchQueue.main.async {
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
        self.captureSessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.observeSession = true
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
                DispatchQueue.main.async {
                    self.cameraBecameAvailable()
                }
            case .notAuthorized:
                DispatchQueue.main.async {
                    let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
                    self.cameraBecameUnavailable(reason: "\(appName) doesn't have permission to use the camera, please change privacy settings.")
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    self.cameraBecameUnavailable(reason: "Unable to configure camera session.")
                }
            }
        }
    }
    
    final public func stopCamera() {
        self.captureSessionQueue.async {
            if self.setupResult == .success {
                self.captureSession.stopRunning()
                self.isSessionRunning = self.captureSession.isRunning
                self.observeSession = false
            }
        }
    }
    
    // MARK: Override in subclasses
    
    open func configureOutputs() {
        let pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        guard self.videoDataOutput != nil else {
            return
        }
        assert(self.videoDataOutput!.availableVideoPixelFormatTypes.contains(pixelFormatType))
        self.videoDataOutput!.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): pixelFormatType]
    }
    
    private func captureSessionInterrupted() {
        self.cameraPreviewView.isHidden = true
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
        self.cameraPreviewView.isHidden = false
    }
    
    // MARK: KVO and Notifications
    
    private var sessionRunningObserveContext = 0
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.sessionRunningObserveContext {
            let newValue = change?[.newKey] as AnyObject?
            guard let isSessionRunning = newValue?.boolValue else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                if isSessionRunning {
                    self?.cameraBecameAvailable()
                }
                self?.isSessionRunning = isSessionRunning
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc private func sessionRuntimeError(notification: NSNotification) {
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
    
    @objc private func sessionWasInterrupted(notification: NSNotification) {
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
    
    @objc private func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        self.cameraBecameAvailable()
    }
}
