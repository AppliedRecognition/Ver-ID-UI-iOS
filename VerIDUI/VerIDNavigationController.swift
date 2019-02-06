//
//  VerIDNavigationController.swift
//  VerID
//
//  Created by Jakub Dolejs on 03/10/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore

class VerIDNavigationController: UINavigationController {
    
    var verIDDelegate: VerIDNavigationControllerDelegate?
    
    func finish(result: SessionResult) {
        DispatchQueue.main.async {
            self.verIDDelegate?.didFinishSessionWithResult(result)
        }
    }
}

protocol VerIDNavigationControllerDelegate {
    func didFinishSessionWithResult(_ result: SessionResult)
}
