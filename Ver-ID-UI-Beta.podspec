Pod::Spec.new do |s|
  s.name         = "Ver-ID-UI-Beta"
  s.version      = "1.1.1"
  s.summary      = "Face detection and recognition"
  s.homepage     = "https://github.com/AppliedRecognition"
  s.license      = { :type => "COMMERCIAL", :file => "LICENCE.txt" }
  s.author       = "Jakub Dolejs"
  s.platform     = :ios, "9.0"
  s.swift_version = "5"
  s.source       = { :http => "https://ver-id.s3.amazonaws.com/ios/veridui/1.1.1/VerIDUI.zip" }
  s.vendored_framework = "VerIDUI.framework"
  s.dependency 'Ver-ID-Core-Beta', '1.1.1'
end
