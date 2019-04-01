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
class VerIDRegistrationViewController: VerIDViewController {

    @IBOutlet var detectedFaceStackView: UIStackView!
    
    public init() {
        super.init(nibName: "VerIDRegistrationViewController")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawFaceFromResult(_ faceDetectionResult: FaceDetectionResult, sessionResult: VerIDSessionResult, defaultFaceBounds: CGRect, offsetAngleFromBearing: EulerAngle?) {
        super.drawFaceFromResult(faceDetectionResult, sessionResult: sessionResult, defaultFaceBounds: defaultFaceBounds, offsetAngleFromBearing: offsetAngleFromBearing)
        guard self.detectedFaceStackView.arrangedSubviews.isEmpty || (sessionResult.error == nil && faceDetectionResult.status == .faceAligned) else {
            return
        }
        guard let settings = self.delegate?.settings as? RegistrationSessionSettings else {
            return
        }
        if self.detectedFaceStackView.arrangedSubviews.isEmpty {
            for i in 0..<settings.numberOfResultsToCollect {
                let bearingIndex = i % settings.bearingsToRegister.count
                let bearing = settings.bearingsToRegister[bearingIndex]
                let imageView = createImageView()
                imageView.alpha = 0.5
                detectedFaceStackView.addArrangedSubview(imageView)
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
        for i in 0..<settings.numberOfResultsToCollect {
            guard let imageView = detectedFaceStackView.arrangedSubviews[i] as? UIImageView else {
                return
            }
            for sub in imageView.subviews {
                sub.removeFromSuperview()
            }
            guard imageView.alpha < 1.0 else {
                continue
            }
            guard i < sessionResult.attachments.count else {
                continue
            }
            let viewSize = imageView.frame.size
            let attachment = sessionResult.attachments[i]
            guard let path = attachment.imageURL?.path else {
                continue
            }
            imageView.alpha = 1.0
            DispatchQueue.global().async {
                guard let faceImage = UIImage(contentsOfFile: path) else {
                    DispatchQueue.main.async {
                        imageView.alpha = 0.5
                    }
                    return
                }
                let originalBounds = attachment.face.bounds
                var scaledBoundsSize = CGSize(width: originalBounds.width, height: originalBounds.height)
                if viewSize.width / viewSize.height > originalBounds.width / originalBounds.height {
                    // View is "fatter" match widths
                    scaledBoundsSize.width = viewSize.width
                    scaledBoundsSize.height = viewSize.width / originalBounds.width * originalBounds.height
                } else {
                    scaledBoundsSize.height = viewSize.height
                    scaledBoundsSize.width = viewSize.height / originalBounds.height * originalBounds.width
                }
                let transform = CGAffineTransform(scaleX: scaledBoundsSize.width / originalBounds.width, y: scaledBoundsSize.height / originalBounds.height)
                let bounds = originalBounds.applying(transform)
                let imageTransform = CGAffineTransform(scaleX: scaledBoundsSize.width / originalBounds.width, y: scaledBoundsSize.height / originalBounds.height)
                let scaledImageSize = faceImage.size.applying(imageTransform)
                UIGraphicsBeginImageContext(bounds.size)
                faceImage.draw(in: CGRect(x: 0-bounds.minX, y: 0-bounds.minY, width: scaledImageSize.width, height: scaledImageSize.height))
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                DispatchQueue.main.async {
                    guard self.isViewLoaded else {
                        return
                    }
                    guard let image = image else {
                        imageView.alpha = 0.5
                        return
                    }
                    imageView.alpha = 1.0
                    if settings.cameraPosition == .front {
                        imageView.transform = CGAffineTransform(scaleX: -1, y: 1)
                    }
                    imageView.image = image
                }
            }
            if i+1 == sessionResult.attachments.count {
                let activityIndicatorView = UIActivityIndicatorView(frame: detectedFaceStackView.arrangedSubviews[i].bounds)
                activityIndicatorView.startAnimating()
                imageView.addSubview(activityIndicatorView)
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
        }
        let bundle = Bundle(for: type(of: self))
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
}
