//
//  SecuritySettingsViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit

class SecuritySettingsViewController: UITableViewController, ValueSelectionDelegate {
    
    let poseCounts: [String] = ["1 pose (easy)","2 poses","3 poses (difficult)"]
    let yawThresholds: [Float] = [12.0,15.0,18.0,21.0,24.0]
    let pitchThresholds: [Float] = [10.0,12.0,15.0,18.0,21.0]
    let authThresholds: [Float] = [3.0,3.5,4.0,4.5,5.0]
    
    weak var delegate: SecuritySettingsDelegate?
    
    @IBOutlet var presetControl: UISegmentedControl!
    @IBOutlet var poseCountCell: UITableViewCell!
    @IBOutlet var yawThresholdCell: UITableViewCell!
    @IBOutlet var pitchThresholdCell: UITableViewCell!
    @IBOutlet var authThresholdCell: UITableViewCell!

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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return section == 0 ? 3 : 1
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
        UserDefaults.standard.authenticationThreshold = preset.authThreshold
        self.updateFromUserDefaults()
    }
    
    private func updateFromUserDefaults() {
        let poseCount: Int = UserDefaults.standard.poseCount
        let yawThreshold: Float = UserDefaults.standard.yawThreshold
        let pitchThreshold: Float = UserDefaults.standard.pitchThreshold
        let authThreshold: Float = UserDefaults.standard.authenticationThreshold
        self.poseCountCell.detailTextLabel?.text = String(format: "%d", poseCount)
        self.yawThresholdCell.detailTextLabel?.text = String(format: "%.01f", yawThreshold)
        self.pitchThresholdCell.detailTextLabel?.text = String(format: "%.01f", pitchThreshold)
        self.authThresholdCell.detailTextLabel?.text = String(format: "%.01f", authThreshold)
        let preset = SecuritySettingsPreset(poseCount: poseCount, yawThreshold: yawThreshold, pitchThreshold: pitchThreshold, authThreshold: authThreshold)
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

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
                destination.title = "Authentication Threshold"
                let authThreshold = UserDefaults.standard.authenticationThreshold
                destination.selectedIndex = self.authThresholds.firstIndex(of: authThreshold)
                destination.values = self.authThresholds.map{ String(format: "%.01f", $0) }
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
        } else if valueSelectionViewController.title == "Authentication Threshold" {
            UserDefaults.standard.authenticationThreshold = self.authThresholds[index]
        }
        self.updateFromUserDefaults()
    }

}

protocol SecuritySettingsDelegate: AnyObject {
    func securitySettingsViewController(_ securitySettingsViewController: SecuritySettingsViewController, didSetProfile profile: String)
}
