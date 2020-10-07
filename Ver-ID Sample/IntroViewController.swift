//
//  IntroViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 08/02/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore
import VerIDUI
import AVFoundation
import MobileCoreServices

class IntroViewController: UIPageViewController, UIPageViewControllerDataSource, VerIDSessionDelegate, UIDocumentPickerDelegate, RegistrationImportDelegate, SessionDiagnosticsViewControllerDelegate {
    
    lazy var introViewControllers: [UIViewController] = {
        guard let storyboard = self.storyboard else {
            return []
        }
        var controllers: [UIViewController] = [
            storyboard.instantiateViewController(withIdentifier: "introPage1"),
            storyboard.instantiateViewController(withIdentifier: "introPage2"),
            storyboard.instantiateViewController(withIdentifier: "introPage3")
        ]
        return controllers
    }()
    
    @IBOutlet var registerButton: UIBarButtonItem!
    @IBOutlet var importButton: UIBarButtonItem!
    @IBOutlet var settingsButton: UIBarButtonItem!
    
    var showRegisterButton = true

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        var leftBarButtonItems: [UIBarButtonItem] = []
        if showRegisterButton {
            self.navigationItem.rightBarButtonItems = [self.registerButton]
            leftBarButtonItems.append(self.settingsButton)
            leftBarButtonItems.append(self.importButton)
        }
        self.navigationItem.leftBarButtonItems = leftBarButtonItems.isEmpty ? nil : leftBarButtonItems
        if let initialController = self.introViewControllers.first {
            self.setViewControllers([initialController], direction: .forward, animated: false, completion: nil)
        }
    }
    
    @IBAction func importRegistration(_ button: UIBarButtonItem) {
        let picker = UIDocumentPickerViewController(documentTypes: [Globals.registrationUTType], in: .import)
        if #available(iOS 11, *) {
            picker.allowsMultipleSelection = false
        }
        picker.popoverPresentationController?.barButtonItem = button
        picker.delegate = self
        self.present(picker, animated: true) {
            if Globals.isTesting, let url = Bundle.main.url(forResource: "Test registration", withExtension: "verid") {
                self.dismiss(animated: false) {
                    self.documentPicker(picker, didPickDocumentAt: url)
                }
            }
        }
    }
    
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didImportRegistrationFromURL url: URL) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "start") as? MainViewController else {
            return
        }
        self.navigationController?.viewControllers = [viewController]
    }
    
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didFailToImportRegistration error: Error) {
        let alert = UIAlertController(title: "Registration import failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    func didCancelImportInRegistrationImportViewController(_ registrationImportViewController: RegistrationImportViewController) {
        
    }
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let importViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "registrationImport") as? RegistrationImportViewController else {
            return
        }
        importViewController.url = url
        importViewController.delegate = self
        self.navigationController?.pushViewController(importViewController, animated: true)
    }
    
    // MARK: -
    
    func showImportError() {
        let alert = UIAlertController(title: "Error", message: "Failed to download registration", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func register(_ sender: Any) {
        guard let verid = Globals.verid else {
            return
        }
        let settings = RegistrationSessionSettings(userId: VerIDUser.defaultUserId, userDefaults: UserDefaults.standard)
        settings.isSessionDiagnosticsEnabled = true
        let session = VerIDSession(environment: verid, settings: settings)
        if Globals.isTesting {
            session.sessionFunctions = TestSessionFunctions(verID: verid, sessionSettings: settings)
            session.sessionViewControllersFactory = TestSessionViewControllersFactory(settings: settings)
        }
        session.delegate = self
        session.start()
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.introViewControllers.firstIndex(of: viewController), index > 0 else {
            return nil
        }
        return self.introViewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.introViewControllers.firstIndex(of: viewController), index + 1 < self.introViewControllers.count else {
            return nil
        }
        return self.introViewControllers[index + 1]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.introViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
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
    
    // MARK: - Ver-ID Session Delegate
    
    func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        self.uploadedToS3 = false
        Globals.updateProfilePictureFromSessionResult(result)
        if result.error == nil {
            Globals.deleteImagesInSessionResult(result)
        }
        if result.error != nil {
            let viewController = SessionDiagnosticsViewController.create(sessionResultPackage: SessionResultPackage(verID: session.environment, settings: session.settings, result: result))
            viewController.delegate = self
            viewController.title = "Registration Failed"
            self.navigationController?.pushViewController(viewController, animated: true)
        } else {
            guard let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "start") as? MainViewController else {
                return
            }
            self.navigationController?.setViewControllers([mainViewController], animated: true)
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
    
}
