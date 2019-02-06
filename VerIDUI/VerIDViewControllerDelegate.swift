//
//  VerIDViewControllerDelegate.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 04/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import Foundation
import CoreMedia
import VerIDCore

protocol VerIDViewControllerDelegate: class {
    
    func viewControllerDidCancel(_ viewController: VerIDViewController)
    
    func viewController(_ viewController: VerIDViewController, didFailWithError error: Error)
    
    func viewController(_ viewController: VerIDViewController, didCaptureSampleBuffer sampleBuffer: CMSampleBuffer, withRotation rotation: CGFloat)
}
