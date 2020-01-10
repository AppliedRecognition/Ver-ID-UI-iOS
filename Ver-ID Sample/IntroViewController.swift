//
//  IntroViewController.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 08/02/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import VerIDCore
import RxVerID
import RxSwift

class IntroViewController: UIPageViewController, UIPageViewControllerDataSource, QRCodeScanViewControllerDelegate {
    
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
    
    var showRegisterButton = true
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        if !showRegisterButton {
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = nil
        }
        if (UIApplication.shared.delegate as! AppDelegate).registrationDownloading == nil {
            // Hide import button if app delegate cannot handle face template imports
            self.navigationItem.leftBarButtonItem = nil
        }
        if let initialController = self.introViewControllers.first {
            self.setViewControllers([initialController], direction: .forward, animated: false, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let codeScanViewController = segue.destination as? QRCodeScanViewController {
            codeScanViewController.delegate = self
        } else if let importViewController = segue.destination as? RegistrationImportViewController, let registrationData = sender as? RegistrationData, let image = registrationData.profilePicture {
            importViewController.image = UIImage(cgImage: image)
            importViewController.faceTemplates = registrationData.faceTemplates
        }
    }
    
    // MARK: - QR code scan delegate
    
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
    
    // MARK: -
    
    func showImportError() {
        let alert = UIAlertController(title: "Error", message: "Failed to download registration", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func register(_ sender: Any) {
        let settings = RegistrationSessionSettings(userId: VerIDUser.defaultUserId, showResult: true)
        let yawThreshold = UserDefaults.standard.float(forKey: "yawThreshold")
        let pitchThreshold = UserDefaults.standard.float(forKey: "pitchThreshold")
        let numberOfFacesToRegister = UserDefaults.standard.integer(forKey: "numberOfFacesToRegister")
        settings.yawThreshold = CGFloat(yawThreshold)
        settings.pitchThreshold = CGFloat(pitchThreshold)
        settings.numberOfResultsToCollect = numberOfFacesToRegister
        
        rxVerID.session(settings: settings)
            .asObservable()
            .flatMap({ result in
                rxVerID.croppedFaceImagesFromSessionResult(result, bearing: .straight).first()
            })
            .asSingle()
            .flatMapCompletable({ image in
                if let data = image?.jpegData(compressionQuality: 0.9), let url = profilePictureURL {
                    try data.write(to: url)
                }
                return Completable.empty()
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                guard let storyboard = self.storyboard else {
                    return
                }
                guard let viewController = storyboard.instantiateViewController(withIdentifier: "start") as? MainViewController else {
                    return
                }
                self.navigationController?.setViewControllers([viewController], animated: false)
            }, onError: nil)
            .disposed(by: self.disposeBag)
    }
    
    @IBAction func importCancelled(_ segue: UIStoryboardSegue) {
        if let codeScanViewController = segue.source as? QRCodeScanViewController {
            codeScanViewController.delegate = nil
        }
        if segue.source is RegistrationImportViewController, let storyboard = self.storyboard {
            rxVerID.facesOfUser(VerIDUser.defaultUserId)
                .first()
                .asMaybe()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { _ in
                    guard let mainViewController = storyboard.instantiateViewController(withIdentifier: "start") as? MainViewController else {
                        return
                    }
                    self.navigationController?.setViewControllers([mainViewController], animated: false)
                }, onError: nil, onCompleted: nil)
                .disposed(by: self.disposeBag)
        }
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
}
