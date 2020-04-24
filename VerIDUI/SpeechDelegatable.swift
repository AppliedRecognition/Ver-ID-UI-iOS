//
//  SpeechDelegatable.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 24/04/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation

protocol SpeechDelegatable {
    
    var speechDelegate: SpeechDelegate? { get set }
}
