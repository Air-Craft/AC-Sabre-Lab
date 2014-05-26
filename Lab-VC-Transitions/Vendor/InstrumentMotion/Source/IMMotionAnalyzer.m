//
//  MotionAnalyzer.m
//  SoundWand
//
//  Created by Hari Karam Singh on 07/08/2011.
//  Copyright 2011 Amritvela. All rights reserved.
//

#import "IMMotionAnalyzer.h"

#import "IMConfig.h"
#import "IMFunctions.h"
#import "InstrumentMotionDebug.h"
#import "IMControlThreadProtocol.h"
#import "IMMotionData.h"


/////////////////////////////////////////////////////////////////////////
#pragma mark - IMMotionAnalyzer
/////////////////////////////////////////////////////////////////////////


@implementation IMMotionAnalyzer
{
    CMMotionManager *_motionManager;
    CMAttitudeReferenceFrame _referenceFrame;
    
    id<IMControlThreadProtocol>_controlThread;
    NSMutableArray *_intMotionObservers;          ///< MotionObservers which run on the internal thread. Used for detectors
    NSMutableArray *_extMotionObservers;          ///< External motion observers, run on the main thread
    NSTimeInterval _pollingInterval;
    
    NSInteger _currentFrame;                      ///< The count for the notification loop
    NSUInteger _oversamplingRatio;
    
    NSInteger _rotationMultiplier;  ///< How many times around have we gone \todo !

    IMMotionSampleSet _latest;        ///< Short names for convenience below
    IMMotionSampleSet _previous;
    IMMotionSampleSet _latestFromDevice;   ///< ie, NOT interpolated due to oversampling or duplicates
    IMVectorCoord _lastfiltAccel;
    IMMotionUnit _filtR;
    
    /** Marks coord at last sign change of its derivative. Used for posDeltaSinceSC etc params */
    IMVectorCoord _attitidePosAtLastSC;  ///< last *velocity* sign change
    IMVectorCoord _attitideVelAtLastSC;  ///< last *accel* sign change
    IMVectorCoord _gyroVelAtLastSC;      ///< last *accel* sign change

}



/////////////////////////////////////////////////////////////////////////

- (id)initWithPollingInterval:(NSTimeInterval)pollingIntvl
            oversamplingRatio:(NSUInteger)oversampRatio 
       attitudeReferenceFrame:(CMAttitudeReferenceFrame)refFrame 
                 controlThread:(id<IMControlThreadProtocol>)aControlThread
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
        _pollingInterval = pollingIntvl;
        _oversamplingRatio = oversampRatio;
        _referenceFrame = refFrame;
        _controlThread = aControlThread;
        _accelerometerEnabled = YES;
        _gyroscopeEnabled = YES;
        _attitudeEnabled = YES;
        _filtR = 1 - (2*M_PI * IM_ACCELEROMETER_HIPASS_FILTER_FREQ * _pollingInterval);
        // y_n = x_n + x_n-1 + R * y_n-1
        // R = 1 - (2pi * hipassfreq / samplerate)
        
        // Core Motion
        _motionManager = [[CMMotionManager alloc] init];

        // Check for device functionality unless simulator.  It does no harm if
        // CM is not available.  You'll just get no motion.
#if !TARGET_IPHONE_SIMULATOR
        if (!_motionManager.deviceMotionAvailable) {
            return self = nil;
        }
#endif        
        
        // Observer info
        _intMotionObservers = [NSMutableArray array];
        _extMotionObservers = [NSMutableArray array];
        
        // Initialise the thread with an invocation to our update method
        // If nil then it's expected the client cllas _updateMotionData
        if (_controlThread != nil) {
            SEL sel = @selector(_updateMotionData);
            NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:sel];
            NSInvocation *invoc = [NSInvocation invocationWithMethodSignature:sig];
            [invoc setSelector:sel];
            [invoc setTarget:self];
            [_controlThread addInvocation:invoc desiredInterval:(_pollingInterval / (NSTimeInterval)oversampRatio)];
        }
    }
    return self;
}

/**********************************************************************/

/// Defaul to 60Hz, no oversampling, CorrectedZVertical ref frame and no callback (client does it)
- (id)init
{
    return [self initWithPollingInterval:0.01667 oversamplingRatio:1u attitudeReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical controlThread:nil];
}

/** ********************************************************************/

- (void)dealloc 
{
    [_motionManager stopDeviceMotionUpdates];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors
/////////////////////////////////////////////////////////////////////////

- (IMMotionSampleSet)current
{
    @synchronized(self) { return _latest; }
}

- (IMMotionSampleSet)previous
{
    @synchronized(self) { return _previous; }
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////

- (void)engage
{
    NSAssert(!_isEngaged, @"Motion Analzer is already engaged!");
    
    // Init the motion manager and polling timer
    if (![_motionManager isDeviceMotionActive]) {

        if (_accelerometerEnabled)
            [_motionManager startAccelerometerUpdates];
        
        if (_gyroscopeEnabled)
            [_motionManager startGyroUpdates];
        
        if (_attitudeEnabled) {
            // Check for new iOS 5 magneto-enhanced yaw support
            if ([CMMotionManager availableAttitudeReferenceFrames] & _referenceFrame) {
                [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:_referenceFrame];
            } else {
                [_motionManager startDeviceMotionUpdates];
            }
        }
    }
    _currentFrame = -1;  // We'll inc this at the beginning of the loop
    
    _isEngaged = YES;
}

//---------------------------------------------------------------------

- (void)disengage
{
    NSAssert(_isEngaged, @"Motion Analzer is disengaged!");
    
    @synchronized(self) {
        _isEngaged = NO;
        
        // No harm calling when not started so skip the conditionals
        [_motionManager stopDeviceMotionUpdates];
        [_motionManager stopAccelerometerUpdates];
        [_motionManager stopGyroUpdates];
        
        // Reset the observers;
        [self reset];
        
        IM_ClearMotionDataSet(&_latest);
        IM_ClearMotionDataSet(&_previous);
    }
}

//---------------------------------------------------------------------

- (void)resetAndCalibrateCenter
{
    if (!_isEngaged) return;
    
    [self disengage];
    [self engage];
}

/////////////////////////////////////////////////////////////////////////

- (void)reset
{
    // Reset all detectors and observers
    for (id<IMMotionObserverProtocol>observer in _extMotionObservers) {
        if ([observer respondsToSelector:@selector(reset)]) {
            [observer reset];
        }
    }
    for (id<IMMotionObserverProtocol>observer in _intMotionObservers) {
        if ([observer respondsToSelector:@selector(reset)]) {
            [observer reset];
        }
    }
    
    // Reset our vars too
    IM_ClearMotionDataSet(&_latest);
    IM_ClearMotionDataSet(&_previous);
}

/////////////////////////////////////////////////////////////////////////

- (void)addMotionObserver:(id<IMMotionObserverProtocol>)observer
{
    @synchronized(self) {
        if ([_extMotionObservers containsObject:observer]) {
            return;
        }
        [_extMotionObservers addObject:observer];
    }
    /// Report the sample rate if received
    if ([observer respondsToSelector:@selector(handleMotionObserverAddedWithSampleRate:)]) {
        [observer handleMotionObserverAddedWithSampleRate:(1.0 / _pollingInterval * (NSTimeInterval)_oversamplingRatio)];
    }
}

- (void)removeMotionObserver:(id<IMMotionObserverProtocol>)observer
{
    @synchronized(self) {
        // Check it actually is contained
        if (![_extMotionObservers containsObject:observer]) {
            return;
        }
        [_extMotionObservers removeObject:observer];
    }
    if ([observer respondsToSelector:@selector(handleMotionObserverRemoved)]) {
        [observer handleMotionObserverRemoved];
    }
}

/** ********************************************************************/

- (void)addMotionObserverOnInternalThread:(id<IMMotionObserverProtocol>)observer
{
    @synchronized(self) {
        if ([_intMotionObservers containsObject:observer]) {
            return;
        }
        [_intMotionObservers addObject:observer];
    }
    
    /// Report the sample rate if received
    if ([observer respondsToSelector:@selector(handleMotionObserverAddedWithSampleRate:)]) {
        [observer handleMotionObserverAddedWithSampleRate:(1.0 / _pollingInterval * (NSTimeInterval)_oversamplingRatio)];
    }
}

- (void)removeMotionObserverOnInternalThread:(id<IMMotionObserverProtocol>)observer
{
    @synchronized(self) {
        [_intMotionObservers removeObject:observer];
    }
    if ([observer respondsToSelector:@selector(handleMotionObserverRemoved)]) {
        [observer handleMotionObserverRemoved];
    }
}

/** ********************************************************************/

- (void)addDetector:(id<IMMotionDetectorProtocol>)detector
{
    // Simply an internal motion observer at the mo'
    [self addMotionObserverOnInternalThread:detector];
    
}

- (void)removeDetector:(id<IMMotionDetectorProtocol>)detector
{
    [self removeMotionObserverOnInternalThread:detector];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////

- (void)_updateMotionData
{
    if (!_isEngaged) {
        IMLogWarn("_updateMotionData called while disengaged.  Aborting...");
        return;
    }
    
    
    
    @synchronized(self) {
        /////////////////////////////////////////
        // PRELIMINARY
        /////////////////////////////////////////
        ++_currentFrame;
        
        CMDeviceMotion *deviceMotion = [_motionManager deviceMotion];
        NSTimeInterval deltaT = 0;
        NSTimeInterval now;
        
        // Used to determine whether this round is an extrapolation round as per
        // the oversampling or whether we try to get it direct from CoreMotion
        BOOL isOversampleRound = (_currentFrame % _oversamplingRatio != 0);

        // Get the timestamp and delta time first as we'll need it
        // If this is a first run (ie no "previous" data) then set deltaT to undefined and don't do oversampling interpolation
        now = CACurrentMediaTime();
        _previous.timestamp = _latest.timestamp;
        
        if (IM_IsEmptyMotionDataSet(&_previous)) {
            deltaT = kIMMotionUnitUndefined;
        } else {
            deltaT = now - _previous.timestamp;
        }
        
        
        /////////////////////////////////////////
        // ACCELEROMETER
        // - DNF:  accel(eration) is what the sensor measures
        /////////////////////////////////////////
        
        _latest.hasAccelerometer = _accelerometerEnabled;
        
        if (_accelerometerEnabled) {

            // Grab a copy of the (previous) previous and shift the old latest (now the previous) into it
            // We'll need the previous-previous for extrapolation if we do it
            //IMMotionSample prev = _previous.accelerometer;
            _previous.accelerometer = _latest.accelerometer;
            
            // For convenience
            IMMotionSample *late = &_latest.accelerometer;
            IMMotionSample *pre = &_previous.accelerometer;
            
            /////////////////////////////////////////
            // DEVICE READING
            /////////////////////////////////////////
            
           // BOOL isDup;
            CMAcceleration accel;
            
            // If not an oversample round, grab a reading from the device
            if (!isOversampleRound) {
                accel = deviceMotion.userAcceleration;
                
                // These are acceleration values
                late->accel.x = accel.x;
                late->accel.y = accel.y;
                late->accel.z = accel.z;
                late->timestamp = now;    // Copy timestamp
                
                // Check for a duplicate round
                /*isDup =
                fabs(_latest.acceleromater.accel.x - _latestFromDevice.accelerometer.accel.x) < IM_DUPLICATE_THRESHOLD &&
                fabs(_latest.acceleromater.accel.y - _latestFromDevice.accelerometer.accel.y) < IM_DUPLICATE_THRESHOLD &&
                fabs(_latest.acceleromater.accel.z - _latestFromDevice.accelerometer.accel.z) < IM_DUPLICATE_THRESHOLD;*/            }
            
            // If oversample or duplicate, extrapolate from the last two values
            if (isOversampleRound /* || isDup*/) {
                NSAssert(NO, @"NO!");
              // late->accel = [self _extrapolate];
            } else {
//#warning Record real device read value for future extraps
                _latestFromDevice.accelerometer = _latest.accelerometer;
                // dont care about derived motion params.  only device read ones ??
            }
            
            
            /////////////////////////////////////////
            // CALCULATE DERIVED MOTION PARAMS
            // - none for now
            /////////////////////////////////////////
            
            // Can only do if we have 2 sets of data.  deltaT is needed for derivates and integration
            if (deltaT != kIMMotionUnitUndefined) {
                
                /////////////////////////////////////////
                // NOT RELIABLE ENOUGH YET...
                /////////////////////////////////////////

                
                // Average or should be just do trailing edge?
                // Don't worry about 0 values in the first couple rounds as they only result in 0's :)
                // Velocity
                /*IMMotionUnit currFiltAccel;
                
                currFiltAccel = late->accel.x - _previous.accelerometer.accel.x + _filtR * _lastfiltAccel.x;
                late->vel.x = 0.5 * (currFiltAccel + _lastfiltAccel.x) * deltaT + _previous.accelerometer.vel.x;
                late->pos.x = 0.5 * (late->vel.x + _previous.accelerometer.vel.x) * deltaT + _previous.accelerometer.pos.x;
                
                currFiltAccel = late->accel.y - _previous.accelerometer.accel.y + _filtR * _lastfiltAccel.y;
                late->vel.y = 0.5 * (late->accel.y + _previous.accelerometer.accel.y) * deltaT + _previous.accelerometer.vel.y;
                late->pos.y = 0.5 * (late->vel.y + _previous.accelerometer.vel.y) * deltaT + _previous.accelerometer.pos.y;

                currFiltAccel = late->accel.z - _previous.accelerometer.accel.z + _filtR * _lastfiltAccel.z;
                late->pos.z = 0.5 * (late->vel.z + _previous.accelerometer.vel.z) * deltaT + _previous.accelerometer.pos.z;
                late->vel.z = 0.5 * (late->accel.z + _previous.accelerometer.accel.z) * deltaT + _previous.accelerometer.vel.z;*/
            }

            
            /////////////////////////////////////////
            // SIGN CHANGES
            /////////////////////////////////////////
            
            if (_currentFrame >= 1) {   // More efficient

                late->accelSC.x = IM_GetSignChange(pre->accel.x, late->accel.x);
                late->accelSC.y = IM_GetSignChange(pre->accel.y, late->accel.y);
                late->accelSC.z = IM_GetSignChange(pre->accel.z, late->accel.z);
                
                /* no point unless above is enabled
                late->velSC.x = IM_GetSignChange(pre->vel.x, late->vel.x);
                late->velSC.y = IM_GetSignChange(pre->vel.y, late->vel.y);
                late->velSC.z = IM_GetSignChange(pre->vel.z, late->vel.z);
                
                late->posSC.x = IM_GetSignChange(pre->pos.x, late->pos.x);
                late->posSC.y = IM_GetSignChange(pre->pos.y, late->pos.y);
                late->posSC.z = IM_GetSignChange(pre->pos.z, late->pos.z);*/
                
            }

        } // END: Accelerometer
        
        
        /////////////////////////////////////////
        // GYROSCOPE
        // - DNF:  Sensor measures rotational *velocity* here
        /////////////////////////////////////////
        
        _latest.hasGyroscope = _gyroscopeEnabled;
        
        if (_gyroscopeEnabled) {
            
            // Grab a copy of the (previous) previous and shift the old latest (now the previous) into it
            // We'll need the previous-previous for extrapolation if we do it
            //IMMotionSample prev = _previous.accelerometer;
            _previous.gyroscope = _latest.gyroscope;
            
            // For convenience
            IMMotionSample *late = &_latest.gyroscope;
            IMMotionSample *pre = &_previous.gyroscope;
            
            
            /////////////////////////////////////////
            // DEVICE READING
            /////////////////////////////////////////
            
            //BOOL isDup;
            CMRotationRate gyro;
            
            // If not an oversample round, grab a reading from the device
            if (!isOversampleRound) {
                gyro = deviceMotion.rotationRate;
                
                // These are velocity values
                late->vel.x = gyro.x;
                late->vel.y = gyro.y;
                late->vel.z = gyro.z;
                late->timestamp = now;    // Copy timestamp
                
                
                // Check for a duplicate round
                /*isDup =
                 fabs(_latest.acceleromater.accel.x - _latestFromDevice.accelerometer.accel.x) < IM_DUPLICATE_THRESHOLD &&
                 fabs(_latest.acceleromater.accel.y - _latestFromDevice.accelerometer.accel.y) < IM_DUPLICATE_THRESHOLD &&
                 fabs(_latest.acceleromater.accel.z - _latestFromDevice.accelerometer.accel.z) < IM_DUPLICATE_THRESHOLD;*/
            }
            
            // If oversample or duplicate, extrapolate from the last two values
            if (isOversampleRound /* || isDup*/) {
              //  late->vel = [self _extrapolate];
            } else {
// #warning Record real device read value for future extraps
                _latestFromDevice.gyroscope = _latest.gyroscope;
                // dont care about derived motion params.  only device read ones ??
            }
            
            
            /////////////////////////////////////////
            // CALCULATE DERIVED MOTION PARAMS
            /////////////////////////////////////////
            
            // Can only do if we have 2 sets of data.  deltaT is needed for derivates and integration
            if (deltaT != kIMMotionUnitUndefined) {
                
                // Average or should be just do trailing edge?
                // Don't worry about 0 values in the first couple rounds as they only result in 0's :)
                // Velocity
                /*late->pos.x = 0.5 * (late->vel.x + _previous.gyroscope.vel.x) * deltaT + _previous.gyroscope.pos.x;
                late->pos.y = 0.5 * (late->vel.y + _previous.gyroscope.vel.y) * deltaT + _previous.gyroscope.pos.y;
                late->pos.z = 0.5 * (late->vel.z + _previous.gyroscope.vel.z) * deltaT + _previous.gyroscope.pos.z;*/
                
                late->accel.x = (late->vel.x - _previous.gyroscope.vel.x) / deltaT;
                late->accel.y = (late->vel.y - _previous.gyroscope.vel.y) / deltaT;
                late->accel.z = (late->vel.z - _previous.gyroscope.vel.z) / deltaT;
            }
            
            
            /////////////////////////////////////////
            // SIGN CHANGES
            /////////////////////////////////////////
            
            if (_currentFrame >= 1) {   // More efficient
                
                late->accelSC.x = IM_GetSignChange(pre->accel.x, late->accel.x);
                late->accelSC.y = IM_GetSignChange(pre->accel.y, late->accel.y);
                late->accelSC.z = IM_GetSignChange(pre->accel.z, late->accel.z);
                
                late->velSC.x = IM_GetSignChange(pre->vel.x, late->vel.x);
                late->velSC.y = IM_GetSignChange(pre->vel.y, late->vel.y);
                late->velSC.z = IM_GetSignChange(pre->vel.z, late->vel.z);
                
                /* Not supported
                late->posSC.x = IM_GetSignChange(pre->pos.x, late->pos.x);
                late->posSC.y = IM_GetSignChange(pre->pos.y, late->pos.y);
                late->posSC.z = IM_GetSignChange(pre->pos.z, late->pos.z);
                */
                
                // Record sign change deltas.  Note, we want to report the max value
                // at the latest sign change and have it reset on the subsequent run.  Hence this order is important
                late->velDeltaSinceSC.x = late->vel.x - _gyroVelAtLastSC.x;
                late->velDeltaSinceSC.y = late->vel.y - _gyroVelAtLastSC.y;
                late->velDeltaSinceSC.z = late->vel.z - _gyroVelAtLastSC.z;

                // Now, if its a new sign change then reset our tracker
                if (late->accelSC.x != kIMSignNone) { _gyroVelAtLastSC.x = late->vel.x; }
                if (late->accelSC.y != kIMSignNone) { _gyroVelAtLastSC.y = late->vel.y; }
                if (late->accelSC.z != kIMSignNone) { _gyroVelAtLastSC.z = late->vel.z; }
            }
        } // END: Gyroscope
        
        
        
        /////////////////////////////////////////
        // ATTITUDE
        // - DNF:  Sensor measures rotational *position*!
        /////////////////////////////////////////
        
        _latest.hasAttitude = _attitudeEnabled;
        
        if (_attitudeEnabled) {
            
            // Grab a copy of the (previous) previous and shift the old latest (now the previous) into it
            // We'll need the previous-previous for extrapolation if we do it
            //IMMotionSample prev = _previous.accelerometer;
            _previous.attitude = _latest.attitude;
            
            // For convenience
            IMMotionSample *late = &_latest.attitude;
            IMMotionSample *pre = &_previous.attitude;
            
            
            /////////////////////////////////////////
            // DEVICE READING
            /////////////////////////////////////////
            
            //BOOL isDup;
            CMAttitude *att;
            
            // If not an oversample round, grab a reading from the device
            if (!isOversampleRound) {
                att = deviceMotion.attitude;
                
                // These are position values
                late->pos.pitch = att.pitch * (_reversePitchOrientation ? -1 : 1);
                late->pos.roll = att.roll * (_reverseRollOrientation ? -1 : 1);
                late->pos.yaw = att.yaw * (!_reverseYawOrientation ? -1 : 1);   // yaw for Apple is positive anti-clockwise.  That's unnatural for us so let's swap it
                late->timestamp = now;    // Copy timestamp
                // + 2*M_PI * _rotationMultiplier;// * alpha + (1-alpha)*self.latestMotionData.yaw;
                
                
                // Check for a duplicate round
                /*isDup =
                 fabs(_latest.acceleromater.accel.pitch - _latestFromDevice.accelerometer.accel.pitch) < IM_DUPLICATE_THRESHOLD &&
                 fabs(_latest.acceleromater.accel.roll - _latestFromDevice.accelerometer.accel.roll) < IM_DUPLICATE_THRESHOLD &&
                 fabs(_latest.acceleromater.accel.yaw - _latestFromDevice.accelerometer.accel.yaw) < IM_DUPLICATE_THRESHOLD;*/
            }
            
            // If oversample or duplicate, extrapolate from the last two values
            if (isOversampleRound /* || isDup*/) {
                //late->vel = [self _extrapolate];
            } else {
#warning Record real device read value for future extraps
                _latestFromDevice.attitude = _latest.attitude;
                // dont care about derived motion params.  only device read ones ??
            }
            
            
            /////////////////////////////////////////
            // CALCULATE DERIVED MOTION PARAMS
            /////////////////////////////////////////
            
            // Can only do if we have 2 sets of data.  deltaT is needed for derivates and integration
            if (deltaT != kIMMotionUnitUndefined) {

                late->vel.pitch = (late->pos.pitch - _previous.attitude.pos.pitch) / deltaT;
                late->vel.roll = (late->pos.roll - _previous.attitude.pos.roll) / deltaT;
                late->vel.yaw = (late->pos.yaw - _previous.attitude.pos.yaw) / deltaT;

                late->accel.pitch = (late->vel.pitch - _previous.attitude.vel.pitch) / deltaT;
                late->accel.roll = (late->vel.roll - _previous.attitude.vel.roll) / deltaT;
                late->accel.yaw = (late->vel.yaw - _previous.attitude.vel.yaw) / deltaT;
            }
            
            
            /////////////////////////////////////////
            // SIGN CHANGES
            /////////////////////////////////////////
            
            if (_currentFrame >= 1) {   // More efficient
                
                late->accelSC.pitch = IM_GetSignChange(pre->accel.pitch, late->accel.pitch);
                late->accelSC.roll = IM_GetSignChange(pre->accel.roll, late->accel.roll);
                late->accelSC.yaw = IM_GetSignChange(pre->accel.yaw, late->accel.yaw);

                late->velSC.pitch = IM_GetSignChange(pre->vel.pitch, late->vel.pitch);
                late->velSC.roll = IM_GetSignChange(pre->vel.roll, late->vel.roll);
                late->velSC.yaw = IM_GetSignChange(pre->vel.yaw, late->vel.yaw);

                late->posSC.pitch = IM_GetSignChange(pre->pos.pitch, late->pos.pitch);
                late->posSC.roll = IM_GetSignChange(pre->pos.roll, late->pos.roll);
                late->posSC.yaw = IM_GetSignChange(pre->pos.yaw, late->pos.yaw);
                
                
                // Record sign change deltas.  Note, we want to report the max value
                // at the latest sign change and have it reset on the subsequent run.  Hence this order is important
                late->posDeltaSinceSC.x = late->pos.x - _attitidePosAtLastSC.x;
                late->posDeltaSinceSC.y = late->pos.y - _attitidePosAtLastSC.y;
                late->posDeltaSinceSC.z = late->pos.z - _attitidePosAtLastSC.z;
                
                late->velDeltaSinceSC.x = late->vel.x - _attitideVelAtLastSC.x;
                late->velDeltaSinceSC.y = late->vel.y - _attitideVelAtLastSC.y;
                late->velDeltaSinceSC.z = late->vel.z - _attitideVelAtLastSC.z;
                
                // Now, if its a new sign change then reset our tracker
                if (late->velSC.x != kIMSignNone) { _attitidePosAtLastSC.x = late->pos.x; }
                if (late->velSC.y != kIMSignNone) { _attitidePosAtLastSC.y = late->pos.y; }
                if (late->velSC.z != kIMSignNone) { _attitidePosAtLastSC.z = late->pos.z; }

                if (late->accelSC.x != kIMSignNone) { _attitideVelAtLastSC.x = late->vel.x; }
                if (late->accelSC.y != kIMSignNone) { _attitideVelAtLastSC.y = late->vel.y; }
                if (late->accelSC.z != kIMSignNone) { _attitideVelAtLastSC.z = late->vel.z; }
            }
            
        } // END: Attitude
        
        
        // Detect wrap around.  Safe to do here as it will detect false for dups
        /*  if (_allowExtendedYaw) {
         
         // IMPORTANT TO CHECK SIGN,  OTHERWISE SLOW DEVICE RESPONSE COULD YIELD FALSE POSITIVE!
         // If sign changed ( = 2 possible point crossings)
         //if ( (previous->yaw > 0 && latest->yaw < 0) ||
         //     (previous->yaw < 0 && latest->yaw > 0) ) {
         
         // If velocity is above our detection thresh range of our
         IMMotionUnit vel = (latest->yaw - previous->yaw) / latest->deltaT;
         if (fabs(vel) >= IM_WRAP_AROUND_DETECTION_VELOCITY_THRESHOLD) {
         // Positive -> negative border crossing is actually a POSITIVE motion
         if (vel < 0) {
         _rotationMultiplier++;
         latest->yaw += 2*M_PI;
         } else {
         _rotationMultiplier--;
         latest->yaw -= 2*M_PI;
         }
         IMLOG(@"Rotation Multiplier: %i", _rotationMultiplier);
         //            latest->yaw += 2*M_PI;
         }
         //}
         }*/
        //DLOG(@"%.4f -> %.4f", previous->yaw, latest->yaw)
        //    DLOGf(IM_RAD2DEG(latest->yaw));
        
        _latest.timestamp = now;
        
        if (_currentFrame >= IM_FRAMES_TO_DELAY_BEFORE_REPORTING) {
            [self _notifyObservers];
        }
        
    } // end @synchronised(self)
}



/////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////

/// Update all the observers as per their requested thread and frame interval params
- (void)_notifyObservers
{
    // First send out the ones which run on external threads, async'ly
    for (id<IMMotionObserverProtocol>observer in _extMotionObservers) {
        
        // Make copies as the values/pointers are inclined to change before 
        // the dispatch processes on its thread
        id<IMMotionObserverProtocol> o = observer;
        dispatch_async(dispatch_get_main_queue(), ^{ [o handleMotionUpdateForData:_latest previousData:_previous]; });
    }
    
    // Then do the synchronous internals ones
    for (id<IMMotionObserverProtocol>observer in _intMotionObservers) {
        [observer handleMotionUpdateForData:_latest previousData:_previous];
    }
}


/** Use velocity and accel to extrapolate the new value for the given time delta 
- (void)_extrapolatePitchInto:(IMAxisMotionDataSet *)dataRef forTimeDelta:(NSTimeInterval)deltaTime
{
    dataRef.pitchAccel = previous->pitchAccel;
    dataRef.pitchVelocity = previous->pitchAccel * deltaTime + previous->pitchVelocity;
    dataRef.pitch = previous->pitchAccel * deltaTime * deltaTime / 2.0 + previous->pitchVelocity * deltaTime + previous->pitch;
}



- (void)_extrapolateRollInto:(IMAxisMotionDataSet *)dataRef forTimeDelta:(NSTimeInterval)deltaTime
{
    dataRef.rollAccel = previous->rollAccel;
    dataRef.rollVelocity = previous->rollAccel * deltaTime + previous->rollVelocity;
    dataRef.roll = previous->rollAccel * deltaTime * deltaTime / 2.0 + previous->rollVelocity * deltaTime + previous->roll;
}


- (void)_extrapolateYawInto:(IMAxisMotionDataSet *)dataRef forTimeDelta:(NSTimeInterval)deltaTime
{
    dataRef.yawAccel = previous->yawAccel;
    dataRef.yawVelocity = previous->yawAccel * deltaTime + previous->yawVelocity;
    dataRef.yaw = previous->yawAccel * deltaTime * deltaTime / 2.0 + previous->yawVelocity * deltaTime + previous->yaw;
}
*/

@end
