//
//  RegistrationResultViewController.swift
//  VerID
//
//  Created by Jakub Dolejs on 04/10/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import AVKit
import VerIDCore

/// Protocol for view controller that shows the results of Ver-ID sessions
@objc public protocol ResultViewControllerProtocol: class {
    /// Result view controller delegate
    @objc var delegate: ResultViewControllerDelegate? { get set }
}

/// Result view controller delegate
@objc public protocol ResultViewControllerDelegate: class {
    /// Called when the user cancels the session after reviewing the result
    ///
    /// - Parameter viewController: View controller from which the session was canceled
    @objc func resultViewControllerDidCancel(_ viewController: ResultViewControllerProtocol)
    /// Called when the user acknowledges the session result and finishes the session
    ///
    /// - Parameters:
    ///   - viewController: View controller from which the session was finished
    ///   - result: Result of the session
    @objc func resultViewController(_ viewController: ResultViewControllerProtocol, didFinishWithResult result: VerIDSessionResult)
}

class ResultViewController: UIViewController, ResultViewControllerProtocol {
    
    var result: VerIDSessionResult?
    var settings: VerIDSessionSettings?
    public var delegate: ResultViewControllerDelegate?
    @IBOutlet weak var textView: UITextView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func cancel(_ sender: Any?=nil) {
        self.delegate?.resultViewControllerDidCancel(self)
    }
    
    @IBAction func finish(_ sender: Any?=nil) {
        guard let result = self.result else {
            return
        }
        self.delegate?.resultViewController(self, didFinishWithResult: result)
    }
}

class SuccessViewController: ResultViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var checkmarkView: UIImageView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        guard let result = self.result else {
            return
        }
        DispatchQueue.global().async {
            let facesWithImage = result.attachments.filter({ $0.imageURL != nil })
            if facesWithImage.isEmpty {
                self.showDefaultImage()
                return
            }
            let detectedFace = facesWithImage.filter({ $0.bearing == .straight }).first ?? facesWithImage.first!
            let face = detectedFace.face
            guard let image = UIImage(contentsOfFile: detectedFace.imageURL!.path) else {
                self.showDefaultImage()
                return
            }
            let centre = CGPoint(x: face.leftEye.x + (face.rightEye.x - face.leftEye.x) / 2, y: face.leftEye.y + (face.rightEye.y - face.leftEye.y) / 2)
            let xDist = min(image.size.width - centre.x, centre.x)
            let yDist = min(image.size.height - centre.y, centre.y)
            let cropRect = CGRect(x: centre.x-xDist, y: centre.y-yDist, width: xDist*2, height: yDist*2)
            var croppedImage: UIImage = image
            if !cropRect.isEmpty {
                UIGraphicsBeginImageContext(cropRect.size)
                defer {
                    UIGraphicsEndImageContext()
                }
                image.draw(at: CGPoint(x: 0-cropRect.minX, y: 0-cropRect.minY))
                croppedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            }
            do {
                croppedImage = try ImageUtil.grayscaleImage(from: croppedImage)
            } catch {
                
            }
            if let blurFilter = CIFilter(name: "CIGaussianBlur"), let cropFilter = CIFilter(name: "CICrop") {
                let ciImage = croppedImage.ciImage ?? CIImage(cgImage: croppedImage.cgImage!)
                blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                blurFilter.setValue(16, forKey: kCIInputRadiusKey)
                if let output = blurFilter.outputImage {
                    cropFilter.setValue(output, forKey: kCIInputImageKey)
                    cropFilter.setValue(CIVector(cgRect: ciImage.extent), forKey: "inputRectangle")
                    if let cropped = cropFilter.outputImage {
                        croppedImage = UIImage(ciImage: cropped, scale: 1, orientation: image.imageOrientation)
                    }
                }
            }
            DispatchQueue.main.async {
                self.imageView.image = croppedImage
                self.imageView.contentMode = .scaleAspectFill
                self.checkmarkView.isHidden = false
            }
        }
        if settings is RegistrationSessionSettings {
            self.textView.text = NSLocalizedString("Great. You are now registered.", tableName: nil, bundle: Bundle(for: type(of: self)), value: "Great. You are now registered.", comment: "Displayed when a registration session succeeds.")
        } else if settings is AuthenticationSessionSettings {
            self.textView.text = NSLocalizedString("Great. You authenticated using your face.", tableName: nil, bundle: Bundle(for: type(of: self)), value: "Great. You authenticated using your face.", comment: "Displayed when an authentication session succeeds.")
        } else {
            self.textView.text = NSLocalizedString("Great. Session succeeded.", tableName: nil, bundle: Bundle(for: type(of: self)), value: "Great. Session succeeded.", comment: "Displayed when a liveness detection session succeeds.")
        }
    }
    
    private func showDefaultImage() {
        DispatchQueue.main.async {
            self.imageView.image = UIImage(named: "liveness_detection001", in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
    }
}

class FailureViewController: ResultViewController {
    
    var looper: Any?
    
    @IBOutlet weak var videoContainerView: UIView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            self.navigationItem.title = appName
        }
        if settings is RegistrationSessionSettings {
            self.textView.text = NSLocalizedString("Registration failed", tableName: nil, bundle: Bundle(for: type(of: self)), value: "Registration failed", comment: "Displayed when a registration session fails.")
        } else if settings is AuthenticationSessionSettings {
            self.textView.text = NSLocalizedString("Authentication failed", tableName: nil, bundle: Bundle(for: type(of: self)), value: "Authentication failed", comment: "Displayed when an authentication session fails.")
        } else {
            self.textView.text = NSLocalizedString("Session failed", tableName: nil, bundle: Bundle(for: type(of: self)), value: "Session failed", comment: "Displayed when a liveness detection session fails.")
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let bundle = Bundle(for: type(of: self))
        let density = UIScreen.main.scale
        let densityInt = density > 2 ? 3 : 2
        let videoFileName = settings is RegistrationSessionSettings ? "registration" : "liveness_detection"
        let videoName = String(format: "%@_%d", videoFileName, densityInt)
        guard let url = bundle.url(forResource: videoName, withExtension: "mp4") else {
            return
        }
        if #available(iOS 10, *) {
            let playerItem = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.videoContainerView.bounds
            self.videoContainerView.layer.addSublayer(playerLayer)
            player.play()
        } else {
            let player = AVPlayer(url: url)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.videoContainerView.bounds
            self.videoContainerView.layer.addSublayer(playerLayer)
            player.play()
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 10, *) {
            (self.looper as? AVPlayerLooper)?.disableLooping()
        }
        self.looper = nil
    }
    
    @IBAction func retry(_ sender: Any?) {
        self.navigationController?.popToRootViewController(animated: false)
    }
}
