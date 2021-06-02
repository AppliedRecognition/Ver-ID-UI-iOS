//
//  VerIDSessionDelegate.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 09/03/2021.
//  Copyright © 2021 Applied Recognition Inc. All rights reserved.
//

import Foundation
import AVFoundation
import VerIDCore

/// Session delegate protocol
@objc public protocol VerIDSessionDelegate: class {
    /// Called when the session successfully finishes
    ///
    /// - Parameters:
    ///   - session: Session that finished
    ///   - result: Session result
    @objc func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult)
    /// Called when the session was canceled
    ///
    /// - Parameter session: Session that was canceled
    @objc optional func didCancelSession(_ session: VerIDSession)
    
    @objc optional func shouldDisplayResult(_ result: VerIDSessionResult, ofSession session: VerIDSession) -> Bool
    
    @objc optional func shouldSpeakPromptsInSession(_ session: VerIDSession) -> Bool
    
    @objc optional func shouldRecordVideoOfSession(_ session: VerIDSession) -> Bool
    
    @objc optional func cameraPositionForSession(_ session: VerIDSession) -> AVCaptureDevice.Position
    
    @objc optional func shouldRetrySession(_ session: VerIDSession, afterFailure error: Error) -> Bool
}
