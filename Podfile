project 'VerIDUI.xcodeproj'
workspace 'VerIDUI.xcworkspace'

platform :ios, '11.0'
use_frameworks!

def veridcore
  pod 'Ver-ID-Core', '2.0.0-beta.02'
end

target 'VerIDUI' do
  veridcore
  post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['ENABLE_BITCODE'] = 'YES'
          config.build_settings['BUILD_LIBRARIES_FOR_DISTRIBUTION'] = 'YES'
          config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
          config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = "arm64"
          if config.name == 'Release'
            config.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
            config.build_settings['OTHER_CFLAGS'] = '-faligned-allocation -fembed-bitcode'
            config.build_settings['OTHER_LDFLAGS'] = '-faligned-allocation -fembed-bitcode'
          else
            config.build_settings['BITCODE_GENERATION_MODE'] = 'marker'
            config.build_settings['OTHER_CFLAGS'] = '-faligned-allocation -fembed-bitcode-marker'
            config.build_settings['OTHER_LDFLAGS'] = '-faligned-allocation -fembed-bitcode-marker'
          end
        end
      end
    end
end

target 'Ver-ID Sample' do
  pod 'DeviceKit', '~> 2.0'
end

target 'Thumbnails' do
  veridcore
end

target 'Preview' do
  veridcore
end
