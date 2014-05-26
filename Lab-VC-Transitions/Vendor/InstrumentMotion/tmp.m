//
//  MotionAnalyzer.m
//  SoundWand
//
//  Created by Hari Karam Singh on 07/08/2011.
//  Copyright 2011 Amritvela. All rights reserved.
//

#import "IMMotionAnalyzer.h"
 
/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


@interface IMMotionAnalyzer()

/// Update all the observers as per their requested thread and frame interval params
- (void)notifyObserversWithMotionData:(IMMotionData *)data;

/**
 Use velocity and accel to extrapolate the new value for the given time delta 
 @{
 */
- (void)extrapolatePitchInto:(IMMotionData *)dataRef forTimeDelta:(NSTimeInterval)deltaTime;
- (void)extrapolateRollInto:(IMMotionData *)dataRef forTimeDelta:(NSTimeInterval)deltaTime;
- (void)extrapolateYawInto:(IMMotionData *)dataRef forTimeDelta:(NSTimeInterval)deltaTime;
/// @}

@end



/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


@implementation IMMotionAnalyzer

/////////////////////////////////////////////////////////////////////////

@synthesize isEngaged;
@synthesize allowExtendedYaw, allowExtendedRoll, allowExtendedPitch;
@synthesize latestMotionData;
@synthesize reversePitchOrientation, reverseYawOrientation, reverseRollOrientation;

/////////////////////////////////////////////////////////////////////////

- (id)initWithPollingInterval:(NSTimeInterval)pollingIntvl
            oversamplingRatio:(NSUInteger)oversampRatio 
       attitudeReferenceFrame:(CMAttitudeReferenceFrame)refFrame 
                 threadProxy:(id<IMThreadProxyProtocol>)aThreadProxy
{
    if (self = [super init]) {
        
        // Sanity checks
        if (oversampRatio < 1) {
            [NSException raise:NSInvalidArgumentException format:@"Oversampling ratio must be >= 1"];
        }
        if (pollingIntvl <= 0.0) {
            [NSException raise:NSInvalidArgumentException format:@"Polling frequency ratio must be > 0.0"];
        }
        
        // Init args
        pollingInterval = pollingIntvl;
        oversamplingRatio = oversampRatio;
        referenceFrame = refFrame;
        threadProxy = aThreadProxy;
        
        // Core Motion
        motionManager = [[CMMotionManager alloc] init];

        // Check for device functionality unless simulator.  It does no harm if 
        // CM is not available.  You'll just get no motion.
#if !TARGET_IPHONE_SIMULATOR
        if (!motionManager.deviceMotionAvailable) {
            return self = nil;
        }
#endif        
        // Initialise ivars for calculating derived motion parameters
        latestMotionData = nil; // must begin as nil.  Init'ed in the update method
        prevMotionData = nil;
        
        // Observer info
        intMotionObservers = [NSMutableArray array];
        extMotionObservers = [NSMutableArray array];
        motionObserversFrameCountsDict = [IMMutableDictionary dictionary];
        
        // Initialise the thread with an invocation to our update method
        // If nil then it's expected the client cllas updateMotionData
        if (threadProxy != nil) {
            SEL sel = @selector(updateMotionData);
            NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:sel];
            NSInvocation *invoc = [NSInvocation invocationWithMethodSignature:sig];
            [invoc setSelector:sel];
            [invoc setTarget:self];
            [threadProxy addInvocation:invoc desiredInterval:(pollingInterval / (NSTimeInterval)oversampRatio)];
        }
    }
    return self;
}

/**********************************************************************/

/// Defaul to 60Hz, no oversampling, CorrectedZVertical ref frame and no callback (client does it)
- (id)init
{
    return [self initWithPollingInterval:0.01667 oversamplingRatio:1u attitudeReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical threadProxy:nil];
}

/** ********************************************************************/

- (void)dealloc 
{
    [motionManager stopDeviceMotionUpdates];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Property Getter/Setters
/////////////////////////////////////////////////////////////////////////

- (IMMotionData *)latestMotionData
{
    IMMotionData *data;
    @synchronized(latestMotionData) {
        data = [latestMotionData copy];
    }
    return data;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////

- (void)engage
{
    NSAssert(!isEngaged, @"Motion Analzer is already engaged!");
    
    // Init the motion manager and polling timer
    if (![motionManager isDeviceMotionActive]) {
            
        // Check for new iOS 5 magneto-enhanced yaw support
        //CMAttitudeReferenceFrame refFrame = CMAttitudeReferenceFrameXArbitraryCorrectedZVertical;
        if ([CMMotionManager availableAttitudeReferenceFrames] & referenceFrame) {
            [motionManager startDeviceMotionUpdatesUsingReferenceFrame:referenceFrame];
        } else {
            [motionManager startDeviceMotionUpdates];
        }
    }
    currentFrame = -1;  // We'll inc this at the beginning of the loop 
    
    isEngaged = YES;
}

/** ********************************************************************/

- (void)disengage
{
    NSAssert(isEngaged, @"Motion Analzer is disengaged!");
    
    isEngaged = NO;
    [motionManager stopDeviceMotionUpdates];
    
    prevMotionData = nil;
    latestMotionData = nil;
    
}

/////////////////////////////////////////////////////////////////////////

- (void)reset
{
    // Reset all detectors and observers
    for (id<IMMotionObserver>observer in extMotionObservers) {
        if ([observer respondsToSelector:@selector(reset)]) {
            [observer reset];
        }
    }
    for (id<IMMotionObserver>observer in intMotionObservers) {
        if ([observer respondsToSelector:@selector(reset)]) {
            [observer reset];
        }
    }    
}

/////////////////////////////////////////////////////////////////////////

- (void)addMotionObserver:(id<IMMotionObserver>)observer frameCount:(NSUInteger)frameCount
{
    [extMotionObservers addObject:observer];
    [motionObserversFrameCountsDict setObject:[NSNumber numberWithUnsignedInteger:frameCount] forKey:observer];
}

- (void)removeMotionObserver:(id<IMMotionObserver>)observer
{
    [extMotionObservers removeObject:observer];
    [motionObserversFrameCountsDict removeObjectForKey:observer];
}

/** ********************************************************************/

- (void)addMotionObserverOnInternalThread:(id<IMMotionObserver>)observer frameCount:(NSUInteger)frameCount
{
    [intMotionObservers addObject:observer];
    [motionObserversFrameCountsDict setObject:[NSNumber numberWithUnsignedInteger:frameCount] forKey:observer];
}

- (void)removeMotionObserverOnInternalThread:(id<IMMotionObserver>)observer
{
    [intMotionObservers removeObject:observer];
    [motionObserversFrameCountsDict removeObjectForKey:observer];
}

/** ********************************************************************/

- (void)addMotionObserver:(id<IMMotionObserver>)observer
{
    [self addMotionObserver:observer frameCount:1u];
}

- (void)addMotionObserverOnInternalThread:(id<IMMotionObserver>)observer
{
    [self addMotionObserverOnInternalThread:observer frameCount:1u];
}

/** ********************************************************************/

- (void)addDetector:(id<IMMotionDetector>)detector
{
    // Simply an internal motion observer at the mo'
    [self addMotionObserverOnInternalThread:detector frameCount:1u];
    
}

- (void)removeDetector:(id<IMMotionDetector>)detector
{
    [self removeMotionObserverOnInternalThread:detector];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////

- (void)updateMotionData
{
    if (!isEngaged) {
        IMLOG("updateMotionData called while disengaged.  Aborting...");
        return;
    }
    
    //NSTimeInterval t0;
    //t0 = CACurrentMediaTime();
    
    CMAttitude *attitude = nil;
    CMRotationRate rotationRate = {0};
    CMAcceleration acceleration = {0};
    CMDeviceMotion *deviceMotion = [motionManager deviceMotion];
    CFTimeInterval timestamp = 0;
    CFTimeInterval deltaTime = 1;   
    IMMotionData *latestMotionDataLocal = [[IMMotionData alloc] init];
    static IMMotionUnit lastSampledYaw, lastSampledYawVel;
    static NSTimeInterval lastSampledYawTimestamp;
    static IMMotionUnit lastSampledPitch, lastSampledPitchVel;
    static NSTimeInterval lastSampledPitchTimestamp;
    static IMMotionUnit lastSampledRoll, lastSampledRollVel;
    static NSTimeInterval lastSampledRollTimestamp;
    static IMMotionUnit lastSampledRotXVel;
    static NSTimeInterval lastSampledRotXTimestamp;
    static IMMotionUnit lastSampledRotYVel;
    static NSTimeInterval lastSampledRotYTimestamp;
    static IMMotionUnit lastSampledRotZVel;
    static NSTimeInterval lastSampledRotZTimestamp;
    static IMMotionUnit lastSampledXVel;
    static NSTimeInterval lastSampledXTimestamp;
    static IMMotionUnit lastSampledYVel;
    static NSTimeInterval lastSampledYTimestamp;
    static IMMotionUnit lastSampledZVel;
    static NSTimeInterval lastSampledZTimestamp;

    
    // Used to determine whether this round is an extrapolation round as per 
    // the oversampling or whether we try to get it direct from CoreMotion
    BOOL isOversampleRound = (++currentFrame % oversamplingRatio != 0);
    
    timestamp = CACurrentMediaTime();
    
    // Store the last sample and grab the new one
    @synchronized(latestMotionData) {
        if (nil == latestMotionData) {
            latestMotionData = [[IMMotionData alloc] init];
        } else {
            // No need to copy as latestMotionData pointer gets reassigned to ...Local
            prevMotionData = latestMotionData;        // = nil on first run
        }
    }
    
    if (prevMotionData != nil)
        deltaTime = timestamp - prevMotionData.timestamp;
    
    // If this is a multisample round (and not the first somehow, j.i.c.)
    // Don't waste time with CoreMotion, just extrapolate, notify and return
    if (isOversampleRound && prevMotionData != nil) {
        [self extrapolateYawInto:latestMotionDataLocal forTimeDelta:deltaTime];
        [self extrapolatePitchInto:latestMotionDataLocal forTimeDelta:deltaTime];
        [self extrapolateRollInto:latestMotionDataLocal forTimeDelta:deltaTime];

        // TEMP:  Just copy these for the moment...
        latestMotionDataLocal.rotationalXVelocity = prevMotionData.rotationalXVelocity;
        latestMotionDataLocal.rotationalYVelocity = prevMotionData.rotationalYVelocity;
        latestMotionDataLocal.rotationalZVelocity = prevMotionData.rotationalZVelocity;
        
        @synchronized(latestMotionData) {
            latestMotionData = latestMotionDataLocal;
        }
        [self notifyObserversWithMotionData:[latestMotionDataLocal copy]];
        return;
    }
    
    // Otherwise poll CM...
    attitude = deviceMotion.attitude;
    rotationRate = deviceMotion.rotationRate;
    acceleration = deviceMotion.userAcceleration;
    
    latestMotionDataLocal.pitch = [attitude pitch] * (reversePitchOrientation ? -1 : 1);
    latestMotionDataLocal.roll = [attitude roll] * (reverseRollOrientation ? -1 : 1);
    latestMotionDataLocal.yaw = [attitude yaw] * (reverseYawOrientation ? -1 : 1); 
    // + 2*M_PI * rotationMultiplier;// * alpha + (1-alpha)*self.latestMotionData.yaw;
    
    latestMotionDataLocal.rotationalXVelocity = rotationRate.x;
    latestMotionDataLocal.rotationalYVelocity = rotationRate.y;
    latestMotionDataLocal.rotationalZVelocity = rotationRate.z;

    latestMotionDataLocal.xVelocity = acceleration.x;
    latestMotionDataLocal.yVelocity = acceleration.y;
    latestMotionDataLocal.zVelocity = acceleration.z;

    
    latestMotionDataLocal.timestamp = timestamp;
    
    // First run?  Add data to the extrapolator if this is the first run, otherwise, we'll add it later (if it's not bogus duplicate data)
    if (prevMotionData == nil) {
        lastSampledYaw = latestMotionDataLocal.yaw;          // since latestMotionData might contain extrapolated values
        lastSampledPitch = latestMotionDataLocal.pitch;
        lastSampledRoll = latestMotionDataLocal.roll;
        lastSampledRotXVel = latestMotionDataLocal.rotationalXVelocity;
        lastSampledRotYVel = latestMotionDataLocal.rotationalYVelocity;
        lastSampledRotZVel = latestMotionDataLocal.rotationalZVelocity;
        lastSampledXVel = latestMotionDataLocal.xVelocity;
        lastSampledYVel = latestMotionDataLocal.yVelocity;
        lastSampledZVel = latestMotionDataLocal.zVelocity;

        
        lastSampledPitchTimestamp = lastSampledRollTimestamp = lastSampledYawTimestamp =
        lastSampledRotXTimestamp = lastSampledRotYTimestamp = lastSampledRotZTimestamp =
        lastSampledXTimestamp = lastSampledYTimestamp = lastSampledZTimestamp = timestamp;
        
        @synchronized(latestMotionData) {
            latestMotionData = latestMotionDataLocal;   // No need to copy as it will release its ref by the next iteration
        }
        return;
    }
    
    // Detect wrap around.  Safe to do here as it will detect false for dups
  /*  if (allowExtendedYaw) {
        
   // IMPORTANT TO CHECK SIGN,  OTHERWISE SLOW DEVICE RESPONSE COULD YIELD FALSE POSITIVE!
        // If sign changed ( = 2 possible point crossings)
        //if ( (prevMotionData.yaw > 0 && latestMotionDataLocal.yaw < 0) || 
        //     (prevMotionData.yaw < 0 && latestMotionDataLocal.yaw > 0) ) {
            
            // If velocity is above our detection thresh range of our 
        IMMotionUnit vel = (latestMotionDataLocal.yaw - prevMotionData.yaw) / deltaTime;
        if (fabs(vel) >= IM_WRAP_AROUND_DETECTION_VELOCITY_THRESHOLD) {
            // Positive -> negative border crossing is actually a POSITIVE motion
            if (vel < 0) {
                rotationMultiplier++;
                latestMotionDataLocal.yaw += 2*M_PI;
            } else {
                rotationMultiplier--;
                latestMotionDataLocal.yaw -= 2*M_PI;
            }
            IMLOG(@"Rotation Multiplier: %i", rotationMultiplier);
//            latestMotionDataLocal.yaw += 2*M_PI;
        }
        //}
    }*/
    //DLOG(@"%.4f -> %.4f", prevMotionData.yaw, latestMotionDataLocal.yaw)
//    DLOGf(IM_RAD2DEG(latestMotionDataLocal.yaw));

    // Check against the last non-duplicate sample whether this sample is a dup 
    BOOL yawIsDup = (fabs(latestMotionDataLocal.yaw - lastSampledYaw) < IM_DUPLICATE_THRESHOLD);
    BOOL pitchIsDup = (fabs(latestMotionDataLocal.pitch - lastSampledPitch) < IM_DUPLICATE_THRESHOLD);
    BOOL rollIsDup = (fabs(latestMotionDataLocal.roll - lastSampledRoll) < IM_DUPLICATE_THRESHOLD);

    // Get the new coords.  If duplicate extrapolate but don't feed the extrapolator extrap'ed data, otherwise it diverges quickly!
    if (yawIsDup) {
        IMLOG(@"WARNING: Duplicate value for YAW.  If frequent, consider increasing the polling interval.");
        [self extrapolateYawInto:latestMotionDataLocal forTimeDelta:deltaTime];
    } else {
        // Don't worry if these are 0
        latestMotionDataLocal.yawVelocity = (latestMotionDataLocal.yaw - lastSampledYaw) / (timestamp - lastSampledYawTimestamp);
        latestMotionDataLocal.yawAccel = (latestMotionDataLocal.yawVelocity - lastSampledYawVel) / (timestamp - lastSampledYawTimestamp);
        
        lastSampledYaw = latestMotionDataLocal.yaw;
        lastSampledYawVel = latestMotionDataLocal.yawVelocity;
        lastSampledYawTimestamp = timestamp;

    }

    if (pitchIsDup) {
        IMLOG(@"Duplicate value for PITCH.  If frequent, consider increasing the polling interval.");
        [self extrapolatePitchInto:latestMotionDataLocal forTimeDelta:deltaTime];
    } else {
        // Don't worry if these are 0
        latestMotionDataLocal.pitchVelocity = (latestMotionDataLocal.pitch - lastSampledPitch) / (timestamp - lastSampledPitchTimestamp);
        latestMotionDataLocal.pitchAccel = (latestMotionDataLocal.pitchVelocity - lastSampledPitchVel) / (timestamp - lastSampledPitchTimestamp);
        lastSampledPitch = latestMotionDataLocal.pitch;
        lastSampledPitchVel = latestMotionDataLocal.pitchVelocity;
        lastSampledPitchTimestamp = timestamp;
    }
    
    if (rollIsDup) {
        IMLOG(@"Duplicate value for ROLL.  If frequent, consider increasing the polling interval.");
        [self extrapolateRollInto:latestMotionDataLocal forTimeDelta:deltaTime];
    } else {
        // Don't worry if these are 0
        latestMotionDataLocal.rollVelocity = (latestMotionDataLocal.roll - prevMotionData.roll) / (timestamp - lastSampledRollTimestamp);
        latestMotionDataLocal.rollAccel = (latestMotionDataLocal.rollVelocity - prevMotionData.rollVelocity) / (timestamp - lastSampledRollTimestamp);
        
        lastSampledRoll = latestMotionDataLocal.roll;
        lastSampledRollVel = latestMotionDataLocal.rollVelocity;
        lastSampledPitchTimestamp = timestamp;
    }
    
    if (YES) {
        latestMotionDataLocal.rotationalXAccel = (latestMotionDataLocal.rotationalXVelocity - prevMotionData.rotationalXVelocity) / (timestamp - lastSampledRotXTimestamp);
    }
    if (YES) {
        latestMotionDataLocal.rotationalYAccel = (latestMotionDataLocal.rotationalYVelocity - prevMotionData.rotationalYVelocity) / (timestamp - lastSampledRotYTimestamp);
    }
    if (YES) {
        latestMotionDataLocal.rotationalZAccel = (latestMotionDataLocal.rotationalZVelocity - prevMotionData.rotationalZVelocity) / (timestamp - lastSampledRotZTimestamp);
    }
    
    if (YES) {
        latestMotionDataLocal.xAccel = (latestMotionDataLocal.xVelocity - prevMotionData.xVelocity) / (timestamp - lastSampledXTimestamp);
    }
    if (YES) {
        latestMotionDataLocal.yAccel = (latestMotionDataLocal.yVelocity - prevMotionData.yVelocity) / (timestamp - lastSampledYTimestamp);
    }
    if (YES) {
        latestMotionDataLocal.zAccel = (latestMotionDataLocal.zVelocity - prevMotionData.zVelocity) / (timestamp - lastSampledZTimestamp);
    }
    
    
    @synchronized(latestMotionData) {
        latestMotionData = latestMotionDataLocal;
    }
    
    [self notifyObserversWithMotionData:[latestMotionDataLocal copy]];
}

/** ********************************************************************/

- (void)notifyObserversWithMotionData:(IMMotionData *)data
{    
    // First send out the ones which run on external threads, async'ly
    for (id<IMMotionObserver>observer in extMotionObservers) {
        
        // Skip if not in a requested frame
        NSUInteger frameIntv = [[motionObserversFrameCountsDict objectForKey:observer] unsignedIntegerValue];
        if (currentFrame % frameIntv != 0)
            continue;
        
        // Make copies as the values/pointers are inclined to change before 
        // the dispatch processes on its thread
        id<IMMotionObserver> o = observer;
        dispatch_async(dispatch_get_main_queue(), ^{ [o handleMotionUpdate:data]; });
    }
    
    // Then do the synchronous internals ones
    for (id<IMMotionObserver>observer in intMotionObservers) {
        // Skip if not in a requested frame
        NSUInteger frameIntv = [[motionObserversFrameCountsDict objectForKey:observer] unsignedIntegerValue];
        if (currentFrame % frameIntv != 0)
            continue;
        [observer handleMotionUpdate:data];
    }
}

/** ********************************************************************/

- (void)extrapolatePitchInto:(IMMotionData *)dataRef forTimeDelta:(NSTimeInterval)deltaTime
{
    dataRef.pitchAccel = prevMotionData.pitchAccel;
    dataRef.pitchVelocity = prevMotionData.pitchAccel * deltaTime + prevMotionData.pitchVelocity;
    dataRef.pitch = prevMotionData.pitchAccel * deltaTime * deltaTime / 2.0 + prevMotionData.pitchVelocity * deltaTime + prevMotionData.pitch;
}

/** ********************************************************************/

- (void)extrapolateRollInto:(IMMotionData *)dataRef forTimeDelta:(NSTimeInterval)deltaTime
{
    dataRef.rollAccel = prevMotionData.rollAccel;
    dataRef.rollVelocity = prevMotionData.rollAccel * deltaTime + prevMotionData.rollVelocity;
    dataRef.roll = prevMotionData.rollAccel * deltaTime * deltaTime / 2.0 + prevMotionData.rollVelocity * deltaTime + prevMotionData.roll;
}

/** ********************************************************************/

- (void)extrapolateYawInto:(IMMotionData *)dataRef forTimeDelta:(NSTimeInterval)deltaTime
{
    dataRef.yawAccel = prevMotionData.yawAccel;
    dataRef.yawVelocity = prevMotionData.yawAccel * deltaTime + prevMotionData.yawVelocity;
    dataRef.yaw = prevMotionData.yawAccel * deltaTime * deltaTime / 2.0 + prevMotionData.yawVelocity * deltaTime + prevMotionData.yaw;
}


@end
