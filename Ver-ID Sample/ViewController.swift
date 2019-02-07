//
//  ViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 06/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit
import VerIDCore
import VerIDUI

class ViewController: UIViewController, SessionDelegate {
    
    var verid: VerID?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func startSession() {
        guard let verid = self.verid else {
            return
        }
        let settings = LivenessDetectionSessionSettings()
        settings.showResult = true
        settings.includeFaceTemplatesInResult = true
        let session = Session(environment: verid, settings: settings)
        session.delegate = self
        session.start()
    }
    
    func sessionWasCanceled(_ session: Session) {
        
    }
    
    func session(_ session: Session, didFinishWithResult result: SessionResult) {
        
    }
    
    func session(_ session: Session, didFailWithError error: Error) {
        
    }
}

