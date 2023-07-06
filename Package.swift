// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "Ver-ID",
    products: [
        .library(
            name: "VerIDUI",
            targets: ["VerIDUI"]
        ),
        .library(
            name: "VerIDCore",
            targets: ["VerIDCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.16"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.0.0"),
        .package(url: "https://github.com/filom/ASN1Decoder.git", from: "1.8.0"),
        .package(url: "https://github.com/AppliedRecognition/Liveness-Detection-Apple.git", from: "1.1.1"),
        .package(url: "https://github.com/AppliedRecognition/Ver-ID-SDK-Identity-Apple.git", from: "3.0.3")
    ],
    targets: [
        .binaryTarget(
            name: "VerIDCore",
            path: "./Frameworks/VerIDCore.xcframework"
        ),
        .target(
            name: "VerIDUI",
            dependencies: [
                .target(
                    name: "VerIDCore"
                )
            ],
            exclude: [
                "Resources/Localization/translations.py",
                "Resources/Localization/translation_xml.py",
                "Resources/Localization/test_translation.py",
                "Info.plist",
                "Version.xcconfig"
            ],
            resources: [
                .process("Resources/head1.obj"),
                .process("Resources/Video/up_to_centre_3.mp4"),
                .process("Resources/Video/right_down_2.mp4"),
                .process("Resources/Video/left_up_3.mp4"),
                .process("Resources/Video/right_3.mp4"),
                .process("Resources/Video/left_down_3.mp4"),
                .process("Resources/Video/right_down_3.mp4"),
                .process("Resources/Video/left_up_2.mp4"),
                .process("Resources/Localization/vi.xml"),
                .process("Resources/Video/face_mask_off_2.mp4"),
                .process("Resources/Video/face_mask_off_3.mp4"),
                .process("Resources/Video/registration_2.mp4"),
                .process("Resources/Video/left_2.mp4"),
                .process("Resources/Video/liveness_detection_2.mp4"),
                .process("Resources/Video/up_3.mp4"),
                .process("Resources/Video/right_up_2.mp4"),
                .process("Resources/Video/down_3.mp4"),
                .process("Resources/Localization/fr_CA.xml"),
                .process("Resources/Video/face_mask_off_1.mp4"),
                .process("Resources/Video/down_2.mp4"),
                .process("Resources/Video/up_2.mp4"),
                .process("Resources/Video/right_up_3.mp4"),
                .process("Resources/Video/up_to_centre_2.mp4"),
                .process("Resources/Video/left_3.mp4"),
                .process("Resources/Video/left_down_2.mp4"),
                .process("Resources/Localization/es_US.xml"),
                .process("Resources/Video/registration_3.mp4"),
                .process("Resources/Video/liveness_detection_3.mp4"),
                .process("Resources/Video/right_2.mp4")
            ]
        )
    ]
)
