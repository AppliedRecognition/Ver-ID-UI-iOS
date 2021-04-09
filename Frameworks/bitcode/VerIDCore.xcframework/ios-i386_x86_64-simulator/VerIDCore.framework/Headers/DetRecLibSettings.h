//
//  DetRecLibSettings.h
//  VerID
//
//  Created by Jakub Dolejs on 18/12/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LogLevel) {
    LogLevelNone = -1,
    LogLevelFatal = 0,
    LogLevelError = 1,
    LogLevelWarning = 2,
    LogLevelInfo = 3,
    LogLevelDebug = 4,
    LogLevelDetail = 5,
    LogLevelTrace = 6
};

NS_ASSUME_NONNULL_BEGIN

@interface DetRecLibSettings : NSObject

@property unsigned detectorVersion;
@property float confidenceThreshold;
@property float sizeRange;
@property unsigned rollRangeLarge;
@property unsigned rollRangeSmall;
@property unsigned yawRangeLarge;
@property unsigned yawRangeSmall;
@property unsigned landmarkOptions;
@property unsigned matrixTemplateVersion;
@property unsigned yawPitchVariant;
@property unsigned eyeDetectionVariant;
@property unsigned defaultTemplateVersion;
@property bool reduceConfidenceCalculation;
@property unsigned lightingMatrix;
@property unsigned lightingCompensation;
@property unsigned poseVariant;
@property unsigned poseCompensation;
@property bool detectSmile;
@property float qualityThreshold;
@property bool attemptMultiThreading;
@property float faceExtractQualityThreshold;
@property float landmarkTrackingQualityThreshold;
@property (nullable) NSURL * modelsURL;
@property LogLevel logLevel;

- (instancetype) initWithModelsURL:(nullable NSURL *)modelsURL;

@end

NS_ASSUME_NONNULL_END
