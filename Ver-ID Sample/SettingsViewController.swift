//
//  SettingsViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

class SettingsViewController: UITableViewController, SecuritySettingsDelegate, ValueSelectionDelegate {
    
    @IBOutlet var securityProfileCell: UITableViewCell!
    @IBOutlet var registrationFaceCountCell: UITableViewCell!
    @IBOutlet var templateEncryptionCell: UITableViewCell!
    @IBOutlet var speakPromptsCell: UITableViewCell!
    @IBOutlet var backCameraCell: UITableViewCell!
    @IBOutlet var recordSessionVideoCell: UITableViewCell!
    @IBOutlet var versionCell: UITableViewCell!
    @IBOutlet var faceWidthFractionCell: UITableViewCell!
    @IBOutlet var faceHeightFractionCell: UITableViewCell!
    @IBOutlet var faceCoveringDetectionCell: UITableViewCell!
    @IBOutlet var sunglassesDetectionCell: UITableViewCell!
    @IBOutlet var confidenceThresholdCell: UITableViewCell!
    @IBOutlet var detectorVersionCell: UITableViewCell!
    @IBOutlet var templateExtractionThresholdCell: UITableViewCell!
    
    enum Section: Int, CaseIterable {
        case about, registration, security, faceDetection, accessibility, camera
    }
    
    let registrationFaceCounts: [Int] = [1,3]
    let faceDetectorVersions: [Int] = [6,7]
    let confidenceThresholds: [Float] = [Float](stride(from:-0.5, through: 1, by: 0.25))
    var isDirty: Bool = false
    var faceWidthFractionObservation: NSKeyValueObservation?
    var faceHeightFractionObservation: NSKeyValueObservation?
    var confidenceThresholdObservation: NSKeyValueObservation?
    var faceTemplateExtractionThresholdObservation: NSKeyValueObservation?
    var faceTemplateEncryptionObservation: NSKeyValueObservation?
    var faceDetectorVersionObservation: NSKeyValueObservation?
    var useSpoofDeviceDetectorObservation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadFromDefaults()
        self.versionCell.detailTextLabel?.text = Bundle(for: VerID.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        self.faceWidthFractionObservation = UserDefaults.standard.observe(\.faceWidthFraction, options: [.initial,.new]) { userDefaults, _ in
            self.faceWidthFractionCell.detailTextLabel?.text = String(format: "%.0f%%", userDefaults.faceWidthFraction * 100)
        }
        self.faceHeightFractionObservation = UserDefaults.standard.observe(\.faceHeightFraction, options: [.initial,.new]) { userDefaults, _ in
            self.faceHeightFractionCell.detailTextLabel?.text = String(format: "%.0f%%", userDefaults.faceHeightFraction * 100)
        }
        self.confidenceThresholdObservation = UserDefaults.standard.observe(\.confidenceThreshold, options: [.new], changeHandler: self.defaultsChangeHandler)
        self.faceDetectorVersionObservation = UserDefaults.standard.observe(\.faceDetectorVersion, options: [.new], changeHandler: self.defaultsChangeHandler)
        self.faceTemplateExtractionThresholdObservation = UserDefaults.standard.observe(\.faceTemplateExtractionThreshold, options: [.new], changeHandler: self.defaultsChangeHandler)
        self.faceTemplateEncryptionObservation = UserDefaults.standard.observe(\.encryptFaceTemplates, options: [.new], changeHandler: self.defaultsChangeHandler)
        self.useSpoofDeviceDetectorObservation = UserDefaults.standard.observe(\.useSpoofDeviceDetector, options: [.new], changeHandler: self.defaultsChangeHandler)
    }
    
    func defaultsChangeHandler<T>(_ defaults: UserDefaults,_ change: NSKeyValueObservedChange<T>) {
        self.isDirty = true
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            self.faceWidthFractionObservation = nil
            self.faceHeightFractionObservation = nil
            self.confidenceThresholdObservation = nil
            self.faceTemplateExtractionThresholdObservation = nil
            self.faceTemplateEncryptionObservation = nil
            self.faceDetectorVersionObservation = nil
            if self.isDirty {
                (UIApplication.shared.delegate as? AppDelegate)?.reload()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionEnum = Section(rawValue: section) else {
            return 0
        }
        switch sectionEnum {
        case .faceDetection:
            return 5
        case .about, .registration, .camera:
            return 2
        case .security:
            return 3
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.camera.rawValue {
            if indexPath.row == 0 {
                UserDefaults.standard.useBackCamera = !UserDefaults.standard.useBackCamera
            } else if indexPath.row == 1 {
                UserDefaults.standard.enableVideoRecording = !UserDefaults.standard.enableVideoRecording
            }
        } else if indexPath.section == Section.registration.rawValue && indexPath.row == 1 {
            UserDefaults.standard.encryptFaceTemplates = !UserDefaults.standard.encryptFaceTemplates
        } else if indexPath.section == Section.accessibility.rawValue && indexPath.row == 0 {
            UserDefaults.standard.speakPrompts = !UserDefaults.standard.speakPrompts
        } else if indexPath.section == Section.faceDetection.rawValue && indexPath.row == 1 {
            UserDefaults.standard.enableFaceCoveringDetection = !UserDefaults.standard.enableFaceCoveringDetection
        } else if indexPath.section == Section.faceDetection.rawValue && indexPath.row == 2 {
            UserDefaults.standard.enableSunglassesDetection = !UserDefaults.standard.enableSunglassesDetection
        } else {
            return
        }
        self.loadFromDefaults()
    }
    
    func loadFromDefaults() {
        let poseCount: Int = UserDefaults.standard.poseCount
        let yawThreshold: Float = UserDefaults.standard.yawThreshold
        let pitchThreshold: Float = UserDefaults.standard.pitchThreshold
        let authThresholds: [VerIDFaceTemplateVersion: Float]
        if let faceRec = Globals.verid?.faceRecognition as? VerIDFaceRecognition {
            let thresholds: [(VerIDFaceTemplateVersion,Float)] = VerIDFaceTemplateVersion.all.sorted(by: { $0.rawValue < $1.rawValue }).map({ ($0,faceRec.authenticationScoreThreshold(faceTemplateVersion: $0).floatValue) })
            authThresholds = Dictionary(uniqueKeysWithValues: thresholds)
        } else {
            authThresholds = [:]
        }
        let registrationPoseCount: Int = UserDefaults.standard.registrationFaceCount
        let securityPreset = SecuritySettingsPreset(poseCount: poseCount, yawThreshold: yawThreshold, pitchThreshold: pitchThreshold, authThresholds: authThresholds, poses: UserDefaults.standard.poses, useSpoofDeviceDetector: UserDefaults.standard.useSpoofDeviceDetector)
        switch securityPreset {
        case .low:
            self.securityProfileCell.detailTextLabel?.text = "Low"
        case .normal:
            self.securityProfileCell.detailTextLabel?.text = "Normal"
        case .high:
            self.securityProfileCell.detailTextLabel?.text = "High"
        default:
            self.securityProfileCell.detailTextLabel?.text = "Custom"
        }
        self.registrationFaceCountCell.detailTextLabel?.text = registrationPoseCount > 1 ? String(format: "%d faces", registrationPoseCount) : "1 face"
        let useBackCamera = UserDefaults.standard.useBackCamera
        backCameraCell.accessoryType = useBackCamera ? .checkmark : .none
        let recordSessionVideo = UserDefaults.standard.enableVideoRecording
        recordSessionVideoCell.accessoryType = recordSessionVideo ? .checkmark : .none
        let speakPrompts = UserDefaults.standard.speakPrompts
        speakPromptsCell.accessoryType = speakPrompts ? .checkmark : .none
        let encryptTemplates = UserDefaults.standard.encryptFaceTemplates
        templateEncryptionCell.accessoryType = encryptTemplates ? .checkmark : .none
        faceCoveringDetectionCell.accessoryType = UserDefaults.standard.enableFaceCoveringDetection ? .checkmark : .none
        sunglassesDetectionCell.accessoryType = UserDefaults.standard.enableSunglassesDetection ? .checkmark : .none
        confidenceThresholdCell.detailTextLabel?.text = String(format: "%.02f", UserDefaults.standard.confidenceThreshold)
        detectorVersionCell.detailTextLabel?.text = String(format: "%d", UserDefaults.standard.faceDetectorVersion)
        templateExtractionThresholdCell.detailTextLabel?.text = String(format: "%.0f", UserDefaults.standard.faceTemplateExtractionThreshold)
    }
    
    // MARK: - Security profile
    
    func securitySettingsViewController(_ securitySettingsViewController: SecuritySettingsViewController, didSetProfile profile: String) {
        self.securityProfileCell.detailTextLabel?.text = profile
    }
    
    // MARK: - Registration face count
    
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValue value: String, atIndex index: Int) {
        self.navigationController?.popViewController(animated: true)
        if valueSelectionViewController.title == "Registration Face Count" {
            UserDefaults.standard.registrationFaceCount = self.registrationFaceCounts[index]
        } else if valueSelectionViewController.title == "Face Detector" {
            UserDefaults.standard.faceDetectorVersion = self.faceDetectorVersions[index]
        } else if valueSelectionViewController.title == "Face Det. Confidence Threshold" {
            UserDefaults.standard.confidenceThreshold = self.confidenceThresholds[index]
        }
        self.loadFromDefaults()
    }
    
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValues values: [String], atIndices: [Int]) {
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SecuritySettingsViewController {
            destination.delegate = self
        } else if let destination = segue.destination as? ValueSelectionViewController {
            destination.delegate = self
            if segue.identifier == "registrationFaceCount" {
                destination.values = ["1 face","3 faces"]
                destination.title = "Registration Face Count"
                if UserDefaults.standard.registrationFaceCount == 1 {
                    destination.selectedIndex = 0
                } else {
                    destination.selectedIndex = 1
                }
            } else if segue.identifier == "faceDetectorVersion" {
                destination.values = self.faceDetectorVersions.map({ String(format: "Version %d", $0) })
                destination.title = "Face Detector"
                destination.selectedIndex = self.faceDetectorVersions.firstIndex(where: { $0 == UserDefaults.standard.faceDetectorVersion }) ?? 0
            } else if segue.identifier == "confidenceThreshold" {
                destination.values = self.confidenceThresholds.map({ String(format: "%.02f", $0)})
                destination.title = "Face Det. Confidence Threshold"
                destination.selectedIndex = self.confidenceThresholds.firstIndex(where: { $0 == UserDefaults.standard.confidenceThreshold }) ?? 0
            }
        } else if let destination = segue.destination as? IntroViewController {
            destination.showRegisterButton = false
        }
    }

}
