//
//  RegistrationIntro2ViewController.swift
//  VerID
//
//  Created by Jakub Dolejs on 03/10/2017.
//  Copyright © 2017 Applied Recognition, Inc. All rights reserved.
//

import UIKit

/// View controller that shows tips
class TipsViewController: UIPageViewController, UIPageViewControllerDataSource, TipsViewControllerProtocol {
    
    // MARK: - Tips view controller protocol
    
    var tipsViewControllerDelegate: TipsViewControllerDelegate?
    
    // MARK: -
    
    lazy var tipControllers: [UIViewController] = {
        guard let storyboard = self.storyboard else {
            return []
        }
        return [
            storyboard.instantiateViewController(withIdentifier: "tip1"),
            storyboard.instantiateViewController(withIdentifier: "tip2"),
            storyboard.instantiateViewController(withIdentifier: "tip3")
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        if let initialController = self.tipControllers.first {
            self.setViewControllers([initialController], direction: .forward, animated: false, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            self.tipsViewControllerDelegate?.didDismissTipsInViewController(self)
        }
    }
    
    // MARK: - Page view controller data source
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.tipControllers.firstIndex(of: viewController), index + 1 < self.tipControllers.count else {
            return nil
        }
        return self.tipControllers[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.tipControllers.firstIndex(of: viewController), index > 0 else {
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
