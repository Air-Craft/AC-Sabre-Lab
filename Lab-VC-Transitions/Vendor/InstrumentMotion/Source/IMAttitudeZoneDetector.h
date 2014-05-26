/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 12/11/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{ 
 */
/// \file IMAttitudeProximityDetector.h
 
 
#import <Foundation/Foundation.h>
#import "IMDefs.h"
#import "IMMotionDetectorProtocol.h"
#import "IMAttitudeZoneDetectorDelegate.h"

/**
 \brief A detector which lets you define boundaries and zones in the Attitude coord system (pitch, roll, yaw) and which reports entry into/exit from them...
 */
@interface IMAttitudeZoneDetector : NSObject <IMMotionDetectorProtocol>


/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

@property (nonatomic, weak) id<IMAttitudeZoneDetectorDelegate> delegate;


//@{s
/** Min, max range for each axis.  The area which will be subdivided into proximity zones...
 
 -Pi...Pi for Roll, Yaw, -Pi/2...Pi/2 for Pitch
 */
@property (atomic) IMMotionUnit minPitch;
@property (atomic) IMMotionUnit maxPitch;
@property (atomic) IMMotionUnit minRoll;
@property (atomic) IMMotionUnit maxRoll;
@property (atomic) IMMotionUnit minYaw;
@property (atomic) IMMotionUnit maxYaw;
//@}


//@{
/** The number of zones to divide. >=1.  Defaults to 1.
 Zone index range = [-floor(Zone Count/2)..0..+floor(ZoneCount/2)].  Default  = 1 for each so set in order to
 */
@property (atomic) NSUInteger pitchZones;
@property (atomic) NSUInteger rollZones;
@property (atomic) NSUInteger yawZones;
//@}


//@{
/** Readonly index of the proximity zone for each axis in which the device is currently oriented.  (-floor(count/2)..0..+floor(count/2)).  Upon exiting a boundary the highest/lowest zone idx will be reported */
@property (atomic, readonly) NSInteger currentPitchZoneIdx;
@property (atomic, readonly) NSInteger currentRollZoneIdx;
@property (atomic, readonly) NSInteger currentYawZoneIdx;
//@}


//@{
/** Readonly property to check whether and which boundary has been exited. kIMSignNegative/None/Positive (-1.0, 0.0. +1.0) */
@property (atomic, readonly) IMMotionUnit currentExitedPitchBoundary;
@property (atomic, readonly) IMMotionUnit currentExitedRollBoundary;
@property (atomic, readonly) IMMotionUnit currentExitedYawBoundary;
//@}


/** Defaults to NO which means the MotionAnalyzer control thread...
 
 The MotionAnalyzer control thread is used by this class to process the motion data. Setting this to NO (the default) indicates to also use it to make the delegate calls. Set to YES to use main thread instead, which is slower but doesn't require thread safety knowledge. */
@property (nonatomic) BOOL notifyDelegateOnMainThread;

@end

/// @}