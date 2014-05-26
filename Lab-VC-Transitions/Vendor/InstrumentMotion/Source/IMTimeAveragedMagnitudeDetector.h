/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 20/11/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{ 
 */
/// \file IMTimeAveragedMagnitudeDetector.h

#import <UIKit/UIKit.h>
#import "IMMotionDetectorProtocol.h"

#warning If these props are atomic, then we need to use the getter in the class or wrap the call and do atomic manually.  Same tieh timeWindow


@interface IMTimeAveragedMagnitudeDetector : NSObject <IMMotionDetectorProtocol>

@property (nonatomic, strong) void (^onUpdateBlock)(IMTimeAveragedMagnitudeDetector *sender);


/** Set to YES to have the updateBlock called on the ,ain thread instead of the internal control thread. Default = NO.  
 
 The control thread is more efficient but requires thread safety considerations
 */
@property (nonatomic) BOOL notifyOnMainThread;

/** Creates or updates detection for an axis or axis combination.  Resets any pre-existing detectors for that axis bitmask. THREAD SAFE.
 \param anAxisBitmask  Combinations of axes are cool.
 \param aMotionType    Combinations are not cool.  No bitmasking though the enum supports it
 */
- (void)setDetectionForAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType timeWindow:(NSTimeInterval)theTimeWindow;

/** Returns silently if doesnt exist. THREAD SAFE. */
- (void)removeDetectionForAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType;

/** Returns the current average for the given axis combination. THREAD SAFE 
 \return The time averaged magnitude or 0 plus an IMLogWarn if the current axis/motion type is not being tracked
 */
- (IMMotionUnit)valueForDetectionAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType;

/** Returns the value normalised to 0 <= v <= 1. THREAD SAFE 
 \see valueForDetectionAxis:motionType
 \return The time averaged magnitude or 0 plus an IMLogWarn if the current axis/motion type is not being tracked
 \todo These really need handling separate from the MAX constants used elsewhere as these are too high
*/
- (IMMotionUnit)normalizedValueForDetectionAxis:(IMAxis)anAxisBitmask motionType:(IMMotionType)aMotionType;

/** Reset the data back to zero */
- (void)reset;

@end

/// @}