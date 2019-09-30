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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }
    
    override func loadResultImage(_ url: URL, forFace face: Face) {
        guard let settings = self.delegate?.settings as? RegistrationSessionSettings else {
            return
        }
        let group = DispatchGroup()
        for view in detectedFaceStackView.arrangedSubviews {
            guard let imageView = view as? UIImageView else {
                return
            }
            for sub in imageView.subviews {
                sub.removeFromSuperview()
            }
            guard imageView.alpha < 1.0 else {
                continue
            }
            let viewSize = imageView.frame.size
            imageView.alpha = 1.0
            DispatchQueue.global().async {
                guard let faceImage = UIImage(contentsOfFile: url.path) else {
                    DispatchQueue.main.async {
                        imageView.alpha = 0.5
                    }
                    return
                }
                group.enter()
                let originalBounds = face.bounds
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
                    defer {
                        group.leave()
                    }
                    guard self.isViewLoaded else {
                        return
                    }
                    guard let image = image else {
                        imageView.alpha = 0.5
                        return
                    }
                    imageView.alpha = 1.0
                    if settings.useFrontCamera {
                        imageView.transform = CGAffineTransform(scaleX: -1, y: 1)
                    }
                    imageView.image = image
                }
            }
            break
        }
        DispatchQueue.global().async {
            group.wait()
            DispatchQueue.main.async {
                guard self.isViewLoaded else {
                    return
                }
                if let imageView = self.detectedFaceStackView.arrangedSubviews.filter({ $0.alpha == 1.0 }).last {
                    let activityIndicatorView = UIActivityIndicatorView(frame: imageView.bounds)
                    activityIndicatorView.startAnimating()
                    imageView.addSubview(activityIndicatorView)
                }
            }
        }
    }
    
    override func clearOverlays() {
        super.clearOverlays()
        guard let settings = self.delegate?.settings as? RegistrationSessionSettings else {
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
