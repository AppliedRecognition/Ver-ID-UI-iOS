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

public protocol ResultViewControllerProtocol: class {
    var delegate: ResultViewControllerDelegate? { get set }
}

public protocol ResultViewControllerDelegate: class {
    func resultViewControllerDidCancel(_ viewController: ResultViewController)
    func resultViewController(_ viewController: ResultViewController, didFinishWithResult result: SessionResult)
}

public class ResultViewController: UIViewController, ResultViewControllerProtocol {
    
    var result: SessionResult?
    var settings: SessionSettings?
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

public class SuccessViewController: ResultViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var checkmarkView: UIImageView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        guard let result = self.result else {
            return
        }
        DispatchQueue.global().async {
            let face: Face
            let image: UIImage
            if let (_face, imageURL) = result.faceImages(withBearing: .straight).first, let _image = UIImage(contentsOfFile: imageURL.path) {
                face = _face
                image = _image
            } else if let (_face, imageURL) = result.faceImages.first, let _image = UIImage(contentsOfFile: imageURL.path) {
                face = _face
                image = _image
            } else {
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(named: "liveness_detection001", in: Bundle(for: type(of: self)), compatibleWith: nil)
                }
                return
            }
            let croppedImage: UIImage? = nil
            // TODO: Crop image
//            if #available(iOS 10.0, *) {
//                croppedImage = ImageUtil.centerImage(image, onEyesOfFace: face).grayscale?.blurred
//            } else {
//                croppedImage = ImageUtil.centerImage(image, onEyesOfFace: face).grayscale
//            }
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
    
}

public class FailureViewController: ResultViewController {
    
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
