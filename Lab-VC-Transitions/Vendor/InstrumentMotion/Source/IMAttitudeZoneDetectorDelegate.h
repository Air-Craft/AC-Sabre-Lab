/**
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 12/11/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{
 */
/// \file IMAttitudeZoneDetectorDelegate.h


#import <Foundation/Foundation.h>

@class IMAttitudeZoneDetector;

@protocol IMAttitudeZoneDetectorDelegate <NSObject>

@optional

/** Reported when a new zone is entered.  Optional.  You can read the Prox Detectors properties directly as an alternative*/
- (void)detector:(IMAttitudeZoneDetector *)aDetector didReportNewAttititudeZoneWithIndicesForPitch:(NSInteger)pitchZoneIdx roll:(NSInteger)rollZoneIdx yaw:(NSInteger)yawZoneIdx;

/** Reported when the device crosses a min/max boundary for one or more axes...  
 
    IMMotionUnit compatible.  The reported properties are the current state of all boundaries regardless of whether is was just crosssed or not.
 
    Params are -1.0, 0, 1.0 or kIMSignNegative/None/Positive.  On entry, the axis value will become None. While exited, Positive or Negative
 */
- (void)detector:(IMAttitudeZoneDetector *)aDetector didReportEntryOrExitBoundaryWithExitStatesForPitch:(IMMotionUnit)pitchBoundarySign roll:(IMMotionUnit)rollBoundarySign yaw:(IMMotionUnit)yawBoundarySign;

@end


/// @}