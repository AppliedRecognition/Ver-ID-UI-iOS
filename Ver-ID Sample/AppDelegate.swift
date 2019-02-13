//
//  AppDelegate.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 20/01/2016.
//  Copyright © 2016 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, VerIDFactoryDelegate {
    
    // MARK: - Instance variables

    var window: UIWindow?
    var profilePictureURL: URL?
    
    // MARK: - Application delegate methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        reload()
        return true
    }
    
    func reload() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        navigationController.setViewControllers([storyboard.instantiateViewController(withIdentifier: "loading")], animated: false)
        // Load Ver-ID
        // API secret is read from the app's Info.plist
        let factory = VerIDFactory()
        factory.delegate = self
        factory.createVerID()
    }
    
    // MARK: -
    
    func showError() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "error")
        navigationController.setViewControllers([initialViewController], animated: false)
    }
    
    // MARK: - Ver-ID factory delegate
    
    func veridFactory(_ factory: VerIDFactory, didCreateVerID instance: VerID) {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController: UIViewController
        do {
            let users = try instance.userManagement.users()
            if users.isEmpty {
                initialViewController = storyboard.instantiateViewController(withIdentifier: "intro")
                (initialViewController as? IntroViewController)?.environment = instance
            } else {
                initialViewController = storyboard.instantiateViewController(withIdentifier: "start")
                (initialViewController as? MainViewController)?.environment = instance
            }
            // Replace the root in the navigation view controller.
            navigationController.setViewControllers([initialViewController], animated: false)
        } catch {
            self.showError()
        }
    }
    
    func veridFactory(_ factory: VerIDFactory, didFailWithError error: Error) {
        self.showError()
    }
    
    // MARK: - Registration upload/download
    
    /// Implement RegistrationUploading if you want your app to handle exporting face registrations
    var registrationUploading: RegistrationUploading? {
        return nil
    }
    
    /// Implement RegistrationDownloading if you want your app to handle importing face registrations
    var registrationDownloading: RegistrationDownloading? {
        return nil
    }
}

