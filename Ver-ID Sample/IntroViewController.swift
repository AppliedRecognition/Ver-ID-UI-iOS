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
import MobileCoreServices

class IntroViewController: UIPageViewController, UIPageViewControllerDataSource, VerIDSessionDelegate, UIDocumentPickerDelegate, RegistrationImportDelegate {
    
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
//        RegistrationImport.importFromURL(url, verid: verid) { error in
//            if error == nil {
//                guard let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "start") as? MainViewController else {
//                    return
//                }
//                self.navigationController?.viewControllers = [mainViewController]
//            } else {
//                let alert = UIAlertController(title: "Registration import failed", message: error?.localizedDescription, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default))
//                self.present(alert, animated: true)
//            }
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let codeScanViewController = segue.destination as? QRCodeScanViewController {
//            codeScanViewController.delegate = self
//        } else if let importViewController = segue.destination as? RegistrationImportViewController, let registrationData = sender as? RegistrationData, let image = registrationData.profilePicture {
//            importViewController.image = UIImage(cgImage: image)
//            importViewController.faceTemplates = registrationData.faceTemplates
//        }
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
        if UserDefaults.standard.enableVideoRecording {
            settings.videoURL = FileManager.default.temporaryDirectory.appendingPathComponent("video").appendingPathExtension("mov")
        }
        settings.isSessionDiagnosticsEnabled = true
        let session = VerIDSession(environment: verid, settings: settings)
        if Globals.isTesting {
            session.imageProviderFactory = TestImageProviderServiceFactory()
            session.faceDetectionFactory = TestFaceDetectionServiceFactory()
            session.resultEvaluationFactory = TestResultEvaluationServiceFactory()
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
    
    // MARK: - Ver-ID Session Delegate
    
    func session(_ session: VerIDSession, didFinishWithResult result: VerIDSessionResult) {
        Globals.updateProfilePictureFromSessionResult(result)
        if result.error == nil {
            Globals.deleteImagesInSessionResult(result)
        }
        guard let storyboard = self.storyboard else {
            return
        }
        var viewControllers: [UIViewController] = []
        guard let mainViewController = storyboard.instantiateViewController(withIdentifier: "start") as? MainViewController else {
            return
        }
        viewControllers.append(mainViewController)
        if result.error != nil {
            guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "result") as? SessionResultViewController else {
                return
            }
            viewController.sessionResult = result
            viewController.sessionTime = Date()
            viewController.sessionSettings = session.settings
            viewController.title = "Registration Failed"
            viewControllers.append(viewController)
        }
        self.navigationController?.setViewControllers(viewControllers, animated: false)
    }
    
    func sessionWasCanceled(_ session: VerIDSession) {
        
    }
}
