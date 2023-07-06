//
//  VerIDSessionViewDelegate.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 01/08/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit

/// Delegate that manages presenting views in a Ver-ID session
@objc public protocol VerIDSessionViewDelegate {
    
    /// Present a view controller that supplies images to the Ver-ID session
    ///
    /// - Parameter viewController: View controller that supplies images to the Ver-ID session
    @objc func presentVerIDViewController(_ viewController: UIViewController & VerIDViewControllerProtocol)
    
    /// Present a view controller showing the result of the Ver-ID session
    ///
    /// - Parameter viewController: View controller showing the result of the Ver-ID session
    @objc func presentResultViewController(_ viewController: UIViewController & ResultViewControllerProtocol)
    
    /// Present a view controller showing tips on how to sucessfully complete a Ver-ID session
    ///
    /// - Parameter viewController: View controller showing tips on how to sucessfully complete a Ver-ID session
    @objc func presentTipsViewController(_ viewController: UIViewController & TipsViewControllerProtocol)
    
    /// Close all views associated with the Ver-ID session
    ///
    /// - Parameter callback: Block to invoke when the views have been closed
    @objc func closeViews(callback: @escaping () -> Void)
}
