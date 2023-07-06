//
//  SessionTheme.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 30/06/2023.
//  Copyright © 2023 Applied Recognition Inc. All rights reserved.
//

import UIKit

public struct SessionTheme {
    
    public let textColor: UIColor
    public let backgroundColor: UIColor
    public let accentColor: UIColor
    
    public init(textColor: UIColor, backgroundColor: UIColor, accentColor: UIColor) {
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
    }
    
    public static let `default`: SessionTheme = {
        if #available(iOS 13, *) {
            return SessionTheme(textColor: .label, backgroundColor: .systemBackground, accentColor: .white)
        } else {
            return SessionTheme(textColor: .black, backgroundColor: .white, accentColor: .white)
        }
    }()
}
