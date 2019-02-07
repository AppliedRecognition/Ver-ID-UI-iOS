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

public protocol VerIDViewControllerDelegate: class {
    
    func viewControllerDidCancel(_ viewController: VerIDViewControllerProtocol)
    
    func viewController(_ viewController: VerIDViewControllerProtocol, didFailWithError error: Error)
    
    func viewController(_ viewController: VerIDViewControllerProtocol, didCaptureSampleBuffer sampleBuffer: CMSampleBuffer, withRotation rotation: CGFloat)
}
