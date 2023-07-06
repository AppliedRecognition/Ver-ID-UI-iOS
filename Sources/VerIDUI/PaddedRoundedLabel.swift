//
//  PaddedRoundedLabel.swift
//  VerID
//
//  Created by Jakub Dolejs on 16/05/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit

/// Label with padding and rounded corners
class PaddedRoundedLabel: UILabel {
    
    var verticalInset: CGFloat = 4.0
    var horizontalInset: CGFloat = 4.0
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += verticalInset * 2
            contentSize.width += horizontalInset * 2
            return contentSize
        }
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
        super.drawText(in: rect.inset(by: insets))
    }
}
