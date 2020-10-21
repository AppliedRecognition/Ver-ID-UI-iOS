//
//  UsersTableViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 19/10/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore

class UsersTableViewController: UITableViewController, GenerateUsersProgressViewControllerDelegate {
    
    var users: [String] = []
    var createdUsers: [String] = []
    var isCreationCancelled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !(Globals.verid?.faceRecognition is VerIDFaceRecognition) {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.loadUsers()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @IBAction func addUsers(_ button: UIBarButtonItem) {
        let iterations = 1000
        let alert = UIAlertController(title: "Generate users", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = button
        alert.addAction(UIAlertAction(title: "Generate \(iterations) users", style: .default, handler: { _ in
            guard let userManagement = Globals.verid?.userManagement else {
                return
            }
            guard let progressViewController = self.storyboard?.instantiateViewController(withIdentifier: "generateUserProgress") as? GenerateUsersProgressViewController else {
                return
            }
            progressViewController.delegate = self
            self.present(progressViewController, animated: true) {
                self.isCreationCancelled = false
                DispatchQueue.global().async {
                    self.createdUsers.removeAll()
                    for i in 0..<iterations {
                        do {
                            guard let template = try (Globals.verid?.faceRecognition as? VerIDFaceRecognition)?.generateRandomFaceTemplate() else {
                                continue
                            }
                            let user = UUID().uuidString
                            var breakLoop = false
                            DispatchQueue.main.sync {
                                breakLoop = self.isCreationCancelled
                            }
                            if breakLoop {
                                break
                            }
                            let semaphore = DispatchSemaphore(value: 0)
                            userManagement.assignFaces([template], toUser: user) { error in
                                if error == nil {
                                    self.createdUsers.append(user)
                                }
                                semaphore.signal()
                            }
                            guard semaphore.wait(timeout: .now()+2) == .success else {
                                break
                            }
                            DispatchQueue.main.async {
                                progressViewController.setProgress(i, of: iterations)
                            }
                        } catch {
                        
                        }
                    }
                    DispatchQueue.main.async {
                        progressViewController.dismiss(animated: true) {
                            self.loadUsers()
                        }
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func deleteUsers(_ button: UIBarButtonItem) {
        Globals.verid?.userManagement.deleteUsers(self.users.filter({ $0 != VerIDUser.defaultUserId })) { error in
            self.loadUsers()
        }
    }
    
    // MARK: - Generate Users View Controller Delegate
    
    func didRequestCancellationFromViewController(_ viewController: GenerateUsersProgressViewController) {
        self.isCreationCancelled = true
        viewController.dismiss(animated: true) {
            if !self.createdUsers.isEmpty, let userManagement = Globals.verid?.userManagement {
                userManagement.deleteUsers(self.createdUsers) { error in
                    self.loadUsers()
                }
            }
        }
    }
    
    // MARK: -
    
    func loadUsers() {
        DispatchQueue.global().async {
            do {
                guard let userManagement = Globals.verid?.userManagement else {
                    return
                }
                self.users = try userManagement.users().sorted(by: {
                    if $0 == VerIDUser.defaultUserId {
                        return true
                    }
                    if $1 == VerIDUser.defaultUserId {
                        return false
                    }
                    return $0 < $1
                })
            } catch {
            }
            DispatchQueue.main.async {
                self.title = String(format: "%d Users", self.users.count)
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)

        cell.textLabel?.text = self.users[indexPath.row]

        return cell
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
