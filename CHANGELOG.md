# Change log

### 1.11.1
- Fixed bitcode embedding issues.
- Removed RxVerID dependency for simplicity.

### 1.11.0
- Added a new method to pass Ver-ID SDK identity to *VerIDFactory*.

    The library now depends on [Ver-ID SDK Identity](https://github.com/AppliedRecognition/Ver-ID-SDK-Identity-Apple). You can construct your app's Ver-ID SDK identity in a variety of ways before passing it to *VerIDFactory*. It's more transparent (you can check out the source of the Ver-ID SDK Identity project) and more flexible than entering your credentials directly into the Ver-ID SDK.

### 1.10.4
- SDK client authorization bug fixes

### 1.10.3
- Better SDK client authorization error handling in sessions

### 1.10.2
- Licensing fixes – reject expired certificates at SDK client authorization

### 1.10.1
- Replace private pod dependency with a submodule

### 1.10.0
- Added a new SDK client authentication/authorization for licensing purposes
- New `VerIDFactory` constructor:

    ~~~swift
    @objc public convenience init(veridPassword: String)
    ~~~

### 1.9.6
- Specify schedulers in sample app reactive calls

### 1.9.5
- Bitcode compilation fixes

### 1.9.4
- Build script and pod spec updates

### 1.9.3
- Reorganized core project workspace

### 1.9.2
- Face object JSON serialization update


