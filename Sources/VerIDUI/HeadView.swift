//
//  HeadView.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 01/09/2022.
//  Copyright © 2022 Applied Recognition Inc. All rights reserved.
//

import UIKit
import SceneKit
import VerIDCore

public class HeadView: SCNView {
    
    @objc dynamic private(set) public var isAnimating: Bool = false
    private var animationObservers: [NSKeyValueObservation] = []
    
    private let ovalMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.black.cgColor
        return layer
    }()
    
    public var headColor: UIColor = .gray {
        didSet {
            self.scene?.rootNode.childNodes.first?.geometry?.materials.forEach { material in
                material.diffuse.contents = self.headColor
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    deinit {
        for observer in self.animationObservers {
            observer.invalidate()
        }
        self.animationObservers.removeAll()
    }
    
    private func setup() {
        if #available(iOS 13, *) {
            self.backgroundColor = .secondarySystemBackground
        } else {
            self.backgroundColor = UIColor(named: "systemSecondaryBackground", in: ResourceHelper.bundle, compatibleWith: nil) ?? UIColor.gray
        }
        guard MDLAsset.canImportFileExtension("obj") else {
            return
        }
        guard let modelURL = ResourceHelper.bundle.url(forResource: "head1", withExtension: "obj") else {
            return
        }
        self.scene = try? SCNScene(url: modelURL)
        if let headNode = self.scene?.rootNode.childNodes.first {
            headNode.geometry?.materials.forEach { material in
                material.diffuse.contents = self.headColor
            }
            let cameraNode = SCNNode()
            let camera = SCNCamera()
            camera.name = "headCam"
            camera.projectionDirection = .vertical
            camera.fieldOfView = 30
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
            cameraNode.camera = camera
            self.pointOfView = cameraNode
            let lightNode = SCNNode()
            let headConstraint = SCNLookAtConstraint(target: headNode)
            lightNode.constraints = [headConstraint]
            lightNode.light = SCNLight()
            lightNode.light?.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
            self.scene?.rootNode.addChildNode(cameraNode)
            self.scene?.rootNode.addChildNode(lightNode)
        }
        self.layer.mask = self.ovalMaskLayer
    }
    
    public override func layoutSubviews() {
        self.ovalMaskLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        super.layoutSubviews()
    }
    
    public func animateFromAngle(_ fromAngle: EulerAngle, toAngle: EulerAngle, duration: TimeInterval, completion: @escaping () -> Void) {
        guard !self.isAnimating else {
            completion()
            return
        }
        guard let rootNode = self.scene?.rootNode else {
            completion()
            return
        }
        guard let headNode = rootNode.childNodes.first else {
            completion()
            return
        }
        guard let cameraNode = rootNode.childNodes.first(where: { $0.camera?.name == "headCam" }), let camera = cameraNode.camera else {
            completion()
            return
        }
        
        let topLeft = self.projectPoint(SCNVector3(-headNode.boundingSphere.radius, -headNode.boundingSphere.radius/2, 0))
        let bottomRight = self.projectPoint(SCNVector3(headNode.boundingSphere.radius, headNode.boundingSphere.radius, 0))
        camera.fieldOfView /= self.bounds.height / CGFloat(bottomRight.x - topLeft.x)
        
        let index = self.animationObservers.count
        let observation = self.observe(\.isAnimating, options: [.new]) { [weak self] view, change in
            if change.newValue == false {
                self?.animationObservers[index].invalidate()
                self?.animationObservers.remove(at: index)
                completion()
            }
        }
        self.animationObservers.append(observation)
        let yawAnimation = CABasicAnimation(keyPath: "eulerAngles.y")
        yawAnimation.fromValue = Float(Measurement(value: fromAngle.yaw, unit: UnitAngle.degrees).converted(to: .radians).value)
        yawAnimation.toValue = Float(Measurement(value: toAngle.yaw, unit: UnitAngle.degrees).converted(to: .radians).value)
        let pitchAnimation = CABasicAnimation(keyPath: "eulerAngles.x")
        pitchAnimation.fromValue = Float(Measurement(value: fromAngle.pitch, unit: UnitAngle.degrees).converted(to: .radians).value)
        pitchAnimation.toValue = Float(Measurement(value: toAngle.pitch, unit: UnitAngle.degrees).converted(to: .radians).value)
        let animation = CAAnimationGroup()
        animation.delegate = self
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        animation.animations = [yawAnimation, pitchAnimation]
        headNode.removeAnimation(forKey: "rotation")
        headNode.addAnimation(animation, forKey: "rotation")
    }
    
    public func stopAnimating() {
        guard let headNode = self.scene?.rootNode.childNodes.first else {
            return
        }
        headNode.removeAnimation(forKey: "rotation")
    }
}

extension HeadView: CAAnimationDelegate {
    
    public func animationDidStart(_ anim: CAAnimation) {
        self.isAnimating = true
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.isAnimating = false
    }
}
