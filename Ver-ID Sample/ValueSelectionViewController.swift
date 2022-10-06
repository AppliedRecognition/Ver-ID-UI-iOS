//
//  ValueSelectionViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 04/05/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit

class ValueSelectionViewController: UITableViewController {
    
    var values: [String] = []
    var selectedIndex: Int?
    var selectedIndices: Set<Int> = []
    var allowsMultipleSelection: Bool = false
    weak var delegate: ValueSelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.allowsMultipleSelection {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.onDone))
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.values.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.allowsMultipleSelection {
            if self.selectedIndices.contains(indexPath.row) {
                self.selectedIndices.remove(indexPath.row)
            } else {
                self.selectedIndices.insert(indexPath.row)
            }
            self.tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            self.delegate?.valueSelectionViewController(self, didSelectValue: self.values[indexPath.row], atIndex: indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "valueCell", for: indexPath)
        cell.textLabel?.text = self.values[indexPath.row]
        if let selected = self.selectedIndex, selected == indexPath.row {
            cell.accessoryType = .checkmark
        } else if self.selectedIndices.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    // MARK: -
    
    @objc private func onDone() {
        var values: [String] = []
        for i in 0..<self.values.count {
            if self.selectedIndices.contains(i) {
                values.append(self.values[i])
            }
        }
        self.delegate?.valueSelectionViewController(self, didSelectValues: values, atIndices: Array(self.selectedIndices))
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol ValueSelectionDelegate: AnyObject {
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValue value: String, atIndex index: Int)
    func valueSelectionViewController(_ valueSelectionViewController: ValueSelectionViewController, didSelectValues values: [String], atIndices: [Int])
}
