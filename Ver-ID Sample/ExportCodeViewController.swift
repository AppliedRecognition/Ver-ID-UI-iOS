//
//  ExportCodeViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 22/11/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit

class ExportCodeViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    var qrCodeImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = qrCodeImage
    }
}
