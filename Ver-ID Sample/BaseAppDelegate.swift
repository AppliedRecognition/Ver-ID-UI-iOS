//
//  BaseAppDelegate.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 29/11/2019.
//  Copyright © 2019 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

var profilePictureURL: URL?
var verid: VerID?

class BaseAppDelegate: UIResponder, UIApplicationDelegate, VerIDFactoryDelegate {

    // MARK: - Instance variables

    var window: UIWindow?
    var userDefaultsContext: Int = 0
    var faceExtractQualityThreshold: Float?
    let faceExtractionQualityThresholdKeyPath = "faceExtractQualityThreshold"
    let faceTemplateEncryptionKeyPath = "faceTemplateEncryption"
//    let disposeBag: DisposeBag = DisposeBag()

    // MARK: - Application delegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        profilePictureURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("profilePicture").appendingPathExtension("jpg")
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
        let detRecLibSettings = DetRecLibSettings(modelsURL: nil)
        detRecLibSettings.faceExtractQualityThreshold = self.faceExtractQualityThreshold ?? UserDefaults.standard.float(forKey: self.faceExtractionQualityThresholdKeyPath)
        let detRecLibFactory = VerIDFaceDetectionRecognitionFactory(apiSecret: nil, settings: detRecLibSettings)
        let veridFactory = VerIDFactory()
        veridFactory.delegate = self
        veridFactory.faceDetectionFactory = detRecLibFactory
        veridFactory.faceRecognitionFactory = detRecLibFactory
        let userManagementFactory = VerIDUserManagementFactory(disableEncryption: !UserDefaults.standard.bool(forKey: self.faceTemplateEncryptionKeyPath))
        veridFactory.userManagementFactory = userManagementFactory
        veridFactory.createVerID()
//        rxVerID.verid
//            .flatMapCompletable({ verid in
//                verid.faceRecognition.authenticationScoreThreshold = NSNumber(value: UserDefaults.standard.float(forKey: "authenticationThreshold"))
//                return Completable.empty()
//            })
//            .andThen(rxVerID.facesOfUser(VerIDUser.defaultUserId))
//            .first()
//            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
//            .observeOn(MainScheduler.instance)
//            .subscribe(onSuccess: { face in
//                let initialViewController: UIViewController
//                if face != nil {
//                    if let controller = storyboard.instantiateViewController(withIdentifier: "start") as? MainViewController {
//                        // Instantiate the main view controller.
//                        initialViewController = controller
//                    } else {
//                        self.displayError()
//                        return
//                    }
//                } else if let controller = storyboard.instantiateViewController(withIdentifier: "intro") as? IntroViewController {
//                    initialViewController = controller
//                } else {
//                    self.displayError()
//                    return
//                }
//                // Replace the root in the navigation view controller.
//                navigationController.setViewControllers([initialViewController], animated: false)
//            }, onError: { _ in
//                self.displayError()
//            }).disposed(by: self.disposeBag)
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
        instance.faceRecognition.authenticationScoreThreshold = NSNumber(value: UserDefaults.standard.float(forKey: "authenticationThreshold"))
        verid = instance
        guard let navigationController = self.window?.rootViewController as? UINavigationController, let storyboard = navigationController.storyboard else {
            return
        }
        let initialViewController: UIViewController
        if let faces = try? instance.userManagement.facesOfUser(VerIDUser.defaultUserId), faces.isEmpty {
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
