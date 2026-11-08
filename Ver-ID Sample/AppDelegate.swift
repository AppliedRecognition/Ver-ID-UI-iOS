//
//  AppDelegate.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 20/01/2016.
//  Copyright © 2016 Applied Recognition, Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: BaseAppDelegate {
}

/// Scene delegate
///
/// UIKit requires apps built with the iOS 26 SDK and later to adopt the UIScene lifecycle,
/// so the scene owns the window and the app delegate drives navigation through it.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let appDelegate = UIApplication.shared.delegate as? BaseAppDelegate else {
            return
        }
        if self.window == nil, let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            self.window = window
        }
        appDelegate.window = self.window
        self.window?.makeKeyAndVisible()
        appDelegate.sceneDidConnect(connectionOptions: connectionOptions)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        (UIApplication.shared.delegate as? BaseAppDelegate)?.openRegistrationURLs(URLContexts.map({ $0.url }))
    }
}

