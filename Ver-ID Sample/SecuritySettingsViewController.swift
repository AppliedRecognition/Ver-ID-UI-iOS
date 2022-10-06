//
//  SecuritySettingsViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

class SecuritySettingsViewController: UITableViewController, ValueSelectionDelegate {
    
    let poseCounts: [String] = ["1 pose (easy)","2 poses","3 poses (difficult)"]
    let yawThresholds: [Float] = [12.0,15.0,18.0,21.0,24.0]
    let pitchThresholds: [Float] = [10.0,12.0,15.0,18.0,21.0]
    let authThresholds: [Float] = [3.0,3.5,4.0,4.5,5.0]
    let poses: [Bearing] = [.straight, .left, .right, .leftUp, .rightUp]
    
    weak var delegate: SecuritySettingsDelegate?
    
    @IBOutlet var presetControl: UISegmentedControl!
    
    private var sections: [Section] = [Section(id: .livenessDetection, footer: "", cells: []), Section(id: .authentication, footer: "", cells: [])]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateFromUserDefaults()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = self.sectionAtIndex(section) else {
            return 0
        }
        return section.cells.count
    }
    
    // MARK: -
    
    @IBAction func didChangePreset(_ control: UISegmentedControl!) {
        let preset: SecuritySettingsPreset
        switch control.selectedSegmentIndex {
        case 0:
            preset = .low
        case 1:
            preset = .normal
        case 2:
            preset = .high
        default:
            return
        }
        UserDefaults.standard.poseCount = preset.poseCount
        UserDefaults.standard.yawThreshold = preset.yawThreshold
        UserDefaults.standard.pitchThreshold = preset.pitchThreshold
        UserDefaults.standard.poses = preset.poses
        for (version,threshold) in preset.authThresholds {
            (Globals.verid?.faceRecognition as? VerIDFaceRecognition)?.setAuthenticationScoreThreshold(NSNumber(value: threshold), faceTemplateVersion: version)
        }
        if let faceRec = Globals.verid?.faceRecognition as? VerIDFaceRecognition {
            UserDefaults.standard.authenticationThresholds = Dictionary(uniqueKeysWithValues: VerIDFaceTemplateVersion.all.map({ ($0, faceRec.authenticationScoreThreshold(faceTemplateVersion: $0).floatValue) }))
        }
        self.updateFromUserDefaults()
    }
    
    private func updateFromUserDefaults() {
        let poseCount: Int = UserDefaults.standard.poseCount
        let yawThreshold: Float = UserDefaults.standard.yawThreshold
        let pitchThreshold: Float = UserDefaults.standard.pitchThreshold
        let poses: [Bearing] = UserDefaults.standard.poses
        
        self.sections[0] = Section(id: .livenessDetection, footer: "Liveness detection prevents spoofing Ver-ID with a picture", cells: [
            (title: "Pose count", value: String(format: "%d", poseCount)),
            (title: "Yaw threshold", value: String(format: "%.01f", yawThreshold)),
            (title: "Pitch threshold", value: String(format: "%.01f", pitchThreshold)),
            (title: "Poses", value: poses.map({ $0.name }).joined(separator: ", "))
        ])
        
        if let faceRec = Globals.verid?.faceRecognition as? VerIDFaceRecognition {
            let authThresholds: [VerIDFaceTemplateVersion:Float] = Dictionary(uniqueKeysWithValues: VerIDFaceTemplateVersion.all.sorted(by: { $0.rawValue < $1.rawValue }).map({ ($0, faceRec.authenticationScoreThreshold(faceTemplateVersion: $0).floatValue) }))
            
            self.sections[1] = Section(id: .authentication, footer: "Increasing the threshold lowers the chance of false acceptance and increases the chance of false rejection", cells: authThresholds.map({ (title: "Score threshold (\($0.stringValue()))", value: String(format: "%.01f", $1)) }).sorted(by: { $0.title < $1.title }))
            let preset = SecuritySettingsPreset(poseCount: poseCount, yawThreshold: yawThreshold, pitchThreshold: pitchThreshold, authThresholds: authThresholds, poses: poses)
            switch preset {
            case .low:
                self.presetControl.selectedSegmentIndex = 0
                self.delegate?.securitySettingsViewController(self, didSetProfile: "Low")
            case .normal:
                self.presetControl.selectedSegmentIndex = 1
                self.delegate?.securitySettingsViewController(self, didSetProfile: "Normal")
            case .high:
                self.presetControl.selectedSegmentIndex = 2
                self.delegate?.securitySettingsViewController(self, didSetProfile: "High")
            default:
                self.presetControl.selectedSegmentIndex = 3
                self.delegate?.securitySettingsViewController(self, didSetProfile: "Custom")
            }
        }
        self.tableView.reloadData()
    }
    
    private func sectionAtIndex(_ index: Int) -> Section? {
        if index >= 0 && index < self.sections.count {
            return self.sections[index]
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let section = self.sectionAtIndex(indexPath.section) {
            cell.textLabel?.text = section.cells[indexPath.row].title
            cell.detailTextLabel?.text = section.cells[indexPath.row].value
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sec = self.sectionAtIndex(section) else {
            return nil
        }
        return sec.header
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sec = self.sectionAtIndex(section) else {
            return nil
        }
        return sec.footer
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = self.sectionAtIndex(indexPath.section) else {
            return
        }
        let cell = section.cells[indexPath.row]
        switch section.id {
        case .livenessDetection:
            switch cell.title {
            case "Pose count":
                self.performSegue(withIdentifier: "poseCount", sender: nil)
            case "Yaw threshold":
                self.performSegue(withIdentifier: "yawThreshold", sender: nil)
            case "Pitch threshold":
                self.performSegue(withIdentifier: "pitchThreshold", sender: nil)
            case "Poses":
                self.performSegue(withIdentifier: "poses", sender: nil)
            default:
                return
            }
        case .authentication:
            self.performSegue(withIdentifier: "authThreshold", sender: indexPath.row)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ValueSelectionViewController {
            switch segue.identifier {
            case "poseCount":
                destination.title = "Pose Count"
                destination.selectedIndex = UserDefaults.standard.poseCount-1
                destination.values = self.poseCounts
            case "yawThreshold":
                destination.title = "Yaw Threshold"
                let yawThreshold = UserDefaults.standard.yawThreshold
                destination.selectedIndex = self.yawThresholds.firstIndex(of: yawThreshold)
                destination.values = self.yawThresholds.map{ String(format: "%.01f", $0) }
            case "pitchThreshold":
                destination.title = "Pitch Threshold"
                let pitchThreshold = UserDefaults.standard.pitchThreshold
                destination.selectedIndex = self.pitchThresholds.firstIndex(of: pitchThreshold)
                destination.values = self.pitchThresholds.map{ String(format: "%.01f", $0) }
            case "authThreshold":
                guard let index = sender as? Int else {
                    return
                }
                let templateVersion = VerIDFaceTemplateVersion.all.sorted(by: { $0.rawValue < $1.rawValue })[index]
                guard let authThreshold = (Globals.verid?.faceRecognition as? VerIDFaceRecognition)?.authenticationScoreThreshold(faceTemplateVersion: templateVersion).floatValue else {
                    return
                }
                destination.title = self.titleOfThresholdSettingForTemplateVersion(templateVersion)
                destination.selectedIndex = self.authThresholds.firstIndex(of: authThreshold)
                destination.values = self.authThresholds.map{ String(format: "%.01f", $0) }
            case "poses":
                destination.title = "Poses"
                destination.allowsMultipleSelection = true
                for i in 0..<self.poses.count {
                    if UserDefaults.standard.poses.contains(self.poses[i]) {
                        destination.selectedIndices.insert(i)
                    }
                }
                destination.values = self.poses.map({ $0.name })
            default:
                return
            }
            destination.delegate = self
        }
    }
    
    // MARK: -
    
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValue value: String, atIndex index: Int) {
        self.navigationController?.popViewController(animated: true)
        if valueSelectionViewController.title == "Pose Count" {
            UserDefaults.standard.poseCount = index+1
        } else if valueSelectionViewController.title == "Yaw Threshold" {
            UserDefaults.standard.yawThreshold = self.yawThresholds[index]
        } else if valueSelectionViewController.title == "Pitch Threshold" {
            UserDefaults.standard.pitchThreshold = self.pitchThresholds[index]
        } else if valueSelectionViewController.title?.starts(with: "Authentication Threshold") == .some(true) {
            for version in VerIDFaceTemplateVersion.all.sorted(by: { $0.rawValue < $1.rawValue }) {
                if valueSelectionViewController.title == self.titleOfThresholdSettingForTemplateVersion(version) {
                    (Globals.verid?.faceRecognition as? VerIDFaceRecognition)?.setAuthenticationScoreThreshold(NSNumber(value: self.authThresholds[index]), faceTemplateVersion: version)
                }
            }
            if let faceRec = Globals.verid?.faceRecognition as? VerIDFaceRecognition {
                UserDefaults.standard.authenticationThresholds = Dictionary(uniqueKeysWithValues: VerIDFaceTemplateVersion.all.map({ ($0, faceRec.authenticationScoreThreshold(faceTemplateVersion: $0).floatValue) }))
            }
        }
        self.updateFromUserDefaults()
    }
    
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValues values: [String], atIndices: [Int]) {
        self.navigationController?.popViewController(animated: true)
        if valueSelectionViewController.title == "Poses" {
            UserDefaults.standard.poses = values.compactMap({ Bearing(name: $0) })
        }
        self.updateFromUserDefaults()
    }
    
    private func titleOfThresholdSettingForTemplateVersion(_ templateVersion: VerIDFaceTemplateVersion) -> String {
        "Authentication Threshold (\(templateVersion.stringValue()))"
    }

}

protocol SecuritySettingsDelegate: AnyObject {
    func securitySettingsViewController(_ securitySettingsViewController: SecuritySettingsViewController, didSetProfile profile: String)
}

fileprivate enum SectionId: String {
    case livenessDetection = "Liveness Detection"
    case authentication = "Authentication"
}

fileprivate struct Section {
    let id: SectionId
    var header: String {
        self.id.rawValue
    }
    let footer: String
    let cells: [(title: String, value: String)]
}
