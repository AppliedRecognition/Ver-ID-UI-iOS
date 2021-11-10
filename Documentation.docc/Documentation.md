 [![Tests](https://github.com/AppliedRecognition/Ver-ID-UI-iOS/actions/workflows/main.yml/badge.svg)](https://github.com/AppliedRecognition/Ver-ID-UI-iOS/actions/workflows/main.yml) ![Cocoapods](https://img.shields.io/cocoapods/v/Ver-ID)

# Ver-ID SDK for iOS

## Prerequisites
Minimum iOS version is 11.

To build this project and to run the sample app you will need a Apple Mac computer with these applications:

- [Xcode](https://itunes.apple.com/us/app/xcode/id497799835)
- [Git](https://git-scm.com)
- [Git LFS](https://git-lfs.github.com)
- [CocoaPods](https://cocoapods.org)

## Installation

1. Open **Terminal** and enter the following commands:

```shell
git clone https://github.com/AppliedRecognition/Ver-ID-UI-iOS.git
cd Ver-ID-UI-iOS
pod install
git lfs install
git lfs pull
open VerIDUI.xcworkspace
```

1. The **VerIDUI.xcworkspace** should now be open in **Xcode**.
1. Change the **Team** setting in the **Signing & Capabilities** tab for all the targets.
1. You can now build and run the **Ver-ID Sample** target on your iOS device.

## Adding Ver-ID to your own project

1. [Register your app](https://dev.ver-id.com/licensing/). You will need your app's bundle identifier.
2. Registering your app will generate an evaluation licence for your app. The licence is valid for 30 days. If you need a production licence please [contact Applied Recognition](mailto:sales@appliedrec.com).
2. When you finish the registration you'll receive a file called **Ver-ID identity.p12** and a password. Copy the password to a secure location and add the **Ver-ID identity.p12** file in your app:    
- Open your project in Xcode.
- From the top menu select **File/Add files to “[your project name]”...** or press **⌥⌘A** and browse to select the downloaded **Ver-ID identity.p12** file.
- Reveal the options by clicking the **Options** button on the bottom left of the dialog.
- Tick **Copy items if needed** under **Destination**.
- Under **Added to targets** select your app target.
8. Ver-ID will need the password you received at registration to construct an instance of `VerIDSDKIdentity`.    
- You can either add the password in your app's **Info.plist**:

```xml
<key>com.appliedrec.verid.password</key>
<string>your password goes here</string>
```
- Or you can specify the password when you create an instance of `VerIDFactory`:

```swift
let identity = try VerIDIdentity(password: "your password goes here")
```
and pass the instance of ``VerIDIdentity`` to the ``VerIDFactory`` constructor:

```swift
let veridFactory = VerIDFactory(identity: identity)
```

1. If your project is using [CocoaPods](https://cocoapods.org) for dependency management, open the project's **Podfile**. Otherwise make sure CocoaPods is installed and in your project's folder create a file named **Podfile** (without an extension).
1. Let's assume your project is called **MyProject** and it has an app target called **MyApp**. Open the **Podfile** in a text editor and enter the following:

```ruby
project 'MyProject.xcodeproj'
workspace 'MyProject.xcworkspace'
platform :ios, '11'
target 'MyApp' do
    use_frameworks!
    pod 'Ver-ID'

    # The following script sets the BUILD_LIBRARY_FOR_DISTRIBUTION build setting
    # to YES and removes the setting from the pod dependencies. Without it the
    # project will compile but it will fail to run. 
    post_install do |installer|
        installer.pods_project.build_configurations.each do |config|
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        end
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings.delete 'BUILD_LIBRARY_FOR_DISTRIBUTION'
            end
        end
    end
end
```

#### Please ensure that you include the `post_install` script. Your app will crash without it.
1. Save the Podfile. Open **Terminal** and navigate to your project's folder. Then enter:

```shell
pod install
```
1. You can now open **MyProject.xcworkspace** in **Xcode** and Ver-ID will be available to use in your app **MyApp**.
1. Before starting Ver-ID sessions ensure that your app has camera permission declared in its Info.plist file:

```xml
<key>NSCameraUsageDescription</key>
<string>Your reason for requesting camera permission</string>
```

## Library initialization
### Using a callback (new in 2.0.0)
This is the simplest way to obtain an instance of `VerID`

```swift
VerIDFactory().createVerID { result in
    switch result {
    case .success(let verID):
        // VerID created
    case .failure(let error):
        // VerID creation failed
    }
}
```
### Using a delegate
This method has been part of the Ver-ID SDK since version 1.

```swift
class MyClass: NSObject, VerIDFactoryDelegate {

func loadVerID() {
    let veridFactory = VerIDFactory()
    veridFactory.delegate = self
    veridFactory.createVerID()
}

// MARK: - Ver-ID factory delegate methods

func veridFactory(_ factory: VerIDFactory, didCreateVerID verID: VerID) {
    // VerID created
}

func veridFactory(_ factory: VerIDFactory, didFailWithError error: Error) {
    // VerID creation failed
}
}
```
### Synchronous
If your application is doing other work on a background queue you may wish to load the library synchronously.

**Caution:** Never call this method on the main queue. Calling it on the main queue will leave your application unresponsive until the method returns.

```swift
DispatchQueue.global().async {
    do {
        let verID = try VerIDFactory().createVerIDSync()
        // VerID created
    } catch {
        // VerID creation failed
    }
}
```
## Running Ver-ID sessions
1. Before running a Ver-ID UI session you will need to import the `VerIDCore` framework and create an instance of `VerID`.
1. Have your class implement the `VerIDFactoryDelegate` protocol. You will receive a callback when the `VerID` instance is created or when the creation fails.
1. In the class that runs the Ver-ID session import `VerIDUI`.
1. Pass the `VerID` instance to the `VerIDSession` constructor along with the session settings.

### Example

```swift
import UIKit
import VerIDCore
import VerIDUI

class MyViewController: UIViewController, VerIDSessionDelegate {

    func runLivenessDetection() {
        // You may want to display an activity indicator as the instance creation may take up to a few seconds
        // Create an instance of Ver-ID
        VerIDFactory().createVerID { result in
            switch result {
            case .success(let verID):
                // Ver-ID instance was created
                // Create liveness detection settings
                let settings = LivenessDetectionSessionSettings()
                // Create a Ver-ID UI session
                let session = VerIDSession(environment: verID, settings: settings)
                // Set your class as a delegate of the session to receive the session outcome
                session.delegate = self
                // Start the session
                session.start()
            case .failure(let error):
                NSLog("Failed to create Ver-ID instance: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Session delegate

    func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        // Session finished successfully
    }

    // MARK: Optional session delegate methods

    func didCancelSession(_ session: VerIDSession) {
        // Session was canceled
    }

    func shouldDisplayResult(_ result: VerIDSessionResult, ofSession session: VerIDSession) -> Bool {
        // Return `true` to display the result of the session
        return true
    }

    func shouldSpeakPromptsInSession(_ session: VerIDSession) -> Bool {
        // Return `true` to speak prompts in the session
        return true
    }

    func shouldRecordVideoOfSession(_ session: VerIDSession) -> Bool {
        // Return `true` to record a video of the session
        return true
    }

    func cameraPositionForSession(_ session: VerIDSession) -> AVCaptureDevice.Position {
        // Return `AVCaptureDevice.Position.back` to use the back camera instead of the front (selfie) camera
        return .back
    }

    var runCount = 0

    func shouldRetrySession(_ session: VerIDSession, afterFailure error: Error) -> Bool {
        // Return `true` to allow the user to retry the session on failure
        // For example, you can keep track of how many times the user tried and fail the session on Xth attempt
        runCount += 1
        return runCount < 3
    }
}
```

## API Reference Documentation
- [Ver-ID Core](https://appliedrecognition.github.io/Ver-ID-Apple)
- [Ver-ID UI](https://appliedrecognition.github.io/Ver-ID-UI-iOS)
