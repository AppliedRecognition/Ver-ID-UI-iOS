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
        self.profilePictureURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("profilePicture").appendingPathExtension("jpg")
        let faceExtractQualityThreshold: Float = (VerIDFactory().faceDetectionFactory as? VerIDFaceDetectionRecognitionFactory)?.settings.faceExtractQualityThreshold ?? 8.0
        let livenessDetectionSettings = LivenessDetectionSessionSettings()
        UserDefaults.standard.register(defaults: [
            "livenessDetectionPoses": NSNumber(value: 1),
            "yawThreshold": livenessDetectionSettings.yawThreshold as NSNumber,
            "pitchThreshold": livenessDetectionSettings.pitchThreshold as NSNumber,
            "authenticationThreshold": NSNumber(value: 3.5),
            "faceExtractQualityThreshold": NSNumber(value: faceExtractQualityThreshold),
            "numberOfFacesToRegister": NSNumber(value: 1)
            ])
        self.reload()
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
    
    func displayError() {
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
        instance.faceRecognition.authenticationScoreThreshold = NSNumber(value: UserDefaults.standard.float(forKey: "authenticationThreshold"))
        let initialViewController: UIViewController
        if let users = try? instance.userManagement.users(), users.contains(VerIDUser.defaultUserId) {
            if let controller = storyboard.instantiateViewController(withIdentifier: "start") as? MainViewController {
                // Instantiate the main view controller.
                controller.environment = instance
                initialViewController = controller
            } else {
                self.displayError()
                return
            }
        } else if let controller = storyboard.instantiateViewController(withIdentifier: "intro") as? IntroViewController {
            controller.environment = instance
            initialViewController = controller
        } else {
            displayError()
            return
        }
        // Replace the root in the navigation view controller.
        navigationController.setViewControllers([initialViewController], animated: false)
    }
    
    func veridFactory(_ factory: VerIDFactory, didFailWithError error: Error) {
        self.displayError()
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

