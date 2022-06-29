//
//  ContinuousLivenessViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 07/08/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import AVFoundation
import VerIDCore
import VerIDUI
import RxSwift

class ContinuousLivenessViewController: CameraViewController, AVCaptureVideoDataOutputSampleBufferDelegate, VerIDSessionDelegate {
    
    var currentImageOrientation: CGImagePropertyOrientation = .right
    var faceDetectionSubscription: Disposable?
    let captureSessionQueue = DispatchQueue(label: "com.appliedrec.avcapture")
    let imagePublisher = PublishSubject<Image>()
    let disposeBag = DisposeBag()
    @IBOutlet var cameraOverlay: UIView!
    @IBOutlet var instructionLabel: UILabel!
    @IBOutlet var successLabel: UILabel!
    
    override var captureDevice: AVCaptureDevice! {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoDataOutput = AVCaptureVideoDataOutput()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.instructionLabel.text = "Please step in front of the camera"
        self.runFaceDetection(until: { $0 }, completion: {
            self.startSession()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.faceDetectionSubscription != nil {
            self.faceDetectionSubscription?.dispose()
            self.faceDetectionSubscription = nil
        }
        self.videoDataOutput?.setSampleBufferDelegate(nil, queue: nil)
        self.stopCamera()
    }
    
    @objc func startSession() {
        self.removeRetryButton()
        self.faceDetectionSubscription?.dispose()
        guard let verid = Globals.verid else {
            return
        }
        let session = VerIDSession(environment: verid, settings: LivenessDetectionSessionSettings())
        session.delegate = self
        session.start()
    }
    
    func runFaceDetection(until: @escaping (_ faceDetected: Bool) -> Bool, completion: @escaping () -> Void) {
        if self.faceDetectionSubscription != nil {
            self.faceDetectionSubscription?.dispose()
        }
        guard let verid = Globals.verid else {
            return
        }
        let faceTracking = verid.faceDetection.startFaceTracking()
        self.faceDetectionSubscription = self.imagePublisher
            .skip(5)
            .map({
                let face = try? faceTracking.trackFaceInImage($0)
                return face != nil
            })
            .takeUntil(.inclusive , predicate: until)
            .ignoreElements()
            .do(onSubscribe: {
                self.startCamera()
            }, onDispose: {
                self.stopCamera()
            })
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                completion()
            }, onError: { error in
                NSLog("Face detection failed: %@", error.localizedDescription)
            })
        self.faceDetectionSubscription?.disposed(by: self.disposeBag)
    }
    
    override func configureOutputs() {
        super.configureOutputs()
        self.videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        let pixelFormat: OSType = kCVPixelFormatType_32BGRA
        self.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:pixelFormat]
        self.videoDataOutput?.setSampleBufferDelegate(self, queue: self.captureSessionQueue)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.faceDetectionSubscription != nil {
            guard let image = try? VerIDImage(sampleBuffer: sampleBuffer, orientation: self.currentImageOrientation).provideVerIDImage() else {
                return
            }
            image.isMirrored = true
            self.imagePublisher.onNext(image)
        }
    }
    
    // MARK: - VerIDSessionDelegate
    
    func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        if result.error == nil {
            self.successLabel.isHidden = false
            self.instructionLabel.text = "Please step away from the camera"
        } else {
            self.instructionLabel.text = "Session failed"
            self.addRetryButton()
        }
        self.runFaceDetection(until: { !$0 }, completion: {
            self.successLabel.isHidden = true
            self.removeRetryButton()
            self.instructionLabel.text = "Please step in front of the camera"
            self.runFaceDetection(until: { $0 }, completion: {
                self.startSession()
            })
        })
    }
    
    func didCancelSession(_ session: VerIDSession) {
        self.instructionLabel.text = "Session cancelled"
        self.addRetryButton()
        self.runFaceDetection(until: { !$0 }, completion: {
            self.removeRetryButton()
            self.instructionLabel.text = "Please step in front of the camera"
            self.runFaceDetection(until: { $0 }, completion: {
                self.startSession()
            })
        })
    }
    
    // MARK: -
    
    func addRetryButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Try again", style: .plain, target: self, action: #selector(self.startSession))
    }
    
    func removeRetryButton() {
        self.navigationItem.rightBarButtonItem = nil
    }
}
