//
//  ErrorViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 07/12/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit

class ErrorViewController: UIViewController {
    
    @IBOutlet var resetSwitch: UISwitch!

    /// Reload Ver-ID
    ///
    /// - Parameter sender: Sender of the action
    @IBAction func reloadVerID(_ sender: Any?) {
        if resetSwitch.isOn, let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
            UserDefaults.standard.registerVerIDDefaults()
        }
        (UIApplication.shared.delegate as? AppDelegate)?.reload()
    }

}
