//
//  RegistrationImport.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 06/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

class RegistrationImport {
    
    static func importFromURL(_ url: URL, verid: VerID, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                guard let profilePicURL = Globals.profilePictureURL else {
                    throw NSError(domain: kVerIDErrorDomain, code: 303, userInfo: [NSLocalizedDescriptionKey:"Missing profile picture"])
                }
                let registrationData = try RegistrationImport.registrationData(from: url)
                try registrationData.profilePicture.write(to: profilePicURL, options: .atomicWrite)
                verid.userManagement.assignFaces(registrationData.faces, toUser: VerIDUser.defaultUserId, completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    static func registrationData(from url: URL) throws -> RegistrationData {
        let data = try Data(contentsOf: url)
        let registrationData = try JSONDecoder().decode(RegistrationData.self, from: data)
        if registrationData.faces.isEmpty {
            throw NSError(domain: kVerIDErrorDomain, code: 302, userInfo: [NSLocalizedDescriptionKey:"Registration has no faces"])
        }
        return registrationData
    }
}
