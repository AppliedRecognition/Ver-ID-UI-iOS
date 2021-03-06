//
//  SpeechDelegate.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 24/04/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation

protocol SpeechDelegate: AnyObject {
    
    func speak(_ text: String, language: String)
}
