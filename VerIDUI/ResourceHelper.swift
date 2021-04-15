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
        guard let frameworkBundle = Bundle(identifier: "com.appliedrec.verid.ui2") else {
            preconditionFailure()
        }
        guard let veriduiBundleURL = frameworkBundle.url(forResource: "VerIDUIResources", withExtension: "bundle") else {
            preconditionFailure()
        }
        guard let veriduiBundle = Bundle(url: veriduiBundleURL) else {
            preconditionFailure()
        }
        return veriduiBundle
    }()
}
