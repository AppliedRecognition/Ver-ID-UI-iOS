project 'VerIDUI.xcodeproj'
workspace 'VerIDUI.xcworkspace'

platform :ios, '12'
use_frameworks!

abstract_target 'Ver-ID' do
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'ZIPFoundation', '~> 0.9'
  pod 'DeviceKit', '~> 4.4'
  pod 'ASN1Decoder', '~> 1.8'
  pod 'Ver-ID-SDK-Identity', '>= 3.0.2', '< 4.0'
  pod 'LivenessDetection', '~> 1.2'
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'BUILD_LIBRARY_FOR_DISTRIBUTION'
        config.build_settings.delete 'ENABLE_BITCODE'
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      end
    end
  end
  
  target 'VerIDUI'
  target 'Ver-ID Sample' do
    pod 'SwiftProtobuf', '~> 1.19'
  end
  target 'Preview' do
    pod 'SwiftProtobuf', '~> 1.19'
  end
  target 'Thumbnails' do
    pod 'SwiftProtobuf', '~> 1.19'
  end
  target 'VerIDUITests'
end
