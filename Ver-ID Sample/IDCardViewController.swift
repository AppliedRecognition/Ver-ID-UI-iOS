//
//  IDCardViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 28/07/2021.
//  Copyright © 2021 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

class IDCardViewController: UIViewController {
    
    var idCardImage: UIImage?
    var face: Face?
    var authenticityScore: Float?
    
    @IBOutlet var cardImageView: UIImageView!
    @IBOutlet var faceImageView: UIImageView!
    @IBOutlet var scoreLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let image = self.idCardImage, let face = self.face, let authScore = self.authenticityScore else {
            return
        }
        self.cardImageView.image = image
        self.scoreLabel.text = String(format: "Score %.02f", authScore)
        UIGraphicsBeginImageContext(face.bounds.size)
        defer {
            UIGraphicsEndImageContext()
        }
        image.draw(at: CGPoint(x: 0-face.bounds.minX, y: 0-face.bounds.minY))
        self.faceImageView.image = UIGraphicsGetImageFromCurrentImageContext()
    }

}
