//
//  BaseAppDelegate.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 29/11/2019.
//  Copyright © 2019 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import VerIDSDKIdentity
import SpoofDeviceDetection

class BaseAppDelegate: UIResponder, UIApplicationDelegate, RegistrationImportDelegate {

    // MARK: - Instance variables

    var window: UIWindow?

    // MARK: - Application delegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Globals.profilePictureURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("profilePicture").appendingPathExtension("jpg")
        UserDefaults.standard.registerVerIDDefaults()
        // Ver-ID is loaded from the scene delegate, once the scene's window exists.
        return true
    }
    
    /// Called by the scene delegate when the scene connects
    func sceneDidConnect(connectionOptions: UIScene.ConnectionOptions) {
        let urls = connectionOptions.urlContexts.map({ $0.url })
        if urls.isEmpty {
            self.reload()
        } else {
            self.openRegistrationURLs(urls)
        }
    }
    
    /// Open one or more registration documents
    func openRegistrationURLs(_ urls: [URL]) {
        for url in urls {
            guard url.pathExtension == "registration" else {
                continue
            }
            guard let importViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "registrationImport") as? RegistrationImportViewController else {
                continue
            }
            importViewController.url = url
            importViewController.delegate = self
            (self.window?.rootViewController as? UINavigationController)?.viewControllers = [importViewController]
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.pathExtension == "registration" else {
            return false
        }
        self.openRegistrationURLs([url])
        return true
    }
    
    // MARK: - Registration import delegate
    
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didImportRegistrationFromURL url: URL) {
        self.reload()
    }
    
    func registrationImportViewController(_ registrationImportViewController: RegistrationImportViewController, didFailToImportRegistration error: Error) {
        self.reload()
    }
    
    func didCancelImportInRegistrationImportViewController(_ registrationImportViewController: RegistrationImportViewController) {
        self.reload()
    }
    
    // MARK: -

    func reload(deleteIncompatibleFaces: Bool = false) {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        Globals.verid = nil
        DispatchQueue.main.async {
            navigationController.setViewControllers([storyboard.instantiateViewController(withIdentifier: "loading")], animated: false)
        }
        // Load Ver-ID
        let veridFactory = VerIDFactory(userDefaults: UserDefaults.standard)
        veridFactory.createVerID { result in
            switch result {
            case .success(let verid):
                Globals.verid = verid
                if Globals.isTesting, let users = try? verid.userManagement.users(), !users.isEmpty {
                    verid.userManagement.deleteUsers(users) { _ in
                        self.loadInitialViewController()
                    }
                    return
                }
                self.loadInitialViewController()
            case .failure(let error):
                switch error {
                case VerIDUserManagementError.containsIncompatibleFaces:
                    self.displayIncompatibleFacesError()
                default:
                    self.displayError()
                }
            }
            guard case .success(let verid) = result else {
                self.displayError()
                return
            }
            Globals.verid = verid
            for (templateVersion, threshold) in UserDefaults.standard.authenticationThresholds {
                (verid.faceRecognition as? VerIDFaceRecognition)?.setAuthenticationScoreThreshold(NSNumber(value: threshold), faceTemplateVersion: templateVersion)
            }
            if Globals.isTesting, let users = try? verid.userManagement.users(), !users.isEmpty {
                verid.userManagement.deleteUsers(users) { _ in
                    self.loadInitialViewController()
                }
                return
            }
            self.loadInitialViewController()
        }
    }

    func displayError() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "error")
        navigationController.setViewControllers([initialViewController], animated: false)
    }
    
    private func loadInitialViewController() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController: UIViewController
        if let faces = try? Globals.verid?.userManagement.facesOfUser(VerIDUser.defaultUserId), !faces.isEmpty {
            if let controller = storyboard.instantiateViewController(withIdentifier: "start") as? MainViewController {
                // Instantiate the main view controller.
                initialViewController = controller
            } else {
                self.displayError()
                return
            }
        } else if let controller = storyboard.instantiateViewController(withIdentifier: "intro") as? IntroViewController {
            initialViewController = controller
        } else {
            self.displayError()
            return
        }
        // Replace the root in the navigation view controller.
        navigationController.setViewControllers([initialViewController], animated: false)
    }
    
    func displayIncompatibleFacesError() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "incompatibleFaces")
        navigationController.setViewControllers([initialViewController], animated: false)
    }
}
