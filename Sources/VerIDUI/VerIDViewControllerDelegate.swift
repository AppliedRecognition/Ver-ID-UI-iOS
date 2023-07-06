//
//  VerIDViewControllerDelegate.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 04/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import UIKit
import CoreMedia
import VerIDCore

/// Ver-ID view controller delegate protocol
@objc public protocol VerIDViewControllerDelegate: AnyObject {
    
    /// Called when the user cancels the session, e.g., by tapping the cancel button
    ///
    /// - Parameter viewController: View controller from which the session was canceled
    @objc func viewControllerDidCancel(_ viewController: VerIDViewControllerProtocol)
    
    /// Signals that the view controller failed and cannot continue displaying the result of the session
    ///
    /// - Parameters:
    ///   - viewController: View controller that failed
    ///   - error: Error that caused the failure
    @objc func viewController(_ viewController: VerIDViewControllerProtocol, didFailWithError error: Error)
}
