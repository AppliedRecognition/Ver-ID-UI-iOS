//
//  S3UploadActivity.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 15/04/2020.
//  Copyright © 2020 Applied Recognition. All rights reserved.
//

import UIKit

enum NotImplementedException: Error {
    case classNotImplemented
}

extension UIActivity.ActivityType {
    static let s3Upload = UIActivity.ActivityType("com.appliedrec.s3upload")
}

class S3UploadActivity: UIActivity {
    
    init(bucket: String) throws {
        throw NotImplementedException.classNotImplemented
    }
}
