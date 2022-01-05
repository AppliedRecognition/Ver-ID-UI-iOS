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

@objc public class ResultViewController: UIViewController, ResultViewControllerProtocol, SpeechDelegatable {
    
    var result: VerIDSessionResult?
    var settings: VerIDSessionSettings?
    public var delegate: ResultViewControllerDelegate?    
    var translatedStrings: TranslatedStrings?
    @IBOutlet weak var textView: UITextView!
    var speechDelegate: SpeechDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem?.title = self.translatedStrings?["Done"]
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

@objc public class SuccessViewController: ResultViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var checkmarkView: UIImageView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        guard let result = self.result else {
            return
        }
        self.navigationItem.title = self.translatedStrings?["Success"]
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
        let text: String?
        if settings is RegistrationSessionSettings {
            text = self.translatedStrings?["Great. You are now registered."]
        } else if settings is AuthenticationSessionSettings {
            text = self.translatedStrings?["Great. You authenticated using your face."]
        } else {
            text = self.translatedStrings?["Great. Session succeeded."]
        }
        if let txt = text {
            self.textView.text = txt
            if var language = self.translatedStrings?.resolvedLanguage {
                if let region = self.translatedStrings?.resolvedRegion {
                    language.append("-\(region)")
                }
                self.speechDelegate?.speak(txt, language: language)
            }
        }
    }
    
    private func showDefaultImage() {
        DispatchQueue.main.async {
            self.imageView.image = UIImage(named: "liveness_detection001", in: ResourceHelper.bundle, compatibleWith: nil)
        }
    }
}

@objc public class FailureViewController: ResultViewController {
    
    var looper: Any?
    
    @IBOutlet weak var videoContainerView: UIView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.translatedStrings?["Failed"]
        let text: String?
        if settings is RegistrationSessionSettings {
            text = self.translatedStrings?["Registration failed"]
        } else if settings is AuthenticationSessionSettings {
            text = self.translatedStrings?["Authentication failed"]
        } else {
            text = self.translatedStrings?["Session failed"]
        }
        if let txt = text {
            self.textView.text = txt
            if var language = self.translatedStrings?.resolvedLanguage {
                if let region = self.translatedStrings?.resolvedRegion {
                    language.append("-\(region)")
                }
                self.speechDelegate?.speak(txt, language: language)
            }
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let bundle = ResourceHelper.bundle
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
