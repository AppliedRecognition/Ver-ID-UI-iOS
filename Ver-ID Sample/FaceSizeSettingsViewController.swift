//
//  FaceSizeSettingsViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 14/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDUI

class FaceSizeSettingsViewController: UIViewController {
    
    @IBOutlet var slider: UISlider!
    @IBOutlet var faceOvalView: UIView!
    var feedbackGenerator: UISelectionFeedbackGenerator?
    var faceOvalLayer: FaceOvalLayer?
    var isLandscape = false
    var lastSliderValue: Int = 10
    var isChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.feedbackGenerator = UISelectionFeedbackGenerator()
        self.slider.addTarget(self, action: #selector(self.didTouchDownOnSlider(_:)), for: .touchDown)
        self.faceOvalLayer = FaceOvalLayer(strokeColor: UIColor.black, backgroundColor: UIColor.clear)
        self.faceOvalView.layer.addSublayer(self.faceOvalLayer!)
        self.faceOvalLayer?.frame = self.faceOvalView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isLandscape = self.faceOvalView.bounds.width > self.faceOvalView.bounds.height
        if self.isLandscape {
            self.lastSliderValue = Int(UserDefaults.standard.faceHeightFraction * 100)
        } else {
            self.lastSliderValue = Int(UserDefaults.standard.faceWidthFraction * 100)
        }
        self.slider.setValue(Float(self.lastSliderValue), animated: false)
        self.updateFaceOval()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            self.save()
        }
    }
    
    @objc func didTouchDownOnSlider(_ slider: UISlider) {
        self.feedbackGenerator?.prepare()
    }
    
    func save() {
        guard self.isChanged else {
            return
        }
        if self.isLandscape {
            UserDefaults.standard.faceHeightFraction = self.slider.value / 100
        } else {
            UserDefaults.standard.faceWidthFraction = self.slider.value / 100
        }
    }
    
    @IBAction func didChangeValueOfSlider(_ slider: UISlider) {
        self.isChanged = true
        let intValue = Int(slider.value)
        if intValue % 5 == 0 && intValue != self.lastSliderValue {
            self.feedbackGenerator?.selectionChanged()
        }
        self.lastSliderValue = intValue
        let newValue = Float((intValue / 5) * 5)
        slider.setValue(newValue, animated: false)
        self.updateFaceOval()
    }
    
    func updateFaceOval() {
        let fraction = CGFloat(self.slider.value/100.0)
        let faceSize: CGSize
        if self.isLandscape {
            let height = self.faceOvalView.bounds.height * fraction
            faceSize = CGSize(width: height * 0.8, height: height)
        } else {
            let width = self.faceOvalView.bounds.width * fraction
            faceSize = CGSize(width: width, height: width * 1.25)
        }
        let faceRect = CGRect(origin: CGPoint(x: self.faceOvalView.bounds.midX - faceSize.width / 2, y: self.faceOvalView.bounds.midY - faceSize.height / 2), size: faceSize)
        self.faceOvalLayer?.setOvalBounds(faceRect, cutoutBounds: nil, angle: nil, distance: nil, strokeColour: nil)
    }
}
