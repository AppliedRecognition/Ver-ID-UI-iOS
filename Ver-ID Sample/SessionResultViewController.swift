//
//  SessionResultViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 05/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import AVFoundation
import ZIPFoundation
import DeviceKit

class SessionResultViewController: UITableViewController {
    
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
    
    @IBOutlet var videoView: UIView!
    private var looper: AVPlayerLooper?
    var sessionTime: Date = Date()
    var sessionSettings: VerIDSessionSettings?
    var sessionResult: VerIDSessionResult?
    var environmentSettings: EnvironmentSettings?
    var uploadedToS3: Bool = false
    var sections: [(String,[CellData])] = []
    lazy var bgQueue = OperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.environmentSettings = EnvironmentSettings(
            confidenceThreshold: -0.5,
            faceTemplateExtractionThreshold: 8.0,
            authenticationThreshold: Globals.verid?.faceRecognition.authenticationScoreThreshold.floatValue ?? 4.0,
            deviceModel: "\(Device.current)",
            os: UIDevice.current.systemName+" "+UIDevice.current.systemVersion,
            applicationId: Bundle.main.bundleIdentifier ?? "unknown",
            applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            veridVersion: Bundle(for: VerID.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        )
        self.navigationItem.title = self.title
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
            if let videoURL = self.sessionResult?.videoURL {
                sections.append(("Video",[VideoCellData(url: videoURL)]))
            }
            if let result = self.sessionResult {
                let images: [UIImage] = result.faceCaptures.map({ $0.faceImage })
                if !images.isEmpty {
                    sections.append(("Faces",[FacesCellData(images: images)]))
                }
                var resultData: [CellData] = [ValueCellData(title: "Succeeded", value: result.error == nil ? "Yes" : "No")]
                if let error = result.error {
                    resultData.append(ValueCellData(title: "Error", value: "\(error)"))
                }
                resultData.append(ValueCellData(title: "Started", value: dateFormatter.string(from: result.startTime)))
                if let duration = result.duration, let durationFormatted = timeFormatter.string(from: duration) {
                    resultData.append(ValueCellData(title: "Session duration", value: durationFormatted))
                    if let diagnostics = result.sessionDiagnostics {
                        let facesPerSecond = String(format: "%.01f faces/second", Float(diagnostics.imageInfo.count)/Float(duration))
                        resultData.append(ValueCellData(title: "Face detection rate", value: facesPerSecond))
                    }
                }
                sections.append(("Session Result",resultData))
            }
            if let settings = self.sessionSettings {
                var settingsArray: [ValueCellData] = []
                if let expiry = timeFormatter.string(from: settings.maxDuration) {
                    settingsArray.append(ValueCellData(title: "Expiry time", value: expiry))
                }
                settingsArray.append(ValueCellData(title: "Number of results to collect", value: "\(settings.faceCaptureCount)"))
//                settingsArray.append(ValueCellData(title: "Using back camera", value: settings.useFrontCamera ? "No" : "Yes"))
                settingsArray.append(ValueCellData(title: "Maximum retry count", value: "\(settings.maxRetryCount)"))
                settingsArray.append(ValueCellData(title: "Yaw threshold", value: String(format: "%.01f", settings.yawThreshold)))
                settingsArray.append(ValueCellData(title: "Pitch threshold", value: String(format: "%.01f", settings.pitchThreshold)))
//                settingsArray.append(ValueCellData(title: "Speak prompts", value: settings.speakPrompts ? "Yes" : "No"))
                settingsArray.append(ValueCellData(title: "Required initial face width", value: String(format: "%.0f %%", settings.expectedFaceExtents.proportionOfViewWidth * 100)))
                settingsArray.append(ValueCellData(title: "Required initial face height", value: String(format: "%.0f %%", settings.expectedFaceExtents.proportionOfViewHeight * 100)))
                if let pause = timeFormatter.string(from: settings.pauseDuration) {
                    settingsArray.append(ValueCellData(title: "Pause duration", value: pause))
                }
                settingsArray.append(ValueCellData(title: "Face buffer size", value: "\(settings.faceCaptureFaceCount)"))
                sections.append(("Session Settings", settingsArray))
            }
            if let environment = self.environmentSettings {
                sections.append(("Environment", [
                    ValueCellData(title: "Ver-ID version", value: environment.veridVersion),
                    ValueCellData(title: "Authentication threshold", value: String(format: "%.01f", environment.authenticationThreshold)),
                    ValueCellData(title: "Face template extraction threshold", value: String(format: "%.01f", environment.faceTemplateExtractionThreshold)),
                    ValueCellData(title: "Confidence threshold", value: String(format: "%.01f", environment.confidenceThreshold))
                ]))
            }
            if !op.isCancelled {
                DispatchQueue.main.async {
                    self.sections = sections
                    self.tableView.reloadData()
                }
            }
        }
        self.bgQueue.addOperation(op)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bgQueue.cancelAllOperations()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { context in
            if !context.isCancelled {
                self.tableView.reloadData()
            }
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        guard parent == nil else {
            return
        }
        if let result = self.sessionResult {
            Globals.deleteImagesInSessionResult(result)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.sections[section].1.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.sections[section].0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.cellData(at: indexPath).type {
        case .video:
            return 300
        case .faces:
            return 100
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let videoCell = cell as? VideoTableCell {
            videoCell.contentView.layer.sublayers?.compactMap({ $0 as? AVPlayerLayer }).first?.frame = videoCell.contentView.bounds
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.cellData(at: indexPath).type == .value, let cellData = self.cellData(at: indexPath) as? ValueCellData, cellData.title == "Error" {
            let alert = UIAlertController(title: cellData.title, message: cellData.value, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func cellData(at indexPath: IndexPath) -> CellData {
        self.sections[indexPath.section].1[indexPath.row]
    }
    
    func createShareItem() throws -> URL {
        guard let settings = self.sessionSettings, let result = self.sessionResult, let environmentSettings = self.environmentSettings else {
            throw NSError(domain: kVerIDErrorDomain, code: 204, userInfo: [NSLocalizedDescriptionKey:"Failed to gather assets"])
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let name = dateFormatter.string(from: self.sessionTime)
        let zipFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(name).appendingPathExtension("zip")
        guard let archive = Archive(url: zipFileURL, accessMode: .create) else {
            throw NSError(domain: kVerIDErrorDomain, code: 205, userInfo: [NSLocalizedDescriptionKey:"Unable to create archive"])
        }
        if let videoURL = result.videoURL {
            let videoData = try Data(contentsOf: videoURL)
            try archive.addEntry(with: "video.mov", type: .file, uncompressedSize: UInt32(videoData.count), provider: { position, size in
                videoData[position..<position+size]
            })
        }
        var i = 1
        for faceCapture in result.faceCaptures {
            guard let imageData = faceCapture.image.jpegData(compressionQuality: 0.8) else {
                continue
            }
            try archive.addEntry(with: "image\(i).jpg", type: .file, uncompressedSize: UInt32(imageData.count), provider: { position, size in
                imageData[position..<position+size]
            })
            i += 1
        }
        let settingsJson = try JSONEncoder().encode(SessionSettingsShareItem(settings: settings))
        try archive.addEntry(with: "settings.json", type: .file, uncompressedSize: UInt32(settingsJson.count), provider: { position, size in
            settingsJson[position..<position+size]
        })
        let resultJson = try JSONEncoder().encode(SessionResultShare(sessionResult: result))
        try archive.addEntry(with: "result.json", type: .file, uncompressedSize: UInt32(resultJson.count), provider: { position, size in
            resultJson[position..<position+size]
        })
        let environmentJson = try JSONEncoder().encode(environmentSettings)
        try archive.addEntry(with: "environment.json", type: .file, uncompressedSize: UInt32(environmentJson.count), provider: { position, size in
            environmentJson[position..<position+size]
        })
        return zipFileURL
    }
    
    @IBAction func shareSession(_ button: UIBarButtonItem) {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        DispatchQueue.global().async {
            do {
                guard let settings = self.sessionSettings, let result = self.sessionResult, let environment = self.environmentSettings else {
                    return
                }
                let shareItem = try SessionItemProvider(settings: settings, result: result, environment: environment)
                DispatchQueue.main.async {
                    if !self.isViewLoaded {
                        return
                    }
                    self.navigationItem.rightBarButtonItem = button
                    var activities: [UIActivity]? = self.uploadedToS3 ? nil : []
                    if !self.uploadedToS3, let activity = try? S3UploadActivity(bucket: "ver-id") {
                        activities?.append(activity)
                    }
                    let activityViewController = UIActivityViewController(activityItems: [shareItem], applicationActivities: activities)
                    activityViewController.popoverPresentationController?.barButtonItem = button
                    activityViewController.completionWithItemsHandler = { activityType, completed, items, error in
                        if activityType == .some(.s3Upload) {
                            self.uploadedToS3 = completed
                        }
                        shareItem.cleanup()
                    }
                    self.present(activityViewController, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
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
}

class FaceTableCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var faceImageView: UIImageView!
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
