//
//  FaceOvalLayer.swift
//  VerID
//
//  Created by Jakub Dolejs on 16/05/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit

/// Layer that's drawn on the camera preview to outline the detected face
class FaceOvalLayer: CALayer {
    
    private(set) var ovalBounds: CGRect = CGRect.zero
    private(set) var cutoutBounds: CGRect?
    private(set) var strokeColor: UIColor
    private(set) var backgroundColour: UIColor
    
    init(strokeColor: UIColor, backgroundColor: UIColor) {
        self.strokeColor = strokeColor
        self.backgroundColour = backgroundColor
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setOvalBounds(_ ovalBounds: CGRect, cutoutBounds: CGRect?, strokeColour: UIColor? = nil) {
        self.ovalBounds = ovalBounds
        self.cutoutBounds = cutoutBounds
        if strokeColour != nil {
            self.strokeColor = strokeColour!
        }
        self.setNeedsDisplay()
    }
    
    override func draw(in ctx: CGContext) {
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
    }
}
