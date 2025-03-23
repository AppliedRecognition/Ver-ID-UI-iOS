project 'VerIDUI.xcodeproj'
workspace 'VerIDUI.xcworkspace'

platform :ios, '13'
use_frameworks!

def rx
  pod 'RxSwift', '~> 6.9'
  pod 'RxCocoa', '~> 6.9'
end

def zip
  pod 'ZIPFoundation', '~> 0.9'
end
  
def devicekit
  pod 'DeviceKit', '~> 5.5'
end

def asn1
  pod 'ASN1Decoder', '~> 1.9'
end

def identity
  pod 'Ver-ID-SDK-Identity', '>= 3.0.2', '< 4.0'
end

def spoofdetection
  pod 'SpoofDeviceDetection/Model', '~> 1.1'
end

def protobuf
  pod 'SwiftProtobuf', '~> 1.19'
end

abstract_target 'Ver-ID' do
  rx
  zip
  devicekit
  asn1
  identity
  spoofdetection
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
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
    protobuf
  end
  target 'Preview' do
    protobuf
  end
  target 'Thumbnails' do
    protobuf
  end
  target 'VerIDUITests'
end
