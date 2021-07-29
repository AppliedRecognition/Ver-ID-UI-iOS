//
//  IDCardFaceDetectionViewController.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 28/07/2021.
//  Copyright © 2021 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDCore
import MobileCoreServices

class IDCardFaceDetectionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func selectImage(_ button: UIBarButtonItem) {
        var sourceTypes: [UIImagePickerController.SourceType] = []
        if UIImagePickerController.isSourceTypeAvailable(.camera), let cameraMediaTypes = UIImagePickerController.availableMediaTypes(for: .camera), cameraMediaTypes.contains(kUTTypeImage as String) {
            sourceTypes.append(.camera)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary), let libraryMediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary), libraryMediaTypes.contains(kUTTypeImage as String) {
            sourceTypes.append(.photoLibrary)
        }
        if sourceTypes.count > 1 {
            let alert = UIAlertController(title: "ID card image", message: nil, preferredStyle: .actionSheet)
            alert.popoverPresentationController?.barButtonItem = button
            alert.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { _ in
                self.takePicture()
            }))
            alert.addAction(UIAlertAction(title: "Select from photos", style: .default, handler: { _ in
                self.selectImageFromLibrary(button)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        } else if sourceTypes.contains(.camera) {
            self.takePicture()
        } else if sourceTypes.contains(.photoLibrary) {
            self.selectImageFromLibrary(button)
        }
    }
    
    func takePicture() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.mediaTypes = [kUTTypeImage as String]
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    func selectImageFromLibrary(_ barButtonItem: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.detectIDCardInImage(image)
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.detectIDCardInImage(image)
        }
        picker.dismiss(animated: true)
    }
    
    func detectIDCardInImage(_ image: UIImage) {
        do {
            guard let faceDetection = Globals.verid?.faceDetection as? VerIDFaceDetection else {
                preconditionFailure()
            }
            guard let verIDImage = VerIDImage(uiImage: image) else {
                preconditionFailure()
            }
            guard let face = try faceDetection.detectFacesInImage(verIDImage, limit: 1, options: 0).first else {
                preconditionFailure()
            }
            let authScore = try faceDetection.extractAttributeFromFace(face, image: verIDImage, using: "license01").floatValue
            self.performSegue(withIdentifier: "result", sender: (image, face, authScore))
        } catch {
            
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "result", let (image, face, score) = sender as? (UIImage, Face, Float), let dest = segue.destination as? IDCardViewController {
            dest.face = face
            dest.idCardImage = image
            dest.authenticityScore = score
        }
    }

}
