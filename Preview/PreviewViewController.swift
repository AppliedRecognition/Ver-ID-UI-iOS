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
                let regData = try RegistrationImport.registrationData(from: url)
                guard let image = UIImage(data: regData.profilePicture) else {
                    throw NSError(domain: kVerIDErrorDomain, code: 500, userInfo: [NSLocalizedDescriptionKey:"Failed to read image"])
                }
                DispatchQueue.main.async {
                    if self.isViewLoaded {
                        self.imageView.image = image
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
