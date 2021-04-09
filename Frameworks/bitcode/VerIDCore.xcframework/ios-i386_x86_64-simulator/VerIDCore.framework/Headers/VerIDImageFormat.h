//
//  VerIDImageFormat.h
//  VerIDCore
//
//  Created by Jakub Dolejs on 08/05/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

#ifndef VerIDImageFormat_h
#define VerIDImageFormat_h

typedef enum : NSUInteger {
    VerIDImageFormatGrayscale,
    VerIDImageFormatARGB,
    VerIDImageFormatRGB,
    VerIDImageFormatBGR,
    VerIDImageFormatBGRA,
    VerIDImageFormatABGR,
    VerIDImageFormatRGBA,
    VerIDImageFormatYUV,
    VerIDImageFormatUnknown
} VerIDImageFormat;

#endif /* VerIDImageFormat_h */
