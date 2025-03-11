//
//  VerIDRecognizable.h
//  VerID
//
//  Created by Jakub Dolejs on 21/12/2018.
//  Copyright © 2018 Applied Recognition, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Recognizable)
/**
 Recognizable protocol definition
 */
@protocol VerIDRecognizable

@required
/**
 Data used for face recognition
 */
@property NSData *recognitionData;

@required
/**
 Version of the data
 */
@property int version;

@end

NS_ASSUME_NONNULL_END
