//
//  IdentificationResultViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 23/10/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit

class IdentificationResultViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var messageLabel: UILabel!
    
    var image: UIImage?
    var message: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.image
        self.messageLabel.text = self.message
    }

    @IBAction func close() {
        self.dismiss(animated: true)
    }

}
