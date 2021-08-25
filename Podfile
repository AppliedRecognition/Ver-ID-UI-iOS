project 'VerIDUI.xcodeproj'
workspace 'VerIDUI.xcworkspace'

platform :ios, '10.3'
use_frameworks!

abstract_target 'Ver-ID' do
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'ZIPFoundation', '~> 0.9'
  pod 'DeviceKit', '~> 4.4'
  pod 'Ver-ID-SDK-Identity', '>= 3.0.2', '< 4.0'
  
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['ENABLE_BITCODE'] = 'YES'
      if config.name == 'Release'
        config.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
        else
        config.build_settings['BITCODE_GENERATION_MODE'] = 'marker'
      end
    end
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'BUILD_LIBRARY_FOR_DISTRIBUTION'
        config.build_settings.delete 'ENABLE_BITCODE'
        config.build_settings.delete 'BITCODE_GENERATION_MODE'
        if config.name == 'Release'
          config.build_settings['OTHER_CFLAGS'] = '$(inherited) -faligned-allocation -fembed-bitcode'
          config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -faligned-allocation -fembed-bitcode'
          else
          config.build_settings['OTHER_CFLAGS'] = '$(inherited) -faligned-allocation -fembed-bitcode-marker'
          config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -faligned-allocation -fembed-bitcode-marker'
        end
      end
    end
  end
  
  target 'VerIDUI'
  target 'Ver-ID Sample'
  target 'Preview'
  target 'Thumbnails'
end
