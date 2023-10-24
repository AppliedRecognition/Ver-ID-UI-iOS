//
//  SessionDiagnosticUpload.swift
//  Ver-ID Sample
//
//  Created by Jakub Dolejs on 23/10/2023.
//  Copyright © 2023 Applied Recognition Inc. All rights reserved.
//

import UIKit
import VerIDUI
import VerIDCore

@available(iOS 13, *)
class SessionDiagnosticUpload {
    
    let sessionDiagnosticCollectionURL = URL(string: "https://session-upload.ver-id.com")!
    
    var hasUserConsent: Bool {
        UserDefaults.standard.sessionDiagnosticUploadPermission == .allow
    }
    
    func uploadPackage(_ package: SessionResultPackage) {
        guard self.hasUserConsent else {
            return
        }
        _Concurrency.Task {
            do {
                var request = URLRequest(url: self.sessionDiagnosticCollectionURL, cachePolicy: .reloadIgnoringCacheData)
                request.httpMethod = "POST"
                request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
                let zipFileURL = try package.createArchive()
                defer {
                    try? FileManager.default.removeItem(at: zipFileURL)
                }
                let (_, response) = try await URLSession.shared.upload(for: request, fromFile: zipFileURL)
                if (response as? HTTPURLResponse)?.statusCode != 200 {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    throw NSError(domain: kVerIDErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Returned status code \(status)"])
                }
                NSLog("Session diagnostics uploaded to %@", self.sessionDiagnosticCollectionURL.absoluteString)
            } catch {
                NSLog("Failed to upload session diagnostics to %@:", self.sessionDiagnosticCollectionURL.absoluteString)
            }
        }
    }
    
    func askForUserConsent(in viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.sessionDiagnosticUploadPermission != .ask {
            completion(UserDefaults.standard.sessionDiagnosticUploadPermission == .allow)
            return
        }
        guard let dialog = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "diagnosticUploadPermission") as? DiagnosticUploadPermissionDialog else {
            return
        }
        dialog.isModalInPresentation = true
        dialog.onAllow = { always in
            if always {
                UserDefaults.standard.sessionDiagnosticUploadPermission = .allow
            }
            completion(true)
        }
        dialog.onDeny = { always in
            if always {
                UserDefaults.standard.sessionDiagnosticUploadPermission = .deny
            }
            completion(false)
        }
        viewController.present(dialog, animated: true)
    }
}
