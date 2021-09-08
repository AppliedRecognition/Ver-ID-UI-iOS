//
//  VerIDUISessionError.swift
//  VerIDUI
//
//  Created by Jakub Dolejs on 27/08/2021.
//  Copyright © 2021 Applied Recognition Inc. All rights reserved.
//

import Foundation

public enum VerIDUISessionError: Error {
    case captureSessionRuntimeError
    case cameraNotAvailableInBackground
    case cameraInUseByAnotherClient
    case cameraNotAvailableWithMultipleForegroundApps
    case cameraNotAvailableDueToSystemPressure
    case captureSessionInterrupted
}
