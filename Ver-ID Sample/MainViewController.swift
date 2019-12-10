//
//  MainViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 04/10/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore
import VerIDUI
import RxVerID
import RxSwift

class MainViewController: UIViewController, QRCodeScanViewControllerDelegate {
    
    // MARK: - Interface builder views

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var importButton: UIButton!
    
    // MARK: -
    
    /// Settings to use for user registration
    var registrationSettings: RegistrationSessionSettings {
        let settings = RegistrationSessionSettings(userId: VerIDUser.defaultUserId, showResult: true)
        let yawThreshold = UserDefaults.standard.float(forKey: "yawThreshold")
        let pitchThreshold = UserDefaults.standard.float(forKey: "pitchThreshold")
        let numberOfFacesToRegister = UserDefaults.standard.integer(forKey: "numberOfFacesToRegister")
        settings.yawThreshold = CGFloat(yawThreshold)
        settings.pitchThreshold = CGFloat(pitchThreshold)
        settings.numberOfResultsToCollect = numberOfFacesToRegister
        return settings
    }
    
    let disposeBag = DisposeBag()
    
    // MARK: - Override from UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUserDisplay()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if appDelegate.registrationUploading == nil {
            // Remove the export button if the app delegate can't handle face template exporting
            self.navigationItem.leftBarButtonItem = nil
        }
        if appDelegate.registrationDownloading == nil {
            // Hide the import button if the app delegate can't handle face template importing
            self.importButton.isHidden = true
        }
    }
    
    // MARK: -
    
    /// Find out whether the user registered their face. If the user is registered display their profile photo and enable the Authenticate button.
    func updateUserDisplay() {
        guard let url = (UIApplication.shared.delegate as? AppDelegate)?.profilePictureURL, let image = UIImage(contentsOfFile: url.path) else {
            return
        }
        self.imageView.layer.cornerRadius = self.imageView.bounds.width / 2
        self.imageView.layer.masksToBounds = true
        self.imageView.image = image
    }
    
    // MARK: - Button actions
    
    /// Reset the registration
    ///
    /// This will delete the registered user
    /// - Parameter sender: Sender of the action
    @IBAction func reset(_ sender: UITapGestureRecognizer) {
        assert(sender.view != nil)
        let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender.view
//        alert.popoverPresentationController?.sourceRect = (sender as? UIView)?.frame
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Unregister", style: .destructive, handler: { _ in
            rxVerID.deleteUser(VerIDUser.defaultUserId)
                .subscribe(onCompleted: {
                    guard let storyboard = self.storyboard else {
                        return
                    }
                    guard let introViewController = storyboard.instantiateViewController(withIdentifier: "intro") as? IntroViewController else {
                        return
                    }
                    self.navigationController?.setViewControllers([introViewController], animated: false)
                }, onError: { error in
                    
                }).disposed(by: self.disposeBag)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Register faces
    ///
    /// Add more faces if the user is already registered
    /// - Parameter sender: Sender of the action
    @IBAction func register(_ sender: Any) {
        rxVerID.session(settings: self.registrationSettings)
            .flatMap({ result in
                rxVerID.croppedFaceImagesFromSessionResult(result, bearing: .straight)
                    .first()
                    .map({ image in
                        if let data = image?.jpegData(compressionQuality: 0.9), let to = (UIApplication.shared.delegate as? AppDelegate)?.profilePictureURL {
                            try data.write(to: to)
                        }
                    })
                    .asMaybe()
            })
            .subscribe(onSuccess: {
                self.updateUserDisplay()
            }, onError: nil, onCompleted: nil)
            .disposed(by: self.disposeBag)
    }
    
    /// Authenticate the registered user
    ///
    /// - Parameter sender: Sender of the action
    @IBAction func authenticate(_ sender: UIButton) {
        let alert = UIAlertController(title: "Select language", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender
        alert.addAction(UIAlertAction(title: "English", style: .default, handler: { _ in
            self.startAuthenticationSession(language: "en")
        }))
        alert.addAction(UIAlertAction(title: "French", style: .default, handler: { _ in
            self.startAuthenticationSession(language: "fr")
        }))
        alert.addAction(UIAlertAction(title: "Spanish", style: .default, handler: { _ in
            self.startAuthenticationSession(language: "es")
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func startAuthenticationSession(language: String) {
        let translatedStrings: TranslatedStrings
        if language == "fr", let url = Bundle(identifier: "com.appliedrec.verid.ui")?.url(forResource: "fr_CA", withExtension: "xml") {
            translatedStrings = try! TranslatedStrings(url: url)
        } else if language == "es", let url = Bundle(identifier: "com.appliedrec.verid.ui")?.url(forResource: "es_US", withExtension: "xml") {
            translatedStrings = try! TranslatedStrings(url: url)
        } else {
            translatedStrings = TranslatedStrings(useCurrentLocale: false)
        }
        let settings = AuthenticationSessionSettings(userId: VerIDUser.defaultUserId)
        settings.showResult = true
        let yawThreshold = UserDefaults.standard.float(forKey: "yawThreshold")
        let pitchThreshold = UserDefaults.standard.float(forKey: "pitchThreshold")
        settings.yawThreshold = CGFloat(yawThreshold)
        settings.pitchThreshold = CGFloat(pitchThreshold)
        rxVerID.session(settings: settings, translatedStrings: translatedStrings)
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Registration export
    
    /// Share registered face templates
    ///
    /// This function will call the app delegate's `uploadRegistration` method end encode the resulting URL in a QR code.
    /// The user can then scan the QR code with another instance of this app to download the face templates and register them.
    ///
    /// - Parameter sender: Bar button item that triggered the function
    @IBAction func shareRegistration(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Share registration", message: "The app will generate a code. Scan the code with this app on another device to import your registration.", preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Generate code", style: .default) { _ in
            let alert = UIAlertController(title: "Exporting registration", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true) {
                rxVerID.facesOfUser(VerIDUser.defaultUserId)
                    .toArray()
                    .map({ faces in
                        var data = RegistrationData()
                        data.faceTemplates = faces
                        if let url = (UIApplication.shared.delegate as? AppDelegate)?.profilePictureURL, let image = UIImage(contentsOfFile: url.path) {
                            data.profilePicture = image.cgImage
                        }
                        return data
                    })
                    .subscribe(onSuccess: { data in
                        (UIApplication.shared.delegate as? AppDelegate)?.registrationUploading?.uploadRegistration(data) { url in
                            DispatchQueue.global().async {
                                guard url != nil, let urlData = "\(url!)".data(using: .utf8) else {
                                    self.showExportFailed()
                                    return
                                }
                                guard let qrCodeImage = self.generateQRCode(data: urlData) else {
                                    self.showExportFailed()
                                    return
                                }
                                DispatchQueue.main.async {
                                    self.dismiss(animated: true) {
                                        self.performSegue(withIdentifier: "export", sender: qrCodeImage)
                                    }
                                }
                            }
                        }
                    }, onError: { _ in
                        self.showExportFailed()
                    })
                    .disposed(by: self.disposeBag)
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Display an error if the face template export fails
    func showExportFailed() {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                let alert = UIAlertController(title: nil, message: "Failed to export registration", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    /// Generate a QR code to facilitate sharing of registered face templates with other devices running this app
    ///
    /// - Parameter data: The data to encode in the QR code
    /// - Returns: QR code image
    func generateQRCode(data: Data) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 8, y: 8)
        guard let ciImage = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        return UIImage(ciImage: ciImage)
    }
    
    /// Unwind segue when the template export is done
    ///
    /// - Parameter segue: Unwind segue
    @IBAction func exportDone(_ segue: UIStoryboardSegue) {
        
    }
    
    // MARK: - Registration import
    
    @IBAction func importCancelled(_ segue: UIStoryboardSegue) {
        self.updateUserDisplay()
    }
    
    /// Display an error when a face template import fails
    func showImportError() {
        let alert = UIAlertController(title: "Error", message: "Failed to download registration", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// QR code scan view controller method
    ///
    /// - Parameters:
    ///   - viewController: The view controller that scanned the QR code
    ///   - value: The string encoded in the QR code
    func qrCodeScanViewController(_ viewController: QRCodeScanViewController, didScanQRCode value: String) {
        self.dismiss(animated: true, completion: nil)
        guard let url = URL(string: value) else {
            self.showImportError()
            return
        }
        let alert = UIAlertController(title: "Downloading", message: nil, preferredStyle: .alert)
        self.present(alert, animated: true) {
            (UIApplication.shared.delegate as? AppDelegate)?.registrationDownloading?.downloadRegistration(url) { registrationData in
                self.dismiss(animated: true) {
                    if registrationData != nil {
                        self.performSegue(withIdentifier: "import", sender: registrationData)
                    } else {
                        self.showImportError()
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let introViewController = segue.destination as? IntroViewController {
            // Hide the register button on the intro slides
            introViewController.showRegisterButton = false
        } else if segue.identifier == "export", let viewController = segue.destination as? ExportCodeViewController, let qrCodeImage = sender as? UIImage {
            viewController.qrCodeImage = qrCodeImage
        } else if let scanViewController = segue.destination as? QRCodeScanViewController {
            scanViewController.delegate = self
        } else if let importViewController = segue.destination as? RegistrationImportViewController, let registrationData = sender as? RegistrationData, let image = registrationData.profilePicture {
            importViewController.faceTemplates = registrationData.faceTemplates
            importViewController.image = UIImage(cgImage: image)
        }
    }
}
