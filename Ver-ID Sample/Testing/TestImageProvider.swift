//
//  TestImageProvider.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 15/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import Foundation
import VerIDCore

class TestImageProviderService: ImageProviderService {
    
    func dequeueImage() throws -> VerIDImage {
        let size = CGSize(width: 4, height: 4)
        return VerIDImage(grayscalePixels: [UInt8](repeating: 0, count: Int(size.width*size.height)), size: size)
    }
}

class TestImageProviderServiceFactory: ImageProviderServiceFactory {
    
    func makeImageProviderService() -> ImageProviderService {
        TestImageProviderService()
    }
}
