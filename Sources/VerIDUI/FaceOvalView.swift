//
//  FaceOvalView.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 09/08/2022.
//  Copyright © 2022 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import AVFoundation

public class FaceOvalView: UIView {
    
    public var lineWidthMultiplier: CGFloat = 0.038
    public var strokeColour: UIColor {
        self.sessionTheme.textColor
    }
    public var sessionTheme: SessionTheme = .default {
        didSet {
            self.ovalLayer.strokeColor = self.sessionTheme.textColor.cgColor
        }
    }
    public var pulseDuration: TimeInterval = 1.0
    public var lineWidth: CGFloat {
        self.bounds.width * self.lineWidthMultiplier
    }
    public var isStrokeVisible: Bool = false {
        didSet {
            guard self.isStrokeVisible != oldValue else {
                return
            }
            if self.isStrokeVisible {
                self.ovalLayer.removeAllAnimations()
                self.ovalLayer.isHidden = false
                let pulseAnimation = CABasicAnimation(keyPath: "lineWidth")
                pulseAnimation.fromValue = self.lineWidth
                pulseAnimation.toValue = self.lineWidth * 1.5
                pulseAnimation.repeatCount = .infinity
                pulseAnimation.autoreverses = true
                pulseAnimation.timingFunction = .init(name: .easeInEaseOut)
                pulseAnimation.duration = self.pulseDuration
                self.ovalLayer.add(pulseAnimation, forKey: self.pulseAnimationKey)
            } else {
                self.ovalLayer.removeAllAnimations()
                self.ovalLayer.isHidden = true
            }
        }
    }
    
    public var image: (image: UIImage, mirrored: Bool)? {
        didSet {
            guard let image = self.image else {
                self.imageLayer?.removeAllAnimations()
                self.imageLayer?.removeFromSuperlayer()
                self.imageLayer = nil
                return
            }
            let imageLayer: CALayer
            if let layer = self.imageLayer {
                imageLayer = layer
                imageLayer.removeAllAnimations()
            } else {
                imageLayer = CALayer()
                self.layer.insertSublayer(imageLayer, below: self.ovalLayer)
                self.imageLayer = imageLayer
            }
            imageLayer.frame = self.bounds
            imageLayer.contentsGravity = .resizeAspectFill
            imageLayer.contents = image.image.cgImage
            if image.mirrored {
                imageLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
            }
            let mask = CAShapeLayer()
            mask.path = UIBezierPath(ovalIn: self.bounds).cgPath
            mask.fillColor = UIColor.black.cgColor
            imageLayer.mask = mask
        }
    }
    
    private var ovalLayer: CAShapeLayer!
    private var imageLayer: CALayer?
    private var faceLayer: CAShapeLayer?
    private var arrowLayer: CAShapeLayer?
    private let pulseAnimationKey = "key_pulse"
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addStroke()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addStroke()
    }
    
    private func addStroke() {
        self.ovalLayer = CAShapeLayer()
        self.ovalLayer.fillColor = nil
        self.ovalLayer.strokeColor = self.sessionTheme.textColor.cgColor
        self.ovalLayer.lineWidth = self.lineWidth
        self.ovalLayer.isHidden = !self.isStrokeVisible
        self.layer.addSublayer(self.ovalLayer)
    }
    
    public override func layoutSubviews() {
        self.ovalLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.imageLayer?.frame = self.bounds
        (self.imageLayer?.mask as? CAShapeLayer)?.path = UIBezierPath(ovalIn: self.bounds).cgPath
        super.layoutSubviews()
    }
    
    public func drawArrow(angle: CGFloat, distance: CGFloat) {
        let arrowLength = self.bounds.width / 5
        let stemLength = min(max(arrowLength * distance, arrowLength * 0.75), arrowLength * 1.7)
        let arrowAngle = CGFloat(Measurement(value: 40, unit: UnitAngle.degrees).converted(to: .radians).value)
        let arrowTip = CGPoint(x: bounds.midX + cos(angle) * arrowLength / 2, y: bounds.midY + sin(angle) * arrowLength / 2)
        let arrowPoint1 = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi - arrowAngle) * arrowLength * 0.6, y: arrowTip.y + sin(angle + CGFloat.pi - arrowAngle) * arrowLength * 0.6)
        let arrowPoint2 = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi + arrowAngle) * arrowLength * 0.6, y: arrowTip.y + sin(angle + CGFloat.pi + arrowAngle) * arrowLength * 0.6)
        let arrowStart = CGPoint(x: arrowTip.x + cos(angle + CGFloat.pi) * stemLength, y: arrowTip.y + sin(angle + CGFloat.pi) * stemLength)
        
        let path = UIBezierPath()
        path.move(to: arrowPoint1)
        path.addLine(to: arrowTip)
        path.addLine(to: arrowPoint2)
        path.move(to: arrowTip)
        path.addLine(to: arrowStart)
        
        if self.arrowLayer == nil {
            self.arrowLayer = CAShapeLayer()
            self.layer.addSublayer(self.arrowLayer!)
        }
        self.arrowLayer?.fillColor = nil
        self.arrowLayer?.lineWidth = bounds.width * 0.038
        self.arrowLayer?.strokeColor = self.sessionTheme.accentColor.cgColor
        self.arrowLayer?.lineCap = .round
        self.arrowLayer?.lineJoin = .round
        self.arrowLayer?.path = path.cgPath
    }
    
    public func removeArrow() {
        self.arrowLayer?.removeFromSuperlayer()
        self.arrowLayer = nil
    }
    
    public func drawImage(_ image: UIImage, ofFace face: Face, mirrored: Bool) {
        let imageLayer: CALayer
        if let layer = self.imageLayer {
            imageLayer = layer
            imageLayer.removeAllAnimations()
        } else {
            imageLayer = CALayer()
            self.layer.insertSublayer(imageLayer, below: self.ovalLayer)
            self.imageLayer = imageLayer
        }
        imageLayer.frame = self.bounds
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.contents = image.cgImage
        if mirrored {
            imageLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        }
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(ovalIn: self.bounds).cgPath
        mask.fillColor = UIColor.black.cgColor
        imageLayer.mask = mask
        let faceLayer: CAShapeLayer
        if let layer = self.faceLayer {
            faceLayer = layer
            faceLayer.removeAllAnimations()
            faceLayer.path = nil
        } else {
            faceLayer = CAShapeLayer()
            self.layer.insertSublayer(faceLayer, above: imageLayer)
            self.faceLayer = faceLayer
        }
        let rect = AVMakeRect(aspectRatio: self.bounds.size, insideRect: CGRect(origin: .zero, size: face.bounds.size))
        let scale = self.bounds.width / rect.width
        var transform = CGAffineTransform(translationX: 0-rect.minX*scale, y: 0-rect.minY*scale).concatenating(CGAffineTransform(scaleX: scale, y: scale))
        if mirrored {
            transform = transform.scaledBy(x: -1, y: 1).concatenating(CGAffineTransform(translationX: self.bounds.width, y: 0))
        }
        let offset = CGAffineTransform(translationX: -face.bounds.minX, y: -face.bounds.minY)
        let points = face.landmarks.map { $0.applying(offset).applying(transform) }
        let dotDiameter = self.lineWidth
        let animationDuration = 1.0
        let dotsPath = UIBezierPath()
        let startPoints: [Int] = [0,17,22,27,31,36,42,48,60]
        let closePoints: [Int] = [41,47,59,67]
        for i in 17..<points.count {
            let point = points[i]
            if startPoints.contains(i) {
                dotsPath.move(to: point)
            } else {
                dotsPath.addLine(to: point)
            }
            if closePoints.contains(i) {
                dotsPath.close()
            }
        }
        faceLayer.fillColor = nil
        faceLayer.strokeColor = self.sessionTheme.textColor.cgColor
        faceLayer.lineCap = .round
        faceLayer.lineJoin = .round
        faceLayer.lineWidth = dotDiameter / 2
        faceLayer.path = dotsPath.cgPath
        faceLayer.strokeEnd = 0.0
        
        let imageAnimation = CABasicAnimation(keyPath: "opacity")
        imageAnimation.fromValue = CGFloat(1)
        imageAnimation.toValue = CGFloat(0)
        imageAnimation.fillMode = .forwards
        imageAnimation.isRemovedOnCompletion = false
        imageAnimation.duration = animationDuration
        imageLayer.add(imageAnimation, forKey: "opacity")
        
        let ovalLineWidthAnimation = CABasicAnimation(keyPath: "lineWidth")
        ovalLineWidthAnimation.fromValue = self.lineWidth
        ovalLineWidthAnimation.toValue = self.lineWidth * 0.5
        let ovalOpacityAnimation = CABasicAnimation(keyPath: "opacity")
        ovalOpacityAnimation.fromValue = CGFloat(1)
        ovalOpacityAnimation.toValue = CGFloat(0)
        let ovalAnimationGroup = CAAnimationGroup()
        ovalAnimationGroup.fillMode = .forwards
        ovalAnimationGroup.isRemovedOnCompletion = false
        ovalAnimationGroup.duration = animationDuration
        ovalAnimationGroup.animations = [ovalLineWidthAnimation, ovalOpacityAnimation]
        self.ovalLayer.removeAllAnimations()
        self.ovalLayer.add(ovalAnimationGroup, forKey: "opacity")
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = CGFloat(0)
        strokeAnimation.toValue = CGFloat(1)
        let group = CAAnimationGroup()
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.duration = animationDuration
        group.animations = [strokeAnimation]
        faceLayer.add(group, forKey: "strokeEnd")
    }
    
    public func removeFace() {
        self.faceLayer?.removeFromSuperlayer()
        self.imageLayer?.removeFromSuperlayer()
    }
}
