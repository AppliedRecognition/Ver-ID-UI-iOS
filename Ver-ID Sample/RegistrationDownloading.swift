//
//  RegistrationDownloading.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 26/11/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import Foundation

protocol RegistrationDownloading {
    func downloadRegistration(_ url: URL, completion: @escaping (RegistrationData?) -> Void)
}
