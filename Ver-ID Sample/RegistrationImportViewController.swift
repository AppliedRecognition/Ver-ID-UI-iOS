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
    var environment: VerID?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = image
    }
    
    @IBAction func importRegistration(_ sender: UIBarButtonItem) {
        guard let faceTemplates = self.faceTemplates, !faceTemplates.isEmpty else {
            return
        }
        guard let environment = self.environment else {
            return
        }
        do {
            if try environment.userManagement.users().contains(VerIDUser.defaultUserId) {
                let alert = UIAlertController(title: "Overwrite your existing registration?", message: nil, preferredStyle: .actionSheet)
                alert.popoverPresentationController?.barButtonItem = sender
                alert.addAction(UIAlertAction(title: "Overwrite", style: .destructive, handler: { _ in
                    environment.userManagement.deleteUsers([VerIDUser.defaultUserId]) { error in
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
        } catch {
            
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
        guard let environment = self.environment else {
            return
        }
        environment.userManagement.assignFaces(faceTemplates, toUser: VerIDUser.defaultUserId) { error in
            if error != nil {
                self.importFailed()
                return
            }
            if let profilePictureURL = (UIApplication.shared.delegate as? AppDelegate)?.profilePictureURL, let imageData = self.image?.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: profilePictureURL)
            }
            let alert = UIAlertController(title: "Registration imported", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                self.performSegue(withIdentifier: "cancel", sender: nil)
            }))
            self.present(alert, animated: true, completion: nil)
            
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
