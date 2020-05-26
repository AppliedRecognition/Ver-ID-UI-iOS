Pod::Spec.new do |s|
    s.name         = "Ver-ID-UI"
    s.module_name  = "VerIDUI"
    s.version      = "1.12.3"
    s.summary      = "Face detection and recognition"
    s.homepage     = "https://github.com/AppliedRecognition"
    s.license      = { :type => "COMMERCIAL", :file => "LICENCE.txt" }
    s.author       = "Jakub Dolejs"
    s.platform     = :ios, "10.0"
    s.swift_version = "5"
    s.documentation_url = "https://appliedrecognition.github.io/Ver-ID-UI-iOS"
    s.source       = { :git => "https://github.com/AppliedRecognition/Ver-ID-UI-iOS.git", :tag => "v#{s.version}" }
    s.source_files = "VerIDUI/*.swift"
    s.resources    = "VerIDUI/Video/*.mp4", "VerIDUI/Localization/*.xml", "VerIDUI/*.xcassets", "VerIDUI/**.{storyboard,xib}"
    s.dependency "Ver-ID-Core", ">= #{s.version}", "< 2.0"
end
