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
    var userDefaultsContext: Int = 0
    var faceExtractQualityThreshold: Float?
    let faceExtractionQualityThresholdKeyPath = "faceExtractQualityThreshold"
    let faceTemplateEncryptionKeyPath = "faceTemplateEncryption"
    
    // MARK: - Application delegate methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        self.profilePictureURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("profilePicture").appendingPathExtension("jpg")
        let defaultSettings = DetRecLibSettings(modelsURL: nil)
        self.faceExtractQualityThreshold = defaultSettings.faceExtractQualityThreshold
        let livenessDetectionSettings = LivenessDetectionSessionSettings()
        UserDefaults.standard.register(defaults: [
            "livenessDetectionPoses": NSNumber(value: 1),
            "yawThreshold": livenessDetectionSettings.yawThreshold as NSNumber,
            "pitchThreshold": livenessDetectionSettings.pitchThreshold as NSNumber,
            "authenticationThreshold": NSNumber(value: 3.5),
            faceExtractionQualityThresholdKeyPath: NSNumber(value: faceExtractQualityThreshold!),
            "numberOfFacesToRegister": NSNumber(value: 1),
            faceTemplateEncryptionKeyPath: true
            ])
        UserDefaults.standard.addObserver(self, forKeyPath: faceExtractionQualityThresholdKeyPath, options: .new, context: &userDefaultsContext)
        UserDefaults.standard.addObserver(self, forKeyPath: faceTemplateEncryptionKeyPath, options: .new, context: &userDefaultsContext)
        self.reload()
        return true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.userDefaultsContext, let defaults = object as? UserDefaults {
            if keyPath == self.faceExtractionQualityThresholdKeyPath {
                let updatedValue = defaults.float(forKey: self.faceExtractionQualityThresholdKeyPath)/10
                if self.faceExtractQualityThreshold == nil || self.faceExtractQualityThreshold! != updatedValue {
                    self.faceExtractQualityThreshold = updatedValue
                    DispatchQueue.main.async {
                        self.reload()
                    }
                }
            } else if keyPath == self.faceTemplateEncryptionKeyPath {
                DispatchQueue.main.async {
                    self.reload()
                }
            }
        }
    }
    
    func reload() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        navigationController.setViewControllers([storyboard.instantiateViewController(withIdentifier: "loading")], animated: false)
        // Load Ver-ID
        // API secret is read from the app's Info.plist
        let veridFactory = VerIDFactory()
        let detRecLibSettings = DetRecLibSettings(modelsURL: nil)
        detRecLibSettings.faceExtractQualityThreshold = self.faceExtractQualityThreshold ?? UserDefaults.standard.float(forKey: self.faceExtractionQualityThresholdKeyPath)
        let detRecLibFactory = VerIDFaceDetectionRecognitionFactory(apiSecret: nil, settings: detRecLibSettings)
        veridFactory.faceDetectionFactory = detRecLibFactory
        veridFactory.faceRecognitionFactory = detRecLibFactory
        let userManagementFactory = VerIDUserManagementFactory(disableEncryption: !UserDefaults.standard.bool(forKey: self.faceTemplateEncryptionKeyPath))
        veridFactory.userManagementFactory = userManagementFactory
        veridFactory.delegate = self
        veridFactory.createVerID()
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
    
    func displayError() {
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "error")
        navigationController.setViewControllers([initialViewController], animated: false)
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

