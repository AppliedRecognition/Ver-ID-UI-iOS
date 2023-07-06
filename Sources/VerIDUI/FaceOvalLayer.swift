//
//  FaceOvalLayer.swift
//  VerID
//
//  Created by Jakub Dolejs on 16/05/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore

/// Layer that's drawn on the camera preview to outline the detected face
public class FaceOvalLayer: CALayer {
    
    private(set) var ovalBounds: CGRect = CGRect.zero
    private(set) var cutoutBounds: CGRect?
    private(set) var strokeColor: UIColor
    private(set) var backgroundColour: UIColor
    private(set) var angle: CGFloat?
    private(set) var distance: CGFloat?
    
    public var faceLandmarks: [CGPoint] = [] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(layer: Any) {
        if let ovalLayer = layer as? FaceOvalLayer {
            self.strokeColor = ovalLayer.strokeColor
            self.backgroundColour = ovalLayer.backgroundColour
        } else {
            self.strokeColor = UIColor.white
            self.backgroundColour = UIColor(white: 0, alpha: 0.5)
        }
        super.init(layer: layer)
    }
    
    public init(strokeColor: UIColor, backgroundColor: UIColor) {
        self.strokeColor = strokeColor
        self.backgroundColour = backgroundColor
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setOvalBounds(_ ovalBounds: CGRect, cutoutBounds: CGRect?, backgroundColour: UIColor, strokeColour: UIColor, faceLandmarks: [CGPoint], angle: CGFloat?, distance: CGFloat?) {
        self.ovalBounds = ovalBounds
        self.cutoutBounds = cutoutBounds
        self.backgroundColour = backgroundColour
        self.strokeColor = strokeColour
        self.faceLandmarks = faceLandmarks
        self.angle = angle
        self.distance = distance
        self.setNeedsDisplay()
    }
    
    public func setOvalBounds(_ ovalBounds: CGRect, cutoutBounds: CGRect?, angle: CGFloat?, distance: CGFloat?, strokeColour: UIColor? = nil) {
        self.ovalBounds = ovalBounds
        self.cutoutBounds = cutoutBounds
        self.strokeColor = strokeColour ?? self.strokeColor
        self.angle = angle
        self.distance = distance
        self.setNeedsDisplay()
    }
    
    public override func draw(in ctx: CGContext) {
        while let sub = self.sublayers?.first {
            sub.removeFromSuperlayer()
        }
        do {
            let cutout = self.cutoutBounds ?? self.ovalBounds
            let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
            let oval = UIBezierPath(ovalIn: cutout)
            path.append(oval)
            path.usesEvenOddFillRule = true
            let shapeLayer = CAShapeLayer()
            shapeLayer.fillColor = self.backgroundColour.cgColor
            shapeLayer.strokeColor = nil
            shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
            shapeLayer.path = path.cgPath
            self.addSublayer(shapeLayer)
        }
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = ovalBounds.width * 0.038
        shapeLayer.strokeColor = strokeColor.cgColor
        let path = UIBezierPath(ovalIn: ovalBounds)
        shapeLayer.path = path.cgPath
        self.addSublayer(shapeLayer)
        if let angle = self.angle, let distance = self.distance {
            self.drawArrow(in: self.ovalBounds, angle: angle, distance: distance * 1.7)
        }
        if !self.faceLandmarks.isEmpty {
            let landmarkRadius: CGFloat = 2
            self.faceLandmarks.forEach({ landmark in
                let path = UIBezierPath(ovalIn: CGRect(x: landmark.x - landmarkRadius, y: landmark.y - landmarkRadius, width: landmarkRadius * 2, height: landmarkRadius * 2))
                let shapeLayer = CAShapeLayer()
                shapeLayer.fillColor = UIColor.cyan.cgColor
                shapeLayer.strokeColor = nil
                shapeLayer.path = path.cgPath
                self.addSublayer(shapeLayer)
            })
        }
    }
    
    private func drawArrow(in bounds: CGRect, angle: CGFloat, distance: CGFloat) {
        let arrowLength = bounds.width / 5
        let stemLength = min(max(arrowLength * distance, arrowLength * 0.75), arrowLength * 1.7)
        let arrowAngle: CGFloat
        if #available(iOS 10.0, *) {
            arrowAngle = CGFloat(Measurement(value: 40, unit: UnitAngle.degrees).converted(to: .radians).value)
        } else {
            arrowAngle = 40 * CGFloat.pi / 180
        }
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
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = bounds.width * 0.038
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.path = path.cgPath
        self.addSublayer(shapeLayer)
    }
}
