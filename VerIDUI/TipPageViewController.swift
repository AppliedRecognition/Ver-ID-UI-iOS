//
//  TipPageViewController.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 28/09/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit

class TipPageViewController: UIViewController {
    
    @IBOutlet var textView: UITextView!
    var text: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.text = text
    }

}
