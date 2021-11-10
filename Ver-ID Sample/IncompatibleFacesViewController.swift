//
//  IncompatibleFacesViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 10/11/2021.
//  Copyright © 2021 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

class IncompatibleFacesViewController: UIViewController {
    
    var verid: VerID?
    
    @IBAction func deleteIncompatibleFaces() {
        (UIApplication.shared.delegate as? AppDelegate)?.reload(deleteIncompatibleFaces: true)
    }
}
