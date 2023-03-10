//
//  LoadingViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 09/03/2023.
//  Copyright © 2023 Applied Recognition Inc. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

    @IBOutlet var label: UILabel!
    let steps: [String] = [
        "Loading Ver-ID",
        "Downloading resources",
        "Checking resource integrity",
        "Compiling models",
        "Checking licence",
        "Preparing face detection",
        "Preparing face recognition",
        "Almost done",
        "Any second now"
    ]
    var stepIndex: Int = 0
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            self.label.text = self.steps[self.stepIndex]
            self.stepIndex += 1
            if self.stepIndex >= self.steps.count {
                self.stepIndex = 0
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
    }
}
