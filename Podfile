project 'VerIDUI.xcodeproj'
workspace 'VerIDUI.xcworkspace'

platform :ios, '11.0'
use_frameworks!

def veridcore
  pod 'Ver-ID-Core', '2.0.0-beta.01'
end

target 'VerIDUI' do
  veridcore
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
