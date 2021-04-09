//
//  DetRecLib.h
//  VerID
//
//  Created by Jakub Dolejs on 18/12/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DetRecLibSettings.h"
#import "VerIDFaceDetectionOptions.h"
#import "TrackingSession.h"
#import "VerIDRecognizable.h"
#import "VerIDImageFormat.h"

@class VerIDFace;
@class VerIDEulerAngle;

NS_ASSUME_NONNULL_BEGIN

/**
 Thin Objective C wrapper around the core C++ library
 */
@interface DetRecLib : NSObject

@property DetRecLibSettings *settings;
@property (atomic) float faceExtractQualityThreshold;
@property (atomic) float landmarkTrackingQualityThreshold;

/**
 Initializer

 @param settings Library settings
 @param error Error pointer to initialization failure
 @return Instance
 */
- (nullable id) initWithSettings:(nonnull DetRecLibSettings *)settings
                           error:(NSError **)error;

/**
 Detect faces in image

 @param imageBuffer Image pixel values
 @param width Width of the image in pixels
 @param height Height of the image in pixels
 @param imageFormat Format of the image in the buffer
 @param exifOrientation Orientation of the image expressed as EXIF tag value 
 @param limit Maximum number of faces to detect
 @param options Option flags (reserved for future use)
 @param error Error pointer to failure
 @return Array of detected faces
 */
- (nullable NSArray<VerIDFace *> *) detectFacesInImageBuffer:(unsigned char *)imageBuffer
                                                       width:(int)width
                                                      height:(int)height
                                                 bytesPerRow:(unsigned int)bytesPerRow
                                                 imageFormat:(VerIDImageFormat)imageFormat
                                             exifOrientation:(int)exifOrientation
                                                       limit:(int)limit
                                                     options:(VerIDFaceDetectionOptions)options
                                                       error:(NSError **)error;

/**
 Track face using a face tracking session

 @param session Face tracking session
 @param imageBuffer Image pixel values
 @param width Width of the image in pixels
 @param height Height of the image in pixels
 @param imageFormat Format of the image in the buffer
 @param exifOrientation Orientation of the image expressed as EXIF tag value
 @param error Error pointer to failure
 @return Tracked face or <code>NULL</code> if no face detected
 */
- (nullable VerIDFace *) trackFaceInSession:(TrackingSession *)session
                                imageBuffer:(unsigned char *)imageBuffer
                                      width:(int)width
                                     height:(int)height
                                bytesPerRow:(unsigned int)bytesPerRow
                                imageFormat:(VerIDImageFormat)imageFormat
                            exifOrientation:(int)exifOrientation
                                      error:(NSError **)error;

/**
 Extract face recognition template from a face

 @param face Face from which to extract the recognition template
 @param imageBuffer Image pixel values
 @param width Width of the image in pixels
 @param height Height of the image in pixels
 @param imageFormat Format of the image in the buffer
 @param exifOrientation Orientation of the image expressed as EXIF tag value
 @param error Error pointer to failure
 @return Face suitable for face recognition
 */
- (nullable NSData *) extractTemplateFromFace:(VerIDFace *)face
                                inImageBuffer:(unsigned char *)imageBuffer
                                        width:(int)width
                                       height:(int)height
                                  bytesPerRow:(unsigned int)bytesPerRow
                                  imageFormat:(VerIDImageFormat)imageFormat
                              exifOrientation:(int)exifOrientation
                                        error:(NSError **)error;

- (float) extractFaceMaskAttributeFromFace:(VerIDFace *)face
                             inImageBuffer:(unsigned char *)imageBuffer
                                     width:(int)width
                                    height:(int)height
                               bytesPerRow:(unsigned int)bytesPerRow
                               imageFormat:(VerIDImageFormat)imageFormat
                           exifOrientation:(int)exifOrientation
                                     error:(NSError **)error;

/**
 Compare subject's faces to other faces

 @param subjectFaces Subject faces
 @param faces Faces to compare the subject faces to
 @param error Error pointer to failure
 @return Similarity score
 */
- (nullable NSNumber *) compareSubjectFaces:(NSArray<id<VerIDRecognizable>> *)subjectFaces
                                    toFaces:(NSArray<id<VerIDRecognizable>> *)faces
                                      error:(NSError **)error;


- (nullable UIImage *) diagnosticImageFromImageBuffer:(unsigned char *)imageBuffer
                                                width:(int)width
                                               height:(int)height
                                          bytesPerRow:(unsigned int)bytesPerRow
                                          imageFormat:(VerIDImageFormat)imageFormat
                                      exifOrientation:(int)exifOrientation
                                                error:(NSError **)error;

/**
 Detect the sharpness of an image

 @param imageBuffer Image pixel values
 @param width Width of the image in pixels
 @param height Height of the image in pixels
 @param error Error pointer to failure
 @return Sharpness score
 */
- (nullable NSNumber *) sharpnessOfImageBuffer:(unsigned char *)imageBuffer
                                         width:(int)width
                                        height:(int)height
                                   bytesPerRow:(unsigned int)bytesPerRow
                                   imageFormat:(VerIDImageFormat)imageFormat
                                         error:(NSError **)error;

- (nullable NSArray<NSNumber *> *) rawTemplateFromTemplateData:(NSData *)templateData
                                                         error:(NSError **)error;

- (nullable NSData *) generateFaceTemplate:(NSError **)error;

- (nullable NSData *) generateFaceTemplateWithScore:(NSNumber *)score
                                        againstFace:(id<VerIDRecognizable>)face
                                              error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
