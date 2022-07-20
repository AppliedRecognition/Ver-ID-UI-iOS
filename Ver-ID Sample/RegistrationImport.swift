//
//  RegistrationImport.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 06/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore
import VerIDSerialization
import SwiftProtobuf

class RegistrationImport {
    
    static func importFromURL(_ url: URL, verid: VerID, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                guard let profilePicURL = Globals.profilePictureURL else {
                    throw NSError(domain: kVerIDErrorDomain, code: 303, userInfo: [NSLocalizedDescriptionKey:"Missing profile picture"])
                }
                let registration = try RegistrationImport.registration(from: url)
                try registration.image.pngData()?.write(to: profilePicURL, options: .atomic)
                verid.userManagement.assignFaces(registration.faces, toUser: VerIDUser.defaultUserId, completion: completion)
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    static func registration(from url: URL) throws -> Registration {
        let data = try Data(contentsOf: url)
        let registration: Registration = try Deserializer.deserialize(data)
        if registration.faces.isEmpty {
            throw NSError(domain: kVerIDErrorDomain, code: 302, userInfo: [NSLocalizedDescriptionKey:"Registration has no faces"])
        }
        return registration
    }
}
