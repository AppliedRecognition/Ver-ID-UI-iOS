//
//  VerIDRegistrationViewController.swift
//  VerID
//
//  Created by Jakub Dolejs on 07/06/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore

/// Subclass of `VerIDViewController` that displays faces collected during the session
@objc open class VerIDRegistrationViewController: VerIDViewController {

    @IBOutlet var detectedFaceStackView: UIStackView!
    var faceImages: [UIImage] = []
    
    public init() {
        super.init(nibName: "VerIDRegistrationViewController")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        guard let settings = self.sessionSettings as? RegistrationSessionSettings else {
            return
        }
        if self.detectedFaceStackView.arrangedSubviews.isEmpty {
            for i in 0..<settings.faceCaptureCount {
                let bearingIndex = i % settings.bearingsToRegister.count
                let bearing = settings.bearingsToRegister[bearingIndex]
                let imageView = createImageView()
                imageView.alpha = 0.5
                detectedFaceStackView.addArrangedSubview(imageView)
                guard let image = self.imageForBearing(bearing) else {
                    continue
                }
                imageView.image = image
            }
        }
    }
    
    public override func addFaceCapture(_ faceCapture: FaceCapture) {
        self.faceImages.append(faceCapture.faceImage)
        OperationQueue.main.addOperation {
            for i in 0..<self.detectedFaceStackView.arrangedSubviews.count {
                guard let imageView = self.detectedFaceStackView.arrangedSubviews[i] as? UIImageView else {
                    continue
                }
                if i < self.faceImages.count {
                    if self.cameraPosition == .front {
                        imageView.transform = CGAffineTransform(scaleX: -1, y: 1)
                    }
                    imageView.image = self.faceImages[i]
                    imageView.alpha = 1.0
                }
            }
        }
    }
    
    public override func clearOverlays() {
        super.clearOverlays()
        self.faceImages.removeAll()
        guard let settings = self.sessionSettings as? RegistrationSessionSettings else {
            return
        }
        guard self.detectedFaceStackView != nil else {
            return
        }
        for i in 0..<self.detectedFaceStackView.arrangedSubviews.count {
            guard let imageView = self.detectedFaceStackView.arrangedSubviews[i] as? UIImageView else {
                return
            }
            imageView.alpha = 0.5
            imageView.transform = CGAffineTransform.identity
            let bearingIndex = i % settings.bearingsToRegister.count
            let bearing = settings.bearingsToRegister[bearingIndex]
            DispatchQueue.global().async {
                guard let image = self.imageForBearing(bearing) else {
                    return
                }
                DispatchQueue.main.async {
                    if self.isViewLoaded {
                        imageView.image = image
                    }
                }
            }
        }
    }
    
    func createImageView() -> UIImageView {
        let imageView = UIImageView(image: nil)
        let constraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 4/5, constant: 0)
        imageView.addConstraint(constraint)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        return imageView
    }

    private func imageForBearing(_ bearing: Bearing) -> UIImage? {
        let imageName: String
        switch bearing {
        case .straight:
            imageName = "head_thumbnail_straight"
        case .up:
            imageName = "head_thumbnail_up"
        case .rightUp:
            imageName = "head_thumbnail_righ_up"
        case .right:
            imageName = "head_thumbnail_right"
        case .rightDown:
            imageName = "head_thumbnail_right_down"
        case .down:
            imageName = "head_thumbnail_down"
        case .leftDown:
            imageName = "head_thumbnail_left_down"
        case .left:
            imageName = "head_thumbnail_left"
        case .leftUp:
            imageName = "head_thumbnail_left_up"
        @unknown default:
            imageName = "head_thumbnail_straight"
        }
        let bundle = Bundle(for: type(of: self))
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
}
