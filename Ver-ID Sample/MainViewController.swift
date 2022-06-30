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
import AVFoundation
import MobileCoreServices

class MainViewController: UIViewController, VerIDSessionDelegate, UIDocumentPickerDelegate, RegistrationImportDelegate, SessionDiagnosticsViewControllerDelegate {
    
    let maxRetryCount = 3
    var sessionRunCount = 0
    
    // MARK: - Interface builder views

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var importButton: UIButton!
    
    // MARK: -
    
    /// Settings to use for user registration
    var registrationSettings: RegistrationSessionSettings {
        let settings = RegistrationSessionSettings(userId: VerIDUser.defaultUserId, userDefaults: UserDefaults.standard)
        settings.isSessionDiagnosticsEnabled = true
        return settings
    }
    
//    let disposeBag = DisposeBag()
    
    // MARK: - Override from UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUserDisplay()
    }
    
    // MARK: -
    
    /// Find out whether the user registered their face. If the user is registered display their profile photo and enable the Authenticate button.
    func updateUserDisplay() {
        guard let url = Globals.profilePictureURL, let image = UIImage(contentsOfFile: url.path) else {
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Unregister", style: .destructive, handler: { _ in
            guard let verid = Globals.verid else {
                return
            }
            verid.userManagement.deleteUsers([VerIDUser.defaultUserId]) { error in
                guard let storyboard = self.storyboard else {
                    return
                }
                guard let introViewController = storyboard.instantiateViewController(withIdentifier: "intro") as? IntroViewController else {
                    return
                }
                self.navigationController?.setViewControllers([introViewController], animated: false)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Register faces
    ///
    /// Add more faces if the user is already registered
    /// - Parameter sender: Sender of the action
    @IBAction func register(_ sender: Any) {
        guard let verid = Globals.verid else {
            return
        }
        sessionRunCount = 0
        let session = VerIDSession(environment: verid, settings: self.registrationSettings)
        if Globals.isTesting {
            session.sessionFunctions = TestSessionFunctions(verID: verid, sessionSettings: self.registrationSettings)
            session.sessionViewControllersFactory = TestSessionViewControllersFactory(settings: self.registrationSettings)
        }
        session.delegate = self
        session.start()
    }
    
    /// Authenticate the registered user
    ///
    /// - Parameter sender: Sender of the action
    @IBAction func authenticate(_ sender: UIButton) {
        guard let verid = Globals.verid else {
            return
        }
        sessionRunCount = 0
        let settings = AuthenticationSessionSettings(userId: VerIDUser.defaultUserId, userDefaults: UserDefaults.standard)
        settings.isSessionDiagnosticsEnabled = true
        let session = VerIDSession(environment: verid, settings: settings)
        if Globals.isTesting && !Globals.shouldCancelAuthentication {
            session.sessionFunctions = TestSessionFunctions(verID: verid, sessionSettings: settings)
            session.sessionViewControllersFactory = TestSessionViewControllersFactory(settings: settings)
        }
        session.delegate = self
        session.start()
    }
    
    // MARK: - Ver-ID Session Delegate
    
    func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        self.uploadedToS3 = false
        if session.settings is RegistrationSessionSettings && result.error == nil {
            Globals.updateProfilePictureFromSessionResult(result)
            Globals.deleteImagesInSessionResult(result)
            self.updateUserDisplay()
            let alert = UIAlertController(title: "Registration successful", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        } else {
            let viewController = SessionDiagnosticsViewController.create(sessionResultPackage: SessionResultPackage(verID: session.environment, settings: session.settings, result: result))
            if result.error != nil {
                viewController.title = "Session Failed"
            } else {
                viewController.title = "Success"
            }
            viewController.delegate = self
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func shouldRecordVideoOfSession(_ session: VerIDSession) -> Bool {
        UserDefaults.standard.enableVideoRecording
    }
    
    func shouldSpeakPromptsInSession(_ session: VerIDSession) -> Bool {
        UserDefaults.standard.speakPrompts
    }
    
    func cameraPositionForSession(_ session: VerIDSession) -> AVCaptureDevice.Position {
        UserDefaults.standard.useBackCamera ? .back : .front
    }
    
    func shouldDisplayResult(_ result: VerIDSessionResult, ofSession session: VerIDSession) -> Bool {
        return false
    }
    
    func shouldRetrySession(_ session: VerIDSession, afterFailure error: Error) -> Bool {
        sessionRunCount += 1
        return sessionRunCount < maxRetryCount
    }
    
    // MARK: - Session diagnostics view controller delegate
    
    private var uploadedToS3 = false
    
    var applicationActivities: [UIActivity]? {
        if !uploadedToS3, let activity = try? S3UploadActivity(bucket: "ver-id") {
            return [activity]
        }
        return nil
    }
    
    var activityCompletionHandler: UIActivityViewController.CompletionWithItemsHandler? {
        { activityType, completed, items, error in
            if activityType == .some(.s3Upload) {
                self.uploadedToS3 = completed
            }
        }
    }
    
    // MARK: - Registration export
    
    /// Share registered face templates
    ///
    /// This function will call the app delegate's `uploadRegistration` method end encode the resulting URL in a QR code.
    /// The user can then scan the QR code with another instance of this app to download the face templates and register them.
    ///
    /// - Parameter sender: Bar button item that triggered the function
    @IBAction func shareRegistration(_ sender: UIBarButtonItem) {
        guard let verid = Globals.verid, let profilePictureURL = Globals.profilePictureURL else {
            return
        }
        guard let shareItem = try? RegistrationProvider(verid: verid, profilePictureURL: profilePictureURL) else {
            return
        }
        let activityController = UIActivityViewController(activityItems: [shareItem], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = sender
        activityController.completionWithItemsHandler = { activityType, completed, items, error in
            shareItem.cleanup()
        }
        self.present(activityController, animated: true)
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
    
    // MARK: - Registration import
    
    @IBAction func importRegistration(_ button: UIButton) {
        let picker = UIDocumentPickerViewController(documentTypes: [Globals.registrationUTType], in: .import)
        if #available(iOS 11, *) {
            picker.allowsMultipleSelection = false
        }
        picker.popoverPresentationController?.sourceView = button
        picker.delegate = self
        self.present(picker, animated: true) {
            if Globals.isTesting, let url = Bundle.main.url(forResource: "Test registration", withExtension: "registration") {
                self.dismiss(animated: false) {
                    self.documentPicker(picker, didPickDocumentAt: url)
                }
            }
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let importViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "registrationImport") as? RegistrationImportViewController else {
            return
        }
        importViewController.url = url
        importViewController.delegate = self
        self.navigationController?.pushViewController(importViewController, animated: true)
    }
    
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didImportRegistrationFromURL url: URL) {
        self.updateUserDisplay()
        let title = "Registration imported"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)            
        })
        self.present(alert, animated: true)
    }
    
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didFailToImportRegistration error: Error) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func didCancelImportInRegistrationImportViewController(_ registrationImportViewController: RegistrationImportViewController) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /// Display an error when a face template import fails
    func showImportError() {
        let alert = UIAlertController(title: "Error", message: "Failed to download registration", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let introViewController = segue.destination as? IntroViewController {
            // Hide the register button on the intro slides
            introViewController.showRegisterButton = false
        }
    }
}

extension MainViewController: UIDocumentInteractionControllerDelegate {
    
    
}
