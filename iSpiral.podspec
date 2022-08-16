Pod::Spec.new do |s|
    s.name = "iSpiral"
    s.module_name = "iSpiralUI"
    s.version = "1.12.7"
    s.summary = "Face detection and recognition"
    s.homepage = "https://github.com/AppliedRecognition"
    s.license = { :type => "COMMERCIAL", :file => "LICENCE.txt" }
    s.author = "Jakub Dolejs"
    s.platform = :ios, "11.0"
    s.swift_version = "5"
    s.documentation_url = "https://appliedrecognition.github.io/Ver-ID-Core-Apple"
    s.source = { :git => "https://github.com/AppliedRecognition/Ver-ID-UI-iOS.git", :tag => "v#{s.version}" }
    s.default_subspecs = 'Core', 'UI'
    s.static_framework = true
    s.cocoapods_version = ">= 1.10"
    s.script_phase = { :name => "Check Ver-ID fully downloaded", :script => 'filesize=$(wc -c <"${PODS_XCFRAMEWORKS_BUILD_DIR}/iSpiral/VerIDCore.framework/VerIDCore"); if [ $filesize -lt 1000000 ]; then echo "error: iSpiral framework files not fully downloaded. Please install Git LFS, clear the iSpiral pod cache using pod cache clean iSpiral and run pod install."; exit 1; else echo "iSpiral installed successfully"; fi', :execution_position => :before_compile }
    s.subspec 'UI' do |ss|
        ss.source_files = "VerIDUI/*.swift"
        ss.resource_bundles = { "VerIDUIResources" => ["VerIDUI/Resources/Video/*.mp4", "VerIDUI/Resources/Localization/*.xml", "VerIDUI/Resources/*.xcassets", "VerIDUI/Resources/**.{storyboard,xib}"] }
        ss.dependency "iSpiral/Core"
        ss.pod_target_xcconfig = {
            "ENABLE_BITCODE" => "YES"
        }
    end
    s.subspec 'Core' do |ss|
        ss.dependency "OpenCV2", "~> 4.1"
        ss.dependency "ZIPFoundation", "~> 0.9"
        ss.dependency 'RxSwift', '~> 5'
        ss.dependency 'RxCocoa', '~> 5'
        ss.vendored_framework = "Frameworks/iSpiralCore/bitcode/VerIDCore.xcframework"
    end
    s.subspec 'UI-no-bitcode' do |ss|
        ss.source_files = "VerIDUI/*.swift"
        ss.resource_bundles = { "VerIDUIResources" => ["VerIDUI/Resources/Video/*.mp4", "VerIDUI/Resources/Localization/*.xml", "VerIDUI/Resources/*.xcassets", "VerIDUI/Resources/**.{storyboard,xib}"] }
        ss.dependency "iSpiral/Core-no-bitcode"
        ss.pod_target_xcconfig = {
            "ENABLE_BITCODE" => "NO"
        }
    end
    s.subspec 'Core-no-bitcode' do |ss|
        ss.dependency "OpenCV2", "~> 4.1"
        ss.dependency "ZIPFoundation", "~> 0.9"
        ss.dependency 'RxSwift', '~> 5'
        ss.dependency 'RxCocoa', '~> 5'
        ss.vendored_framework = "Frameworks/iSpiralCore/no-bitcode/VerIDCore.xcframework"
    end
end