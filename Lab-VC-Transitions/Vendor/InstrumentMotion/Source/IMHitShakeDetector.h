/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 31/10/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{ 
 */
/// \file IMHitShakeDetector.h

#import <Foundation/Foundation.h>

#import "IMHitShakeDetectorDelegate.h"
#import "IMMotionDetectorProtocol.h"



/**
 \brief 
 
 \section Positive Negative Edge
 "Positive Edge" hits mean ones where the initial direction (velocity) is positive and the direction after the snap is negative.  Vice versa for "Negative Edge".  This doesn't imply which hemisphere of *position* the hit occurs in.  This is a separate consideration...
 
 \section Detection Algorithms
 \subsection Gyroscope Hit
  = Velocity Sign Change + Accel Threshold + Attitude Hemisphere Threshold
 
 A velocity sign change must occur in the correlated attitude's hemisphere of the opposite sign.  For example a velocity change to - means a Positive Edge GyroZ Hit (see above) can only occur when Yaw > 0.
 
 */
@interface IMHitShakeDetector : NSObject <IMMotionDetectorProtocol>


/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

@property (nonatomic, weak) id<IMHitShakeDetectorDelegate> delegate;

/** Bitmask descriptor of the axes & directions to check for hits. Defaults to kIMHitShakeAxisDescriptorAnyGyro */
@property (atomic) IMHitShakeAxisDescriptor activeHitAxes;

/** Bitmask descriptor of the axes & directions to check for shakes. Defaults to kIMHitShakeAxisDescriptorAnyGyro */
@property (atomic) IMHitShakeAxisDescriptor activeShakeAxes;

/** 
 Minimum for the normalised intensity to trigger a hit
 0-1 based value.  0 = anything shift triggers, 1 = only the hardest action triggers.  Default = 0.1
 */
@property (atomic) IMMotionUnit threshold;

/**
 0-1 based value.  1 = smooth gradation in intensity from 0 for weakest trigger (ie, the threshold) to 1 for the hardest.  Decrease to have max intensity registered with less exertion.  0 = every trigger is max intensity no matter how hard or soft.  Default = 1.
 */
@property (atomic) IMMotionUnit sensitivity;

@property (atomic) NSTimeInterval _deltaTimeThresh;
@property (atomic) IMMotionUnit _deltaVelThreshForMinIntensity;
@property (atomic) IMMotionUnit _deltaVelThreshForMaxIntensity;
@property (atomic) IMMotionUnit _deltaPosThreshForMinIntensity;
@property (atomic) IMMotionUnit _deltaPosThreshForMaxIntensity;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Init
/////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////


@end

/// @}