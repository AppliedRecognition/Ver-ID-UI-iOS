//
//  Errors.h
//  VerIDCore
//
//  Created by Jakub Dolejs on 06/02/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

#ifndef Errors_h
#define Errors_h

typedef NS_ENUM(NSInteger, VerIDErrorCode) {
    VerIDErrorCodeFaceDetectionFailed,
    VerIDErrorCodeTemplateExtractionFailed,
    VerIDErrorCodeInvalidAPIKey,
    VerIDErrorCodeInvalidAPISecret,
    VerIDErrorCodeInvalidModelsURL,
    VerIDErrorCodeDetRecLibError,
    VerIDErrorCodeFaceTrackingFailed,
    VerIDErrorCodeSubjectCreationFailed,
    VerIDErrorCodeFaceComparisonFailed,
    VerIDErrorCodeImageSharpnessDetectionFailed,
    VerIDErrorCodeUnsupportedImageFormat,
    VerIDErrorCodeFaceAttributeExtractionFailed,
    VerIDErrorCodeFaceTemplateGenerationFailed,
};

#define kVerIDErrorDomain @"com.appliedrec.verid"

#endif /* Errors_h */
