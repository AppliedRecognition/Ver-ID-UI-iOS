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
    @IBOutlet var overwriteStackView: UIStackView!
    @IBOutlet var overwriteSwitch: UISwitch!
    
    var url: URL?
    weak var delegate: RegistrationImportDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = self.url, let regData = try? RegistrationImport.registrationData(from: url), let profilePic = UIImage(data: regData.profilePicture) else {
            return
        }
        self.imageView.image = profilePic
        DispatchQueue.global().async {
            do {
                let verid = try Globals.verid ?? VerIDFactory(userDefaults: UserDefaults.standard).createVerIDSync()
                if let faces = try? verid.userManagement.facesOfUser(VerIDUser.defaultUserId), !faces.isEmpty {
                    DispatchQueue.main.async {
                        self.overwriteStackView.isHidden = false
                    }
                }
            } catch {
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.delegate?.didCancelImportInRegistrationImportViewController(self)
    }
    
    @IBAction func importRegistration(_ sender: UIBarButtonItem) {
        guard let url = self.url else {
            return
        }
        let overwrite = self.overwriteSwitch.isOn
        DispatchQueue.global().async {
            do {
                let verid = try Globals.verid ?? VerIDFactory(userDefaults: UserDefaults.standard).createVerIDSync()
                if overwrite {
                    verid.userManagement.deleteUsers([VerIDUser.defaultUserId]) { _ in
                        self.importRegistrationFromURL(url, verid: verid)
                    }
                } else {
                    self.importRegistrationFromURL(url, verid: verid)
                }
            } catch {
                DispatchQueue.main.async {
                    self.importFailed(error: error)
                }
            }
        }
        
    }
    
    private func importRegistrationFromURL(_ url: URL, verid: VerID) {
        RegistrationImport.importFromURL(url, verid: verid) { error in
            if let err = error {
                self.importFailed(error: err)
            } else {
                self.importSucceeded(url: url)
            }
        }
    }
    
    private func importSucceeded(url: URL) {
        self.delegate?.registrationImportViewController(self, didImportRegistrationFromURL: url)
//        let alert = UIAlertController(title: "Registration imported", message: nil, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
//            self.delegate?.registrationImportViewController(self, didImportRegistrationFromURL: url)
//        }))
//        self.present(alert, animated: true, completion: nil)
    }
    
    private func importFailed(error: Error) {
        let alert = UIAlertController(title: "Registration import failed", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
            self.delegate?.registrationImportViewController(self, didFailToImportRegistration: error)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

protocol RegistrationImportDelegate: AnyObject {
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didImportRegistrationFromURL url: URL)
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didFailToImportRegistration error: Error)
    func didCancelImportInRegistrationImportViewController(_ registrationImportViewController: RegistrationImportViewController)
}
