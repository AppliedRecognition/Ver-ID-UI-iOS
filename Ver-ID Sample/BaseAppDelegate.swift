//
//  BaseAppDelegate.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 29/11/2019.
//  Copyright © 2019 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

class BaseAppDelegate: UIResponder, UIApplicationDelegate, VerIDFactoryDelegate, RegistrationImportDelegate {

    // MARK: - Instance variables

    var window: UIWindow?

    // MARK: - Application delegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Globals.profilePictureURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("profilePicture").appendingPathExtension("jpg")
        UserDefaults.standard.registerVerIDDefaults()
        if launchOptions?.keys.contains(.url) == .some(true) {
            return true
        }
        self.reload()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.pathExtension == "verid" else {
            return false
        }
        guard let importViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "registrationImport") as? RegistrationImportViewController else {
            return false
        }
        importViewController.url = url
        importViewController.delegate = self
        (self.window?.rootViewController as? UINavigationController)?.viewControllers = [importViewController]
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

    func reload() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        Globals.verid = nil
        navigationController.setViewControllers([storyboard.instantiateViewController(withIdentifier: "loading")], animated: false)
        // Load Ver-ID
        // Ver-ID API password is read from the app's Info.plist
        let veridFactory = VerIDFactory(userDefaults: UserDefaults.standard)
        veridFactory.delegate = self
        veridFactory.createVerID()
    }

    func displayError() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "error")
        navigationController.setViewControllers([initialViewController], animated: false)
    }
    
    // MARK: - Ver-ID Factory Delegate
    
    func veridFactory(_ factory: VerIDFactory, didCreateVerID instance: VerID) {
        instance.faceRecognition.authenticationScoreThreshold = NSNumber(value: UserDefaults.standard.authenticationThreshold)
        Globals.verid = instance
        if Globals.isTesting {
            if let users = try? instance.userManagement.users() {
                if !users.isEmpty {
                    instance.userManagement.deleteUsers(users) { _ in
                        self.loadInitialViewController()
                    }
                    return
                }
            }
        }
        self.loadInitialViewController()
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
    
    func veridFactory(_ factory: VerIDFactory, didFailWithError error: Error) {
        self.displayError()
    }
}
