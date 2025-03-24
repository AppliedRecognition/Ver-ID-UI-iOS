project 'VerIDUI.xcodeproj'
workspace 'VerIDUI.xcworkspace'

platform :ios, '13.4'
use_frameworks!

abstract_target 'Ver-ID' do
  pod 'DeviceKit', '~> 5.5'
  pod 'ZIPFoundation', '~> 0.9'
  pod 'Ver-ID-SDK-Identity', '>= 3.0.2', '< 4.0'
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'BUILD_LIBRARY_FOR_DISTRIBUTION'
        config.build_settings.delete 'ENABLE_BITCODE'
      end
    end
  end
  
  target 'VerIDUI'
  target 'Ver-ID Sample'
  target 'Preview'
  target 'Thumbnails'
end
