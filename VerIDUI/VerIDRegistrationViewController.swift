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
    
    public init() {
        super.init(nibName: "VerIDRegistrationViewController")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
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
    
    open override func loadResultImage(_ url: URL, forFace face: Face) {
        guard let settings = self.delegate?.settings as? RegistrationSessionSettings else {
            return
        }
        guard let imageView = self.detectedFaceStackView.arrangedSubviews.first(where: { $0 is UIImageView && $0.alpha < 1.0 }) as? UIImageView else {
            return
        }
        func image(at url: URL, croppedToBoundsOfFace face: Face, inSize size: CGSize) -> UIImage? {
            guard let faceImage = UIImage(contentsOfFile: url.path) else {
                return nil
            }
            var scaledBoundsSize = CGSize(width: face.bounds.width, height: face.bounds.height)
            if size.width / size.height > face.bounds.width / face.bounds.height {
                // View is "fatter" match widths
                scaledBoundsSize.width = size.width
                scaledBoundsSize.height = size.width / face.bounds.width * face.bounds.height
            } else {
                scaledBoundsSize.height = size.height
                scaledBoundsSize.width = size.height / face.bounds.height * face.bounds.width
            }
            let transform = CGAffineTransform(scaleX: scaledBoundsSize.width / face.bounds.width, y: scaledBoundsSize.height / face.bounds.height)
            let bounds = face.bounds.applying(transform)
            let scaledImageSize = faceImage.size.applying(transform)
            return UIGraphicsImageRenderer(size: bounds.size).image { _ in
                faceImage.draw(in: CGRect(x: 0-bounds.minX, y: 0-bounds.minY, width: scaledImageSize.width, height: scaledImageSize.height))
            }
        }
        let viewSize = imageView.frame.size
        DispatchQueue.global().async { [weak imageView] in
            guard let faceImage = image(at: url, croppedToBoundsOfFace: face, inSize: viewSize) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let imageView = imageView else {
                    return
                }
                imageView.image = faceImage
                imageView.alpha = 1.0
                if settings.useFrontCamera {
                    imageView.transform = CGAffineTransform(scaleX: -1, y: 1)
                }
            }
        }
    }
    
    public override func clearOverlays() {
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
        let bundle = ResourceHelper.bundle
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
}
