//
//  RegistrationImportViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 23/11/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore
import RxSwift
import RxVerID

class RegistrationImportViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    var image: UIImage?
    var faceTemplates: [Recognizable]?
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = image
    }
    
    @IBAction func importRegistration(_ sender: UIBarButtonItem) {
        guard let faceTemplates = self.faceTemplates, !faceTemplates.isEmpty else {
            return
        }
        rxVerID.facesOfUser(VerIDUser.defaultUserId)
            .first()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { face in
                if face != nil {
                    let alert = UIAlertController(title: "Overwrite your existing registration?", message: nil, preferredStyle: .actionSheet)
                    alert.popoverPresentationController?.barButtonItem = sender
                    alert.addAction(UIAlertAction(title: "Overwrite", style: .destructive, handler: { _ in
                        rxVerID.deleteUser(VerIDUser.defaultUserId)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onCompleted: {
                                self.addFaceTemplates(faceTemplates)
                            }, onError: nil)
                            .disposed(by: self.disposeBag)
                    }))
                    alert.addAction(UIAlertAction(title: "Amend", style: .default, handler: { _ in
                        self.addFaceTemplates(faceTemplates)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.addFaceTemplates(faceTemplates)
                }
            }, onError: nil)
            .disposed(by: self.disposeBag)
    }
    
    private func importFailed() {
        let alert = UIAlertController(title: "Registration import failed", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
            self.performSegue(withIdentifier: "cancel", sender: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func addFaceTemplates(_ faceTemplates: [Recognizable]) {
        rxVerID.assignFaces(faceTemplates, toUser: VerIDUser.defaultUserId)
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                if let profilePictureURL = profilePictureURL, let imageData = self.image?.jpegData(compressionQuality: 1.0) {
                    try? imageData.write(to: profilePictureURL)
                }
                let alert = UIAlertController(title: "Registration imported", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    self.performSegue(withIdentifier: "cancel", sender: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }, onError: { error in
                self.importFailed()
            })
            .disposed(by: self.disposeBag)
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
