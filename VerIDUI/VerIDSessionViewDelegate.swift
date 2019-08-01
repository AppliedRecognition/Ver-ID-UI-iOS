//
//  VerIDSessionViewDelegate.swift
//  VerIDCore
//
//  Created by Jakub Dolejs on 01/08/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import Foundation

@objc public protocol VerIDSessionViewDelegate {
    
    @objc func presentVerIDViewController(_ viewController: UIViewController & VerIDViewControllerProtocol)
    
    @objc func presentResultViewController(_ viewController: UIViewController & ResultViewControllerProtocol)
    
    @objc func presentTipsViewController(_ viewController: UIViewController & TipsViewControllerProtocol)
    
    @objc func closeViews(callback: @escaping () -> Void)
}
