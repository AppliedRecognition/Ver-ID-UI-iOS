//
//  FaceDetectionAlertController.swift
//  VerID
//
//  Created by Jakub Dolejs on 25/05/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

import UIKit
import AVFoundation

enum FaceDetectionAlertControllerAction {
    case cancel, showTips, retry
}

class FaceDetectionAlertController: UIViewController {
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var messageLabelBackgroundView: UIView!
    @IBOutlet var videoView: UIView!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var tipsButton: UIButton!
    @IBOutlet var retryButton: UIButton!
    @IBOutlet var stackView: UIStackView!
    
    let message: String?
    let videoURL: URL?
    var delegate: FaceDetectionAlertControllerDelegate?
    var looper: Any?
    
    public init(message: String?, videoURL: URL?, delegate: FaceDetectionAlertControllerDelegate) {
        self.message = message
        self.videoURL = videoURL
        self.delegate = delegate
        super.init(nibName: "FaceDetectionAlertController", bundle: Bundle(for: type(of: self)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.message != nil {
            self.messageLabel.text = self.message!
        } else {
            self.stackView.removeArrangedSubview(self.messageLabelBackgroundView)
        }
        if self.videoURL == nil {
            self.stackView.removeArrangedSubview(self.videoView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let url = self.videoURL {
            if #available(iOS 10, *) {
                let playerItem = AVPlayerItem(url: url)
                let player = AVQueuePlayer()
                self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.videoView.bounds
                self.videoView.layer.addSublayer(playerLayer)
                player.play()
            } else {
                let player = AVPlayer(url: url)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.videoView.bounds
                self.videoView.layer.addSublayer(playerLayer)
                player.play()
            }
        }
        let cornerRadius: CGFloat = 12
        let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
        let roundedTopCornersLayer = CAShapeLayer()
        if self.message != nil {
            roundedTopCornersLayer.path = UIBezierPath(roundedRect: self.messageLabelBackgroundView.bounds, byRoundingCorners: [.topLeft,.topRight], cornerRadii: cornerRadii).cgPath
            self.messageLabelBackgroundView.layer.mask = roundedTopCornersLayer
        } else {
            roundedTopCornersLayer.path = UIBezierPath(roundedRect: self.videoView.bounds, byRoundingCorners: [.topLeft,.topRight], cornerRadii: cornerRadii).cgPath
            self.videoView.layer.mask = roundedTopCornersLayer
        }
        let roundedBottomLeftCornerLayer = CAShapeLayer()
        roundedBottomLeftCornerLayer.path = UIBezierPath(roundedRect: self.cancelButton.bounds, byRoundingCorners: .bottomLeft, cornerRadii: cornerRadii).cgPath
        self.cancelButton.layer.mask = roundedBottomLeftCornerLayer
        let roundedBottomRightCornerLayer = CAShapeLayer()
        roundedBottomRightCornerLayer.path = UIBezierPath(roundedRect: self.retryButton.bounds, byRoundingCorners: .bottomRight, cornerRadii: cornerRadii).cgPath
        self.retryButton.layer.mask = roundedBottomRightCornerLayer
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 10, *) {
            (self.looper as? AVPlayerLooper)?.disableLooping()
        }
        self.looper = nil
    }
    
    @IBAction func cancel(_ sender: Any?=nil) {
        delegate?.faceDetectionAlertController(self, didCloseDialogWithAction: .cancel)
    }
    
    @IBAction func showTips(_ sender: Any?=nil) {
        delegate?.faceDetectionAlertController(self, didCloseDialogWithAction: .showTips)
    }
    
    @IBAction func retry(_ sender: Any?=nil) {
        delegate?.faceDetectionAlertController(self, didCloseDialogWithAction: .retry)
    }
}

protocol FaceDetectionAlertControllerDelegate: class {
    func faceDetectionAlertController(_ controller: FaceDetectionAlertController, didCloseDialogWithAction action: FaceDetectionAlertControllerAction)
}
