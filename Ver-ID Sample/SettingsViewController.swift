//
//  SettingsViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

class SettingsViewController: UITableViewController, SecuritySettingsDelegate, FaceDetectionSettingsDelegate, ValueSelectionDelegate {
    
    @IBOutlet var securityProfileCell: UITableViewCell!
    @IBOutlet var faceDetectionProfileCell: UITableViewCell!
    @IBOutlet var registrationFaceCountCell: UITableViewCell!
    @IBOutlet var templateEncryptionCell: UITableViewCell!
    @IBOutlet var speakPromptsCell: UITableViewCell!
    @IBOutlet var backCameraCell: UITableViewCell!
    @IBOutlet var recordSessionVideoCell: UITableViewCell!
    @IBOutlet var versionCell: UITableViewCell!
    @IBOutlet var faceWidthFractionCell: UITableViewCell!
    @IBOutlet var faceHeightFractionCell: UITableViewCell!
    @IBOutlet var maxImageContrastCell: UITableViewCell!
    
    enum Section: Int, CaseIterable {
        case about, security, faceDetection, registration, accessibility, camera
    }
    
    let registrationFaceCounts: [Int] = [1,3]
    let maxImageContrasts: [Double] = [25, 30, 35, 40, 45, 50, 55, 60]
    var isDirty: Bool = false
    var faceWidthFractionObservation: NSKeyValueObservation?
    var faceHeightFractionObservation: NSKeyValueObservation?
    var confidenceThresholdObservation: NSKeyValueObservation?
    var faceTemplateExtractionThresholdObservation: NSKeyValueObservation?
    var faceTemplateEncryptionObservation: NSKeyValueObservation?
    var authenticationThresholdObservation: NSKeyValueObservation?

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
        self.faceTemplateExtractionThresholdObservation = UserDefaults.standard.observe(\.faceTemplateExtractionThreshold, options: [.new], changeHandler: self.defaultsChangeHandler)
        self.faceTemplateEncryptionObservation = UserDefaults.standard.observe(\.encryptFaceTemplates, options: [.new], changeHandler: self.defaultsChangeHandler)
        self.authenticationThresholdObservation = UserDefaults.standard.observe(\.authenticationThreshold, options: [.new]) { userDefaults, _ in
            Globals.verid?.faceRecognition.authenticationScoreThreshold = NSNumber(value: userDefaults.authenticationThreshold)
        }
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
            self.authenticationThresholdObservation = nil
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
        case .about, .registration, .camera, .faceDetection:
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
        } else {
            return
        }
        self.loadFromDefaults()
    }
    
    func loadFromDefaults() {
        let poseCount: Int = UserDefaults.standard.poseCount
        let yawThreshold: Float = UserDefaults.standard.yawThreshold
        let pitchThreshold: Float = UserDefaults.standard.pitchThreshold
        let authThreshold: Float = UserDefaults.standard.authenticationThreshold
        let confidenceThreshold: Float = UserDefaults.standard.confidenceThreshold
        let faceTemplateExtractionThreshold: Float = UserDefaults.standard.faceTemplateExtractionThreshold
        let registrationPoseCount: Int = UserDefaults.standard.registrationFaceCount
        let securityPreset = SecuritySettingsPreset(poseCount: poseCount, yawThreshold: yawThreshold, pitchThreshold: pitchThreshold, authThreshold: authThreshold)
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
        let faceDetectionPreset = FaceDetectionSettingsPreset(confidenceThreshold: confidenceThreshold, templateExtractionThreshold: faceTemplateExtractionThreshold)
        switch faceDetectionPreset {
        case .permissive:
            self.faceDetectionProfileCell.detailTextLabel?.text = "Permissive"
        case .normal:
            self.faceDetectionProfileCell.detailTextLabel?.text = "Normal"
        case .restrictive:
            self.faceDetectionProfileCell.detailTextLabel?.text = "Restrictive"
        default:
            self.faceDetectionProfileCell.detailTextLabel?.text = "Custom"
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
        maxImageContrastCell.detailTextLabel?.text = String(format: "%.0f", UserDefaults.standard.maxFaceImageContrast)
    }
    
    // MARK: - Security profile
    
    func securitySettingsViewController(_ securitySettingsViewController: SecuritySettingsViewController, didSetProfile profile: String) {
        self.securityProfileCell.detailTextLabel?.text = profile
    }
    
    // MARK: - Face detection profile
    
    func faceDetectionSettingsViewController(_ faceDetectionSettingsViewController: FaceDetectionSettingsViewController, didSetProfile profile: String) {
        self.faceDetectionProfileCell.detailTextLabel?.text = profile
    }
    
    // MARK: - Registration face count
    
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValue value: String, atIndex index: Int) {
        self.navigationController?.popViewController(animated: true)
        if valueSelectionViewController.title == "Max Image Contrast" {
            UserDefaults.standard.maxFaceImageContrast = self.maxImageContrasts[index]
        } else {
            UserDefaults.standard.registrationFaceCount = self.registrationFaceCounts[index]
        }
        self.loadFromDefaults()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SecuritySettingsViewController {
            destination.delegate = self
        } else if let destination = segue.destination as? FaceDetectionSettingsViewController {
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
            } else if segue.identifier == "maxImageContrast" {
                destination.values = self.maxImageContrasts.map { String(format: "%.0f", $0) }
                destination.title = "Max Image Contrast"
                if let index = self.maxImageContrasts.firstIndex(of: UserDefaults.standard.maxFaceImageContrast) {
                    destination.selectedIndex = index
                } else {
                    destination.selectedIndex = 5
                }
            }
        } else if let destination = segue.destination as? IntroViewController {
            destination.showRegisterButton = false            
        }
    }

}
