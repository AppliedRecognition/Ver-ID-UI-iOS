//
//  FaceDetectionOptions.h
//  VerID
//
//  Created by Jakub Dolejs on 02/01/2019.
//  Copyright © 2019 Applied Recognition, Inc. All rights reserved.
//

typedef NS_OPTIONS(NSUInteger, VerIDFaceDetectionOptions) {
    VerIDFaceDetectionOptionsSkipHaar = 1 << 0,
    VerIDFaceDetectionOptionsExtractFaceTemplates = 1 << 1,
    VerIDFaceDetectionOptionsDisablePoseCompensation = 1 << 2,
    VerIDFaceDetectionOptionsReduceSizeRange = 1 << 3
} NS_SWIFT_NAME(FaceDetectionOptions);
