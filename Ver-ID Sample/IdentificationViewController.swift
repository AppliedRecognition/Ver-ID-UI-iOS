//
//  IdentificationViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 23/10/2020.
//  Copyright © 2020 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDUI
import VerIDCore

class IdentificationViewController: UIViewController, VerIDSessionDelegate {
    
    @IBOutlet var facesTextField: UITextField!
    @IBOutlet var textView: UITextView!
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var label: UILabel!
    
    private var faces: [Recognizable] = []
    private var registredUserFaces: [Recognizable] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.facesTextField.canBecomeFirstResponder {
            self.facesTextField.becomeFirstResponder()
        }
    }
    
    private func startSession() {
        self.label.text = "Faces to generate"
        self.facesTextField.isHidden = false
        guard let verid = Globals.verid else {
            return
        }
        let settings = LivenessDetectionSessionSettings()
        settings.bearings = [.straight]
        settings.faceCaptureCount = 1
        let session = VerIDSession(environment: verid, settings: settings)
        session.delegate = self
        session.start()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(self.start))
    }
    
    @IBAction func start() {
        if self.facesTextField.canResignFirstResponder {
            self.facesTextField.resignFirstResponder()
        }
        guard let facesToGenerateText = self.facesTextField.text, let facesToGenerate = Int(facesToGenerateText) else {
            return
        }
        let maxFaces = 1000000
        guard facesToGenerate > 0 && facesToGenerate <= maxFaces else {
            let alert = UIAlertController(title: "Please enter a number between 1 and \(maxFaces)", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
                if self.facesTextField.canBecomeFirstResponder {
                    self.facesTextField.becomeFirstResponder()
                }
            })
            self.present(alert, animated: true)
            return
        }
        guard let verid = Globals.verid else {
            return
        }
        guard let faceRec = verid.faceRecognition as? VerIDFaceRecognition else {
            return
        }
        var labelText = "Generating \(facesToGenerate) face"
        if facesToGenerate > 1 {
            labelText += "s"
        }
        self.label.text = labelText
        self.facesTextField.isHidden = true
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        DispatchQueue.global().async {
            do {
                let userFaces = try verid.userManagement.facesOfUser(VerIDUser.defaultUserId)
                guard let faceTemplateVersion = Array(Set(userFaces.map { $0.faceTemplateVersion })).sorted().last else {
                    throw VerIDError.userMissingRequiredFaceTemplates
                }
                let generatedFaces = try faceRec.generate(NSNumber(value: facesToGenerate), templatesWithVersion: faceTemplateVersion)
                self.faces = generatedFaces + userFaces.filter({ $0.faceTemplateVersion == faceTemplateVersion })
                DispatchQueue.main.async {
                    self.progressBar.isHidden = true
                    self.registredUserFaces = userFaces
                    self.startSession()
                }
            } catch {
                DispatchQueue.main.async {
                    self.progressBar.isHidden = true
                    self.label.text = "Faces to generate"
                    self.facesTextField.isHidden = false
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(self.start))
                    let alert = UIAlertController(title: nil, message: "Failed to generate faces for testing", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        guard let faceCapture = result.faceCaptures.first(where: { $0.bearing == .straight }) else {
            return
        }
        let faceTemplateVersion = self.faces.first!.faceTemplateVersion
        do {
            let face: Recognizable
            if let f = faceCapture.faces.first(where: { $0.faceTemplateVersion == faceTemplateVersion }) {
                face = f
            } else {
                face = try (session.environment.faceRecognition as! VerIDFaceRecognition).createRecognizableFacesFromFaces([faceCapture.face], inImage: faceCapture.verIDImage, faceTemplateVersion: faceTemplateVersion) as! any Recognizable
            }
            self.label.text = "Identifying"
            self.facesTextField.isHidden = true
            let identification = UserIdentification(verid: session.environment)
            let progress = Progress()
            var progressObservation: NSKeyValueObservation? = progress.observe(\.fractionCompleted) { (progressInstance, completed) in
                self.label.text = "Looking at face \(progressInstance.completedUnitCount) of \(progressInstance.totalUnitCount)"
            }
            self.progressBar.observedProgress = progress
            self.progressBar.isHidden = false
            identification.findFacesSimilarTo(face, in: self.faces, threshold: nil, progress: progress) { result in
                progressObservation = nil
                self.progressBar.isHidden = true
                self.progressBar.observedProgress = nil
                let message: String
                let succeeded: Bool
                if case Result.success(let identifiedFaces) = result, let bestFace = identifiedFaces.first?.face {
                    if self.registredUserFaces.contains(where: { $0.recognitionData == bestFace.recognitionData }) {
                        message = "You've been identified among \(self.faces.count) faces"
                        succeeded = true
                    } else {
                        message = "You have been misidentified"
                        succeeded = false
                    }
                } else {
                    message = "We were unable to identify you"
                    succeeded = false
                }
                self.label.text = "Faces to generate"
                self.facesTextField.isHidden = false
                if succeeded {
                    guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "identificationSuccess") as? IdentificationResultViewController else {
                        return
                    }
                    viewController.message = message
                    if let url = Globals.profilePictureURL, let image = UIImage(contentsOfFile: url.path) {
                        viewController.image = image
                    }
                    self.present(viewController, animated: true)
                } else {
                    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        } catch {
            let alert = UIAlertController(title: nil, message: "Failed to extract \(faceTemplateVersion.stringValue()) face from capture.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
        self.label.text = "Identifying"
        self.facesTextField.isHidden = true
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
