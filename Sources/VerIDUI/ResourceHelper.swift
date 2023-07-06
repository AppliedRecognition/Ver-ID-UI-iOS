//
//  ResourceHelper.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 15/04/2021.
//  Copyright © 2021 Applied Recognition Inc. All rights reserved.
//

import Foundation

public class ResourceHelper {
    
    public static let bundle: Bundle = {
        let frameworkBundle = Bundle(for: ResourceHelper.self)
        guard let veriduiBundleURL = frameworkBundle.url(forResource: "VerIDUIResources", withExtension: "bundle") else {
            preconditionFailure()
        }
        guard let veriduiBundle = Bundle(url: veriduiBundleURL) else {
            preconditionFailure()
        }
        return veriduiBundle
    }()
}
