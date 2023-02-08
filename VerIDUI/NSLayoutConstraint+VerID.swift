//
//  NSLayoutConstraint+VerID.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 02/02/2023.
//  Copyright © 2023 Applied Recognition Inc. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    func copyWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        
        let originallyActive = self.isActive
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        
        if originallyActive {
            NSLayoutConstraint.activate([newConstraint])
        }
        return newConstraint
    }
}
