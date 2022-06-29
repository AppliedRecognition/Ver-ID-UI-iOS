//
//  PreviewViewController.swift
//  Preview
//
//  Created by Jakub Dolejs on 07/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import QuickLook
import VerIDCore

class PreviewViewController: UIViewController, QLPreviewingController {
    
    @IBOutlet var imageView: UIImageView!

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let regData = try RegistrationImport.registration(from: url)
                DispatchQueue.main.async {
                    if self.isViewLoaded {
                        self.imageView.image = regData.image
                    }
                    handler(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    handler(error)
                }
            }
        }
    }

}
