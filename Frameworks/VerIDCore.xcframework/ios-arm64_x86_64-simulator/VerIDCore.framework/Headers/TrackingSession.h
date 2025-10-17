//
//  TrackingSession.h
//  VerIDCore
//
//  Created by Jakub Dolejs on 04/03/2019.
//  Copyright © 2019 Applied Recognition. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef VERIDCORE_H_
#import <tools/FaceDetectionRecognition.hpp>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Wrapper around C++ tracking session
 */
@interface TrackingSession : NSObject

#ifndef VERIDCORE_H_
/**
 C++ library tracking session
 */
@property FaceTrackingSession *session;
#endif

@end

NS_ASSUME_NONNULL_END
