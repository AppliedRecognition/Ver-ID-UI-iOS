![Cocoapods](https://img.shields.io/cocoapods/v/Ver-ID-UI.svg)

# Ver-ID UI for iOS

## Usage

1. Before running a Ver-ID UI session you will need to import the `VerIDCore` framework and create an instance of `VerID`.
1. Have your class implement the `VerIDFactoryDelegate` protocol. You will receive a callback when the `VerID` instance is created or when the creation fails.
1. In the class that runs the Ver-ID UI session import `VerIDUI`.
1. Pass the `VerID` instance to the `Session` constructor along with the session settings.

### Example

~~~swift
import UIKit
import VerIDCore
import VerIDUI

class MyViewController: UIViewController, VerIDFactoryDelegate, SessionDelegate {
    
    func runLivenessDetection() {
        // You may want to display an activity indicator as the instance creation may take up to a few seconds
        let factory = VerIDFactory()
        // Set your class as the factory's delegate
        // The delegate methods will be called when the session is created or if the creation fails
        factory.delegate = self
        // Create an instance of Ver-ID
        factory.createVerID()
    }
    
    // MARK: - Ver-ID factory delegate
    
    func veridFactory(_ factory: VerIDFactory, didCreateVerID instance: VerID) {
        // Ver-ID instance was created
        // Create liveness detection settings
        let settings = LivenessDetectionSessionSettings()
        // Show the result of the session to the user
        settings.showResult = true
        // Create a Ver-ID UI session
        let session = Session(environment: instance, settings: settings)
        // Set your class as a delegate of the session to receive the session outcome
        session.delegate = self
        // Start the session
        session.start()
    }
    
    func veridFactory(_ factory: VerIDFactory, didFailWithError error: Error) {
        NSLog("Failed to create Ver-ID instance: %@", error.localizedDescription)
    }
    
    // MARK: - Session delegate
    
    func sessionWasCanceled(_ session: Session) {
        // Session was canceled
    }
    
    func session(_ session: Session, didFinishWithResult result: SessionResult) {
        // Session finished successfully
    }
    
    func session(_ session: Session, didFailWithError error: Error) {
        // Session failed
    }
}
~~~

## API Reference Documentation
- [Ver-ID Core](https://appliedrecognition.github.io/Ver-ID-Core-Apple)
- [Ver-ID UI](https://appliedrecognition.github.io/Ver-ID-UI-iOS)
