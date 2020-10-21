//
//  GenerateUsersProgressViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 19/10/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit

class GenerateUsersProgressViewController: UIViewController {
    
    @IBOutlet var progressBar: UIProgressView?
    @IBOutlet var label: UILabel?
    
    var progress = 0
    var total = 0
    var delegate: GenerateUsersProgressViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setProgress(self.progress, of: self.total)
    }
    
    func setProgress(_ progress: Int, of total: Int) {
        self.progress = progress
        self.total = total
        if progress > 0 && total > 0 {
            let fraction = Float(progress) / Float(total)
            self.progressBar?.setProgress(fraction, animated: false)
            self.label?.text = "Generated user \(progress) of \(total)"
        }
    }
    
    @IBAction func cancel() {
        self.delegate?.didRequestCancellationFromViewController(self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol GenerateUsersProgressViewControllerDelegate: class {
    func didRequestCancellationFromViewController(_ viewController: GenerateUsersProgressViewController)
}
