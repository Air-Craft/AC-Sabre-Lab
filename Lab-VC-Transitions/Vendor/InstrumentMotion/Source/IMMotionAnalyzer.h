//
//  MotionAnalyzer.h
//  SoundWand
//
//  Created by Hari Karam Singh on 07/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import <tgmath.h>
#import <dispatch/queue.h>

#import "IMConfig.h"
#import "IMDefs.h"
#import "IMMotionObserverProtocol.h"
#import "IMMotionDetectorProtocol.h"
#import "IMControlThreadProtocol.h"

/**
 \ingroup   InstrumentMotion
 \brief     Use CoreMotion to analyze gyro, attitude and accelerometer data complete with velocity & accel & other calculations
 
 \section Supported IMMotionSample Components (* = measured directly)
 - Accelerometer: accel*, accelSC only.  Not stable enough to integrate.
 - Gyroscope: All except position ones.  Position doenst really make sense for all axes due to moving reference frame and Gimbal-lock-like issues. Use correlated Attitude axis for position.  Also note that Roll and GyroY rotation are the same.
 
 measures rotatinal velocity.  Rot acceleration is derived.
 
 No longer a singleton but as with CMMotionManager, only one instance 
 is recommended
 
  \todo Thread safety for add/remove methods
 */
@interface IMMotionAnalyzer : NSObject

@property (nonatomic, readonly) BOOL isEngaged;

/// @name ed Enabled/Disable different CoreMotion sensors.  All enabled by default.
@property (nonatomic) BOOL accelerometerEnabled;
@property (nonatomic) BOOL gyroscopeEnabled;
@property (nonatomic) BOOL attitudeEnabled;
/// @}


/// @name Comming Soon
@property (nonatomic) BOOL allowExtendedPitch;
@property (nonatomic) BOOL allowExtendedYaw;
@property (nonatomic) BOOL allowExtendedRoll;
/// @}


/// @name Reverse the orientation of the positive motion for each axis
@property (nonatomic) BOOL reversePitchOrientation;
@property (nonatomic) BOOL reverseYawOrientation;
@property (nonatomic) BOOL reverseRollOrientation;
/// @}

/** Returns the latest read/derived motion sample set of all enabled sensors/axes */
@property (atomic, readonly) IMMotionSampleSet current;

/** Returns the previous iteration's motion sample set */
@property (atomic, readonly) IMMotionSampleSet previous;

/**
 @param pollingIntvl    The time between polling CoreMotion attitude data, before oversampling.  This * oversampling is the max rate at which observers can be notified
 @param oversampRatio   The multiple of the polling rate at which interpolated results will be generated on top of the sampled ones
 @param refFrame        See CMAttitudeReferenceFrame
 @param aThreadProxy    The wrapper thread which will be given an invocation                      to the updateMotionData method.   Alternatively, pass nil and call the update method manually from the client
 @throws    NSInvalidArgumentException  if oversampling < 1 or polling interval < 0
 @return    Nil if coremotion is not available on the device UNLESS we're on simulator in which case the dud object is returned.  It works per-se (as in no exceptions are thrown); it just doesn't
 */
- (id)initWithPollingInterval:(NSTimeInterval)pollingIntvl 
            oversamplingRatio:(NSUInteger)oversampRatio 
       attitudeReferenceFrame:(CMAttitudeReferenceFrame)refFrame 
                 controlThread:(id<IMControlThreadProtocol>)aControlThread;

/**
 Initialise CoreMotion and begin polling motion values
 and calculating derived values
 */
- (void)engage;

/**
 End the timer and stop the CM motion updates and set all 
 motion properties to nil.  Enters a standby
 state.
 */
- (void)disengage;


/** Resets CoreMotion to so that the 0deg yaw is the current device direction and reset iphone5s core motion bugs.  Currently just calls disengage then engage.  If disengaged already then this is a no-op */
- (void)resetAndCalibrateCenter;

/**
 Clears the internal motion data and sends reset to observers if they detect it.  Use to reset data before re-engaging after a disengage. (CURRENTLY NOT THREAD SAFE)
 
 Currently, there is no thread safety locks so only call when disengaged and from a single thread.
 */
- (void)reset;

- (void)addMotionObserver:(id<IMMotionObserverProtocol>)observer;
- (void)addMotionObserverOnInternalThread:(id<IMMotionObserverProtocol>)observer;

- (void)removeMotionObserver:(id<IMMotionObserverProtocol>)observer;
- (void)removeMotionObserverOnInternalThread:(id<IMMotionObserverProtocol>)observer;


/// Add in internal detector which will process on the main thread (though it's detector messages may not be).  Frame count = 1 for these.
- (void)addDetector:(id<IMMotionDetectorProtocol>)detector;
- (void)removeDetector:(id<IMMotionDetectorProtocol>)detector;


@end
