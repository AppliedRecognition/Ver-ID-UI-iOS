//
//  SessionDiagnosticsViewController.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 06/10/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import AVFoundation

/// View controller that displays the result of a session and facilitates sharing of session result packages
/// - Since: 2.0.0
@objc open class SessionDiagnosticsViewController: UITableViewController {
    
    enum CellType {
        case video, value, faces
    }
    
    class CellData {
        let type: CellType
        init(type: CellType) {
            self.type = type
        }
    }
    
    class VideoCellData: CellData {
        let videoURL: URL
        init(url: URL) {
            self.videoURL = url
            super.init(type: .video)
        }
    }
    
    class FacesCellData: CellData {
        let images: [UIImage]
        init(images: [UIImage]) {
            self.images = images
            super.init(type: .faces)
        }
    }
    
    class ValueCellData: CellData {
        let title: String
        let value: String
        init(title: String, value: String) {
            self.title = title
            self.value = value
            super.init(type: .value)
        }
    }
    
    public weak var delegate: SessionDiagnosticsViewControllerDelegate?
    
    var sessionResultPackage: SessionResultPackage!
    var sections: [(String,[CellData])] = []
    lazy var bgQueue = OperationQueue()
    
    /// Create an instance of the view controller
    /// - Parameter sessionResultPackage: The session result package to display
    /// - Returns: View controller instance
    @objc public static func create(sessionResultPackage: SessionResultPackage) -> SessionDiagnosticsViewController {
        let viewController = UIStoryboard(name: "SessionDiagnostics", bundle: ResourceHelper.bundle).instantiateInitialViewController() as! SessionDiagnosticsViewController
        viewController.sessionResultPackage = sessionResultPackage
        return viewController
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let op = BlockOperation()
        op.addExecutionBlock { [weak op, weak self] in
            guard let `self` = self, let `op` = op else {
                return
            }
            let timeFormatter = DateComponentsFormatter()
            timeFormatter.allowedUnits = [.second,.minute]
            timeFormatter.allowsFractionalUnits = false
            timeFormatter.unitsStyle = .short
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            var sections = [(String,[CellData])]()
            if let videoURL = self.sessionResultPackage.result.videoURL {
                sections.append(("Video",[VideoCellData(url: videoURL)]))
            }
            let images: [UIImage] = self.sessionResultPackage.result.faceCaptures.map({ $0.faceImage })
            if !images.isEmpty {
                sections.append(("Faces",[FacesCellData(images: images)]))
            }
            var resultData: [CellData] = [ValueCellData(title: "Succeeded", value: self.sessionResultPackage.result.error == nil ? "Yes" : "No")]
            if let error = self.sessionResultPackage.result.error {
                resultData.append(ValueCellData(title: "Error", value: "\(error)"))
            }
            resultData.append(ValueCellData(title: "Started", value: dateFormatter.string(from: self.sessionResultPackage.result.startTime)))
            if let duration = self.sessionResultPackage.result.duration, let durationFormatted = timeFormatter.string(from: duration) {
                resultData.append(ValueCellData(title: "Session duration", value: durationFormatted))
                if let diagnostics = self.sessionResultPackage.result.sessionDiagnostics {
                    let facesPerSecond = String(format: "%.01f faces/second", Float(diagnostics.imageInfo.count)/Float(duration))
                    resultData.append(ValueCellData(title: "Face detection rate", value: facesPerSecond))
                }
            }
            if let authSessionResult = self.sessionResultPackage.result as? AuthenticationSessionResult {
                resultData.append(ValueCellData(title: "Face comparison score", value: String(format: "%.02f", authSessionResult.comparisonScore.floatValue)))
                resultData.append(ValueCellData(title: "Authentication score threshold", value: String(format: "%.02f", authSessionResult.authenticationScoreThreshold.floatValue)))
                if let faceTemplateVersion = authSessionResult.comparisonFaceTemplateVersion {
                    resultData.append(ValueCellData(title: "Face template version", value: faceTemplateVersion.stringValue()))
                }
            }
            sections.append(("Session Result",resultData))
            
            var settingsArray: [ValueCellData] = []
            if let expiry = timeFormatter.string(from: self.sessionResultPackage.settings.maxDuration) {
                settingsArray.append(ValueCellData(title: "Maximum duration", value: expiry))
            }
            settingsArray.append(ValueCellData(title: "Face capture count", value: "\(self.sessionResultPackage.settings.faceCaptureCount)"))
            settingsArray.append(ValueCellData(title: "Yaw threshold", value: String(format: "%.01f", self.sessionResultPackage.settings.yawThreshold)))
            settingsArray.append(ValueCellData(title: "Pitch threshold", value: String(format: "%.01f", self.sessionResultPackage.settings.pitchThreshold)))
            settingsArray.append(ValueCellData(title: "Required initial face width", value: String(format: "%.0f %%", self.sessionResultPackage.settings.expectedFaceExtents.proportionOfViewWidth * 100)))
            settingsArray.append(ValueCellData(title: "Required initial face height", value: String(format: "%.0f %%", self.sessionResultPackage.settings.expectedFaceExtents.proportionOfViewHeight * 100)))
            if let pause = timeFormatter.string(from: self.sessionResultPackage.settings.pauseDuration) {
                settingsArray.append(ValueCellData(title: "Pause duration", value: pause))
            }
            settingsArray.append(ValueCellData(title: "Face capture face count", value: "\(self.sessionResultPackage.settings.faceCaptureFaceCount)"))
            sections.append(("Session Settings", settingsArray))
            
            var environmentArray: [ValueCellData] = [
                ValueCellData(title: "Ver-ID version", value: self.sessionResultPackage.environmentSettings.veridVersion),
                ValueCellData(title: "Application ID", value: self.sessionResultPackage.environmentSettings.applicationId),
                ValueCellData(title: "Application version", value: self.sessionResultPackage.environmentSettings.applicationVersion),
                ValueCellData(title: "Device model", value: self.sessionResultPackage.environmentSettings.deviceModel),
                ValueCellData(title: "Operating system", value: self.sessionResultPackage.environmentSettings.os)
            ]
            if let templateExtractionThreshold = self.sessionResultPackage.environmentSettings.faceTemplateExtractionThreshold {
                environmentArray.append(ValueCellData(title: "Face template extraction threshold", value: String(format: "%.01f", templateExtractionThreshold)))
            }
            if let detectorVersion = self.sessionResultPackage.environmentSettings.faceDetectorVersion {
                environmentArray.append(ValueCellData(title: "Face detector version", value: String(format: "%d", detectorVersion)))
            }
            if let confidenceThreshold = self.sessionResultPackage.environmentSettings.confidenceThreshold {
                environmentArray.append(ValueCellData(title: "Confidence threshold", value: String(format: "%.01f", confidenceThreshold)))
            }
            sections.append(("Environment", environmentArray))
            
            if !op.isCancelled {
                DispatchQueue.main.async {
                    self.sections = sections
                    self.tableView.reloadData()
                }
            }
        }
        self.bgQueue.addOperation(op)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bgQueue.cancelAllOperations()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { context in
            if !context.isCancelled {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        self.sections.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.sections[section].1.count
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.sections[section].0
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.cellData(at: indexPath).type {
        case .video:
            return 300
        case .faces:
            return 100
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let videoData = self.cellData(at: indexPath) as? VideoCellData, let cell = tableView.dequeueReusableCell(withIdentifier: "video") as? VideoTableCell {
            cell.videoURL = videoData.videoURL
            return cell
        } else if let facesData = self.cellData(at: indexPath) as? FacesCellData, let cell = tableView.dequeueReusableCell(withIdentifier: "faces") as? FacesTableCell {
            let imageViews: [UIImageView] = facesData.images.map({ image in
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFill
                imageView.layer.masksToBounds = true
                imageView.layer.cornerRadius = 8
                imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 4/5))
                return imageView
            })
            cell.stackView.arrangedSubviews.forEach({
                cell.stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            })
            imageViews.forEach({ imageView in
                cell.stackView.addArrangedSubview(imageView)
            })
            return cell
        } else if let data = self.cellData(at: indexPath) as? ValueCellData, let cell = tableView.dequeueReusableCell(withIdentifier: "value") {
            cell.textLabel?.text = data.title
            cell.detailTextLabel?.text = data.value
            return cell
        } else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let videoCell = cell as? VideoTableCell {
            videoCell.contentView.layer.sublayers?.compactMap({ $0 as? AVPlayerLayer }).first?.frame = videoCell.contentView.bounds
        }
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.cellData(at: indexPath).type == .value, let cellData = self.cellData(at: indexPath) as? ValueCellData, cellData.title == "Error" {
            let alert = UIAlertController(title: cellData.title, message: cellData.value, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Sharing
    
    /// Invoke action to share the session result package
    /// - Parameter button: Bar button that invoked the action
    /// - Since: 2.0.0
    @IBAction open func share(_ button: UIBarButtonItem) {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        self.bgQueue.addOperation {
            do {
                let archive = try self.sessionResultPackage.createArchive()
                let shareItem = self.sessionResultPackage.createItemActivityProvider(archiveURL: archive)
                OperationQueue.main.addOperation {
                    if !self.isViewLoaded {
                        return
                    }
                    self.navigationItem.rightBarButtonItem = button
                    let activityViewController = UIActivityViewController(activityItems: [shareItem], applicationActivities: self.delegate?.applicationActivities)
                    activityViewController.popoverPresentationController?.barButtonItem = button
                    activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                        self.delegate?.activityCompletionHandler?(activityType, completed, returnedItems, error)
                        try? FileManager.default.removeItem(at: archive)
                    }
                    self.present(activityViewController, animated: true)
                }
            } catch {
                OperationQueue.main.addOperation {
                    if !self.isViewLoaded {
                        return
                    }
                    self.navigationItem.rightBarButtonItem = button
                    let alert = UIAlertController(title: "Unable to share session", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func cellData(at indexPath: IndexPath) -> CellData {
        self.sections[indexPath.section].1[indexPath.row]
    }
    
}

public protocol SessionDiagnosticsViewControllerDelegate: AnyObject {
    
    var applicationActivities: [UIActivity]? { get }
    
    var activityCompletionHandler: UIActivityViewController.CompletionWithItemsHandler? { get }
}

class FacesTableCell: UITableViewCell {
    
    @IBOutlet var stackView: UIStackView!
}

class VideoTableCell: UITableViewCell {
    
    var looper: AVPlayerLooper?
    
    var videoURL: URL? {
        didSet {
            self.contentView.layer.sublayers?.removeAll()
            if let url = videoURL {
                let playerItem = AVPlayerItem(url: url)
                let player = AVQueuePlayer()
                self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.contentView.bounds
                playerLayer.videoGravity = .resizeAspectFill
                self.contentView.layer.addSublayer(playerLayer)
                player.play()
            } else {
                if let looper = self.looper {
                    looper.disableLooping()
                    self.looper = nil
                }
            }
        }
    }
}
