//
//  RegistrationUploading.swift
//  VerIDSample
//
//  Created by Jakub Dolejs on 26/11/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import Foundation

protocol RegistrationUploading {
    func uploadRegistration(_ registrationData: RegistrationData, completion: @escaping (URL?) -> Void)
}
