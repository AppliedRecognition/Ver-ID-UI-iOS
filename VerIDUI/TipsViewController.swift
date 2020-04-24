//
//  RegistrationIntro2ViewController.swift
//  VerID
//
//  Created by Jakub Dolejs on 03/10/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit

/// View controller that shows tips
class TipsViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, TipsViewControllerProtocol, SpeechDelegatable {
    
    var translatedStrings: TranslatedStrings?
    var speechDelegate: SpeechDelegate?
    
    // MARK: - Tips view controller protocol
    
    var tipsViewControllerDelegate: TipsViewControllerDelegate?
    
    // MARK: -
    
    lazy var tipControllers: [TipPageViewController] = {
        guard let storyboard = self.storyboard else {
            return []
        }
        return [
            storyboard.instantiateViewController(withIdentifier: "tip1") as! TipPageViewController,
            storyboard.instantiateViewController(withIdentifier: "tip2") as! TipPageViewController,
            storyboard.instantiateViewController(withIdentifier: "tip3") as! TipPageViewController
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.view.backgroundColor = UIColor.black
        if let translatedStrings = self.translatedStrings {
            self.tipControllers[0].text = translatedStrings["Avoid standing in a light that throws sharp shadows like in sharp sunlight or directly under a lamp."]
            self.tipControllers[1].text = translatedStrings["If you can, take off your glasses."]
            self.tipControllers[2].text = translatedStrings["Avoid standing in front of busy backgrounds."]
            self.tipControllers[0].title = translatedStrings["Tip %d of %d", 1, 3]
            self.tipControllers[1].title = translatedStrings["Tip %d of %d", 2, 3]
            self.tipControllers[2].title = translatedStrings["Tip %d of %d", 3, 3]
        }
        if let initialController = self.tipControllers.first {
            self.setViewControllers([initialController], direction: .forward, animated: false, completion: nil)
            self.updateNavBar()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            self.tipsViewControllerDelegate?.didDismissTipsInViewController(self)
        }
    }
    
    @objc func close() {
        self.tipsViewControllerDelegate?.didDismissTipsInViewController(self)
    }
    
    private func updateNavBar() {
        guard let page: TipPageViewController = self.viewControllers?[0] as? TipPageViewController else {
            return
        }
        self.navigationItem.title = page.title
        if let speechDelegate = self.speechDelegate, let text = page.text, var language = self.translatedStrings?.resolvedLanguage {
            if let region = self.translatedStrings?.resolvedRegion {
                language.append("-\(region)")
            }
            speechDelegate.speak(text, language: language)
        }
    }
    
    // MARK: - Page view controller data source
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.tipControllers.firstIndex(of: viewController as! TipPageViewController), index + 1 < self.tipControllers.count else {
            return nil
        }
        return self.tipControllers[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.tipControllers.firstIndex(of: viewController as! TipPageViewController), index > 0 else {
            return nil
        }
        return self.tipControllers[index - 1]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.tipControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: - Page view controller delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            self.updateNavBar()
        }
    }
}

/// Tips view controller delegate
@objc public protocol TipsViewControllerDelegate: class {
    /// Called when the user the tips view controller
    ///
    /// - Parameter viewController: View controller that was dismissed
    @objc func didDismissTipsInViewController(_ viewController: TipsViewControllerProtocol)
}

/// Tips view controller protocol
@objc public protocol TipsViewControllerProtocol: class {
    /// Tips view controller delegate
    @objc var tipsViewControllerDelegate: TipsViewControllerDelegate? { get set }
}
