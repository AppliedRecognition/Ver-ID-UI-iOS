//
//  SessionViewControllersFactory.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 06/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

import Foundation
import VerIDCore

/// Protocol for a factory that creates view controllers used by Ver-ID session
public protocol SessionViewControllersFactory {
    func makeVerIDViewController() throws -> UIViewController & VerIDViewControllerProtocol & ImageProviderService
    func makeResultViewController(result: SessionResult) throws -> UIViewController & ResultViewControllerProtocol
    func makeTipsViewController() throws -> UIViewController & TipsViewControllerProtocol
}

public enum VerIDSessionViewControllersFactoryError: Int, Error {
    case failedToCreateInstance
}

public class VerIDSessionViewControllersFactory: SessionViewControllersFactory {
    
    public let settings: SessionSettings
    
    public init(settings: SessionSettings) {
        self.settings = settings
    }
    
    public func makeVerIDViewController() throws -> UIViewController & VerIDViewControllerProtocol & ImageProviderService {
        if self.settings is RegistrationSessionSettings {
            return VerIDRegistrationViewController()
        } else {
            return VerIDViewController(nibName: nil)
        }
    }
    
    public func makeResultViewController(result: SessionResult) throws -> UIViewController & ResultViewControllerProtocol {
        let bundle = Bundle(for: type(of: self))
        let storyboard = UIStoryboard(name: "Result", bundle: bundle)
        let storyboardId = result.error != nil ? "failure" : "success"
        guard let resultViewController = storyboard.instantiateViewController(withIdentifier: storyboardId) as? ResultViewController else {
            throw VerIDSessionViewControllersFactoryError.failedToCreateInstance
        }
        resultViewController.result = result
        resultViewController.settings = self.settings
        return resultViewController
    }
    
    public func makeTipsViewController() throws -> UIViewController & TipsViewControllerProtocol {
        let bundle = Bundle(for: type(of: self))
        guard let tipsController = UIStoryboard(name: "Tips", bundle: bundle).instantiateInitialViewController() as? TipsViewController else {
            throw VerIDSessionViewControllersFactoryError.failedToCreateInstance
        }
        return tipsController
    }
    
    
}
