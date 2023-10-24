//
//  DiagnosticUploadPermissionDialog.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 23/10/2023.
//  Copyright © 2023 Applied Recognition Inc. All rights reserved.
//

import UIKit

class DiagnosticUploadPermissionDialog: UIViewController {
    
    var onDeny: ((Bool) -> Void)?
    var onAllow: ((Bool) -> Void)?
    
    @IBOutlet var rememberSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func allow() {
        self.dismiss(animated: true) {
            self.onAllow?(self.rememberSwitch.isOn)
            self.onAllow = nil
        }
    }
    
    @IBAction func deny() {
        self.dismiss(animated: true) {
            self.onDeny?(self.rememberSwitch.isOn)
            self.onDeny = nil
        }
    }
}
