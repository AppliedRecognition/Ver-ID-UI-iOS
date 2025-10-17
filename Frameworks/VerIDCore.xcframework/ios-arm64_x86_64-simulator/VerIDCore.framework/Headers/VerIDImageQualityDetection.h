//
//  VerIDImageQualityDetection.h
//  VerIDCore
//
//  Created by Jakub Dolejs on 09/04/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageQualityParams : NSObject

@property double brightness;
@property double contrast;
@property double sharpness;

- (instancetype)init;

- (instancetype)initWithBrightness:(double)brightness
                          contrast:(double)contrast
                         sharpness:(double)sharpness;

@end

@interface VerIDImageQualityDetection : NSObject

+ (double)sharpnessOfImage:(unsigned char *)grayscaleBuffer
                     width:(int)width
                    height:(int)height;

+ (ImageQualityParams *)brightnessContrastAndSharpnessOfImage:(unsigned char *)grayscaleBuffer
                                                        width:(int)width
                                                       height:(int)height;

@end

NS_ASSUME_NONNULL_END
