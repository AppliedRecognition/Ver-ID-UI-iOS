#!/bin/sh

xcodebuild archive -workspace VerIDUI.xcworkspace -scheme VerIDUI -sdk iphoneos -arch arm64 -configuration Release -archivePath ./ios.xcarchive BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO | xcpretty

xcodebuild archive -workspace VerIDUI.xcworkspace -scheme VerIDUI -sdk iphonesimulator -arch x86_64 -configuration Release -archivePath ./iossimulator.xcarchive BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO | xcpretty

rm -rf VerIDUI.xcframework

xcodebuild -create-xcframework -framework ./ios.xcarchive/Products/Library/Frameworks/VerIDUI.framework -framework ./iossimulator.xcarchive/Products/Library/Frameworks/VerIDUI.framework -output VerIDUI.xcframework
