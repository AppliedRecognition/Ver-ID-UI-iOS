//
//  ThumbnailProvider.swift
//  Thumbnails
//
//  Created by Jakub Dolejs on 07/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import ZIPFoundation
import AVFoundation
import QuickLookThumbnailing

@available(iOS 11.0, *)
class ThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
        
        // First way: Draw the thumbnail into the current context, set up with UIKit's coordinate system.
        
        if request.fileURL.pathExtension == "registration" {
            do {
                let registration = try RegistrationImport.registration(from: request.fileURL)
                let reply = QLThumbnailReply(contextSize: request.maximumSize) {
                    let rect = AVMakeRect(aspectRatio: request.maximumSize, insideRect: CGRect(origin: .zero, size: registration.image.size))
                    let scale = request.maximumSize.width / rect.width
                    let cropRect = CGRect(origin: CGPoint(x: 0-rect.minX*scale, y: 0-rect.minY*scale), size: registration.image.size.applying(CGAffineTransform(scaleX: scale, y: scale)))
                    registration.image.draw(in: cropRect)
                    return true
                }
                DispatchQueue.main.async {
                    handler(reply, nil)
                }
            } catch {
                handler(nil, error)
            }
        }
        
        /*
        
        // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            // Draw the thumbnail here.
         
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
         
        // Third way: Set an image file URL.
        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "fileThumbnail", withExtension: "jpg")!), nil)
        
        */
    }
}
