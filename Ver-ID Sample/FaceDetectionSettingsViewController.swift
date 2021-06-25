//
//  FaceDetectionSettingsViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit

class FaceDetectionSettingsViewController: UITableViewController, ValueSelectionDelegate {
    
    @IBOutlet var presetControl: UISegmentedControl!
    @IBOutlet var templateExtractionThresholdCell: UITableViewCell!
    @IBOutlet var confidenceThresholdCell: UITableViewCell!
    
    let confidenceThresholds: [Float] = [-0.5,0.0]
    let templateExtractionThresholds: [Float] = [5.0,6.0,7.0,8.0,9.0]
    
    weak var delegate: FaceDetectionSettingsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadFromDefaults()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func loadFromDefaults() {
        let templateExtractionThreshold = UserDefaults.standard.faceTemplateExtractionThreshold
        let confidenceThreshold = UserDefaults.standard.confidenceThreshold
        self.templateExtractionThresholdCell.detailTextLabel?.text = String(format: "%.01f", templateExtractionThreshold)
        self.confidenceThresholdCell.detailTextLabel?.text = String(format: "%.01f", confidenceThreshold)
        let preset = FaceDetectionSettingsPreset(confidenceThreshold: confidenceThreshold, templateExtractionThreshold: templateExtractionThreshold)
        let profile: String
        switch preset {
        case .permissive:
            self.presetControl.selectedSegmentIndex = 0
            profile = "Permissive"
        case .normal:
            self.presetControl.selectedSegmentIndex = 1
            profile = "Normal"
        case .restrictive:
            self.presetControl.selectedSegmentIndex = 2
            profile = "Restrictive"
        default:
            self.presetControl.selectedSegmentIndex = 3
            profile = "Custom"
        }
        self.delegate?.faceDetectionSettingsViewController(self, didSetProfile: profile)
    }
    
    @IBAction func didChangePreset(_ control: UISegmentedControl) {
        let preset: FaceDetectionSettingsPreset
        switch control.selectedSegmentIndex {
        case 0:
            preset = .permissive
        case 1:
            preset = .normal
        case 2:
            preset = .restrictive
        default:
            return
        }
        UserDefaults.standard.confidenceThreshold = preset.confidenceThreshold
        UserDefaults.standard.faceTemplateExtractionThreshold = preset.templateExtractionThreshold
        self.loadFromDefaults()
    }
    
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValue value: String, atIndex index: Int) {
        self.navigationController?.popViewController(animated: true)
        if valueSelectionViewController.title == "Confidence Threshold" {
            UserDefaults.standard.confidenceThreshold = self.confidenceThresholds[index]
        } else {
            UserDefaults.standard.faceTemplateExtractionThreshold = self.templateExtractionThresholds[index]
        }
        self.loadFromDefaults()
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
            case "confidenceThreshold":
                destination.values = self.confidenceThresholds.map { String(format: "%.01f", $0) }
                destination.selectedIndex = self.confidenceThresholds.firstIndex(of: UserDefaults.standard.confidenceThreshold)
                destination.title = "Confidence Threshold"
            case "templateExtractionThreshold":
                destination.values = self.templateExtractionThresholds.map { String(format: "%.01f", $0) }
                destination.selectedIndex = self.templateExtractionThresholds.firstIndex(of: UserDefaults.standard.faceTemplateExtractionThreshold)
                destination.title = "Face Template Extraction Threshold"
            default:
                return
            }
            destination.delegate = self
        }
    }

}


protocol FaceDetectionSettingsDelegate: AnyObject {
    func faceDetectionSettingsViewController(_ faceDetectionSettingsViewController: FaceDetectionSettingsViewController, didSetProfile profile: String)
}
