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

