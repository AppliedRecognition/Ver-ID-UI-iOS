Pod::Spec.new do |s|
    s.name = "Ver-ID"
    s.module_name = "VerIDUI"
    s.version = "2.0.1"
    s.summary = "Face detection and recognition"
    s.homepage = "https://github.com/AppliedRecognition"
    s.license = { :type => "COMMERCIAL", :file => "LICENCE.txt" }
    s.author = "Jakub Dolejs"
    s.platform = :ios, "10.3"
    s.swift_version = "5"
    s.documentation_url = "https://appliedrecognition.github.io/Ver-ID-Core-Apple"
    s.source = { :git => "https://github.com/AppliedRecognition/Ver-ID-UI-iOS.git", :tag => "v#{s.version}" }
    s.default_subspecs = 'Core', 'UI'
    s.static_framework = true
    s.subspec 'UI' do |ss|
        ss.source_files = "VerIDUI/*.swift"
        ss.resource_bundles = { "VerIDUIResources" => ["VerIDUI/Resources/Video/*.mp4", "VerIDUI/Resources/Localization/*.xml", "VerIDUI/Resources/*.xcassets", "VerIDUI/Resources/**.{storyboard,xib}"] }
        ss.dependency "Ver-ID/Core"
        ss.dependency 'RxSwift', '~> 5'
        ss.dependency 'RxCocoa', '~> 5'
        ss.pod_target_xcconfig = {
            "ENABLE_BITCODE" => "YES"
        }
    end
    s.subspec 'Core' do |ss|
        ss.dependency "OpenCV2", "~> 4.1"
        ss.dependency "DeviceKit", "~> 4.1"
        ss.dependency "ZIPFoundation", "~> 0.9"
        ss.dependency "Ver-ID-SDK-Identity", "~> 3.0"
        ss.dependency 'RxSwift', '~> 5'
        ss.dependency 'RxCocoa', '~> 5'
        ss.vendored_framework = "Frameworks/bitcode/VerIDCore.xcframework"
    end
    s.subspec 'UI-no-bitcode' do |ss|
        ss.source_files = "VerIDUI/*.swift"
        ss.resource_bundles = { "VerIDUIResources" => ["VerIDUI/Resources/Video/*.mp4", "VerIDUI/Resources/Localization/*.xml", "VerIDUI/Resources/*.xcassets", "VerIDUI/Resources/**.{storyboard,xib}"] }
        ss.dependency "Ver-ID/Core-no-bitcode"
        ss.dependency 'RxSwift', '~> 5'
        ss.dependency 'RxCocoa', '~> 5'
        ss.pod_target_xcconfig = {
            "ENABLE_BITCODE" => "NO"
        }
    end
    s.subspec 'Core-no-bitcode' do |ss|
        ss.dependency "OpenCV2", "~> 4.1"
        ss.dependency "DeviceKit", "~> 4.1"
        ss.dependency "ZIPFoundation", "~> 0.9"
        ss.dependency "Ver-ID-SDK-Identity", "~> 3.0"
        ss.dependency 'RxSwift', '~> 5'
        ss.dependency 'RxCocoa', '~> 5'
        ss.vendored_framework = "Frameworks/no-bitcode/VerIDCore.xcframework"
    end
end
