//
//  RegistrationImportViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 23/11/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore

class RegistrationImportViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    var image: UIImage?
    var faceTemplates: [Recognizable]?
//    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = image
    }
    
    @IBAction func importRegistration(_ sender: UIBarButtonItem) {
        guard let faceTemplates = self.faceTemplates, !faceTemplates.isEmpty else {
            return
        }
        guard let verid = Globals.verid else {
            return
        }
        if let faces = try? verid.userManagement.facesOfUser(VerIDUser.defaultUserId), !faces.isEmpty {
            let alert = UIAlertController(title: "Overwrite your existing registration?", message: nil, preferredStyle: .actionSheet)
            alert.popoverPresentationController?.barButtonItem = sender
            alert.addAction(UIAlertAction(title: "Overwrite", style: .destructive, handler: { _ in
                verid.userManagement.deleteUsers([VerIDUser.defaultUserId]) { _ in
                    self.addFaceTemplates(faceTemplates)
                }
            }))
            alert.addAction(UIAlertAction(title: "Amend", style: .default, handler: { _ in
                self.addFaceTemplates(faceTemplates)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.addFaceTemplates(faceTemplates)
        }
    }
    
    private func importFailed() {
        let alert = UIAlertController(title: "Registration import failed", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
            self.performSegue(withIdentifier: "cancel", sender: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func addFaceTemplates(_ faceTemplates: [Recognizable]) {
        guard let verid = Globals.verid else {
            return
        }
        verid.userManagement.assignFaces(faceTemplates, toUser: VerIDUser.defaultUserId) { error in
            guard error == nil else {
                self.importFailed()
                return
            }
            if let profilePictureURL = Globals.profilePictureURL, let imageData = self.image?.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: profilePictureURL)
            }
            let alert = UIAlertController(title: "Registration imported", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                self.performSegue(withIdentifier: "cancel", sender: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
