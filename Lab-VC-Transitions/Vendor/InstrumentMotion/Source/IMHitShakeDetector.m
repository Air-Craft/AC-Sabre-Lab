/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 31/10/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{ 
 */

#import "IMHitShakeDetector.h"
#import <tgmath.h>
#import <QuartzCore/QuartzCore.h>

#import "IMConfig.h"
#import "IMFunctions.h"
#import "InstrumentMotionDebug.h"




/////////////////////////////////////////////////////////////////////////
#pragma mark - IMHitShareDector
/////////////////////////////////////////////////////////////////////////

@implementation IMHitShakeDetector
{
    NSMutableDictionary *_posAtLastAccelSC;
    NSMutableDictionary *_timeAtLastShake;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - <#Header#>
/////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
/////////////////////////////////////////////////////////////////////////

- (id)init
{
    self = [super init];
    if (self) {
        _activeHitAxes = kIMHitShakeAxisDescriptorAnyGyro;
        _activeShakeAxes = kIMHitShakeAxisDescriptorAnyGyro;
        self.threshold = 0.1;
        self.sensitivity = 1;
        _posAtLastAccelSC = [@{
                             @(kIMAxisPitch): @0.0,
                             @(kIMAxisRoll): @0.0,
                             @(kIMAxisYaw): @0.0
                             } mutableCopy];
        _timeAtLastShake = [@{
                            @(kIMAxisPitch): @(-1.0),
                             @(kIMAxisRoll): @(-1.0),
                             @(kIMAxisYaw): @(-1.0)
                             } mutableCopy];
        
        __deltaTimeThresh = IM_HITSHAKE_DELTA_TIME_THRESHOLD;
        __deltaPosThreshForMinIntensity = IM_HITSHAKE_DELTA_ANGLE_THRESHOLD_FOR_MIN_INTENSITY_HIT;
        __deltaPosThreshForMaxIntensity = IM_HITSHAKE_DELTA_ANGLE_THRESHOLD_FOR_MAX_INTENSITY_HIT;
        __deltaVelThreshForMinIntensity = IM_HITSHAKE_DELTA_VEL_THRESHOLD_FOR_MIN_INTENSITY_HIT;
        __deltaVelThreshForMaxIntensity = IM_HITSHAKE_DELTA_VEL_THRESHOLD_FOR_MAX_INTENSITY_HIT;
    }
    return self;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Accessors
/////////////////////////////////////////////////////////////////////////

@synthesize threshold=_threshold, sensitivity=_sensitivity;

- (IMMotionUnit)threshold { @synchronized(self) { return _threshold; } };
- (IMMotionUnit)sensitivity { @synchronized(self) { return _sensitivity; } };

- (void)setThreshold:(IMMotionUnit)aThreshold { @synchronized(self) { _threshold = aThreshold; } }

- (void)setSensitivity:(IMMotionUnit)aSensitivity { @synchronized(self) { _sensitivity = aSensitivity; } }


/////////////////////////////////////////////////////////////////////////
#pragma mark - IMMotionDetector Fulfillment
/////////////////////////////////////////////////////////////////////////

/**
 If velocity goes from neg->pos or pos->neg && delta(abs([v])) > thresh, then trigger
 */
- (void)handleMotionUpdateForData:(IMMotionSampleSet)current previousData:(IMMotionSampleSet)previous
{
    @synchronized(self) {       // prevent collisions with setting threshold & sensitivity
        
        [self _doHitDetectionForAttitudeAxis:kIMAxisPitch
                      currentMotionSampleSet:&current
                     previousMotionSampleSet:&previous];
        [self _doHitDetectionForAttitudeAxis:kIMAxisRoll
                      currentMotionSampleSet:&current
                     previousMotionSampleSet:&previous];
        [self _doHitDetectionForAttitudeAxis:kIMAxisYaw
                      currentMotionSampleSet:&current
                     previousMotionSampleSet:&previous];
        
        
        [self _doShakeDetectionForAttitudeAxis:kIMAxisPitch
                         currentMotionSampleSet:&current
                        previousMotionSampleSet:&previous];
        [self _doShakeDetectionForAttitudeAxis:kIMAxisRoll
                         currentMotionSampleSet:&current
                        previousMotionSampleSet:&previous];
        [self _doShakeDetectionForAttitudeAxis:kIMAxisYaw
                         currentMotionSampleSet:&current
                        previousMotionSampleSet:&previous];
    }
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////

/**
 Abstracts the axis from the detection algorithm
 
 ALGORITHM: Velocity sign change + Attitude Hemisphere Sync. See class notes
 */
- (void)_doHitDetectionForAttitudeAxis:(IMAxis)anAxisName
                 currentMotionSampleSet:(IMMotionSampleSet *)current
                previousMotionSampleSet:(IMMotionSampleSet *)previous
{
    if (!current->hasAttitude || !current->hasAttitude ) {
        [NSException raise:NSInternalInconsistencyException format:@"Attitude must be enabled."];
    }
    
    // Are we looking at this axis?
    IMHitShakeAxisDescriptor positiveAxisDescr = IM_GetPositiveHitShakeAxisDescriptorAxis(anAxisName);
    IMHitShakeAxisDescriptor negativeAxisDescr = IM_GetNegativeHitShakeAxisDescriptorAxis(anAxisName);
    
    if (!(_activeHitAxes & positiveAxisDescr) &&
        !(_activeHitAxes & negativeAxisDescr))
        return;
    

    // Get values for the given axis and the correlated attitude axis
    IMMotionCoord axisMotion;
    IMMotionCoord signChange;
    IMMotionCoord signChangeDelta;

    // Get the values for a single axis for brevity
    IM_GetMotionCoordDataFromSampleForAxis(&current->attitude,
                                           anAxisName,
                                           &axisMotion,
                                           &signChange,
                                           &signChangeDelta);
    
    
    /////////////////////////////////////////
    // CONDITION: "Hit" := Velocity Sign Change
    /////////////////////////////////////////

    // No direction change = no hit
    if (signChange.vel == kIMSignNone) return;
    

    
    /////////////////////////////////////////
    // CONDITION: Intensity >= threshold
    /////////////////////////////////////////
    // Scale intensity wrt to max, check against the threshold and scale according to sensitivity. no need to synchro as long as calling source has done so
    IMMotionUnit intensity = fabs(axisMotion.accel / IM_GetMaxAccelerationForAxis(anAxisName));
    
    if (intensity < _threshold) return;
    
    
    /////////////////////////////////////////
    // NORMALISE INTENSITY
    /////////////////////////////////////////

    // Normalise the intensity wrt to threshold and sensitivity thiIMCons time
    if (intensity > _sensitivity) {
        intensity = 1;
    } else {
        // Linear map from thresh...sensitivity to 0..1
        intensity = IM_MapLinearRange(intensity, _threshold, _sensitivity, 0, 1);
    }
    
    
    /////////////////////////////////////////
    // CONDITION: Transversed Distance Weighted Threshold
    /////////////////////////////////////////
    
    // Get the minimum transversed distance for the intensity
    IMMotionUnit deltaPosThreshold = IM_MapLinearRange(intensity, 0, 1, IM_HITSHAKE_DELTA_ANGLE_THRESHOLD_FOR_MIN_INTENSITY_HIT, IM_HITSHAKE_DELTA_ANGLE_THRESHOLD_FOR_MAX_INTENSITY_HIT);
    
    if (fabs(signChangeDelta.pos) < deltaPosThreshold)
        return;
    
    
    
    /////////////////////////////////////////
    // REPORT TO DELEGATE
    /////////////////////////////////////////

    // Positive edge means a now negative velocity (or will be in the next instant)
    BOOL isPositiveEdgeHit = axisMotion.vel < 0 || (axisMotion.vel == 0 && axisMotion.accel < 0);

    if (isPositiveEdgeHit && (_activeHitAxes & positiveAxisDescr)) {
        
        [_delegate hitDidOccurWithAxisDescriptor:positiveAxisDescr intensity:intensity];
    }
    
    // Else it should be a negative edge
    else if (_activeHitAxes & negativeAxisDescr) {
        
        [_delegate hitDidOccurWithAxisDescriptor:negativeAxisDescr intensity:intensity];
        
    } else {
        NSAssert(NO, @"Shouldn't be!");
    }
}

/////////////////////////////////////////////////////////////////////////

- (void)_doShakeDetectionForAttitudeAxis:(IMAxis)anAxisName
                  currentMotionSampleSet:(IMMotionSampleSet *)current
                 previousMotionSampleSet:(IMMotionSampleSet *)previous
{
    if (!current->hasAttitude || !current->hasAttitude ) {
        [NSException raise:NSInternalInconsistencyException format:@"Attitude must be enabled."];
    }
    
    // Are we looking at this axis?
    IMHitShakeAxisDescriptor positiveAxisDescr = IM_GetPositiveHitShakeAxisDescriptorAxis(anAxisName);
    IMHitShakeAxisDescriptor negativeAxisDescr = IM_GetNegativeHitShakeAxisDescriptorAxis(anAxisName);
    
    if (!(_activeShakeAxes & positiveAxisDescr) &&
        !(_activeShakeAxes & negativeAxisDescr))
        return;
    
    
    // Get values for the given axis and the correlated attitude axis
    IMMotionCoord axisMotion;
    IMMotionCoord signChange;
    IMMotionCoord signChangeDelta;
    
    // Get the values for a single axis for brevity
    IM_GetMotionCoordDataFromSampleForAxis(&current->attitude,
                                           anAxisName,
                                           &axisMotion,
                                           &signChange,
                                           &signChangeDelta);
    
    /////////////////////////////////////////
    // CONDITION: "Shake" := Accel Sign Change
    /////////////////////////////////////////
    
    // No direction change = no hit
    if (signChange.accel == kIMSignNone) return;
    
    // record position
    IMMotionUnit posAtLastAccelSC = [_posAtLastAccelSC[@(anAxisName)] floatValue];    
    _posAtLastAccelSC[@(anAxisName)] = @(axisMotion.pos);
    
    // Positive edge means a now negative velocity (or will be in the next instant)
    BOOL isPositiveEdgeHit = axisMotion.vel > 0;

    
    // Sign change must be in the opposite direciton of the motion
    IMMotionUnit reqAccelSignChange = isPositiveEdgeHit ? kIMSignNegative : kIMSignPositive;
    
    if (signChange.accel != reqAccelSignChange) return;
    
    
    /////////////////////////////////////////
    // CONDITION: Intensity >= threshold
    /////////////////////////////////////////
    // Scale intensity wrt to max, check against the threshold and scale according to sensitivity. no need to synchro as long as calling source has done so
    IMMotionUnit intensity = fabs(axisMotion.vel / IM_GetMaxVelocityForAxis(anAxisName));
    
    if (intensity < _threshold) {
        if (InstrumentMotionDebugLogLevel & kIMDebugLogLevelRealTime) {
            if (intensity > 0.5 * _threshold) {
                IMLogRealTime("[Hit Fail] intensity < _threshold (%.3f < %.3f)", fabs(intensity), _threshold);
            }
        }
 // too much info!       IMLogRealTime("[Hit Fail] intensity < threshold (%.1f < %.1f) ", intensity, _threshold);
        return;
    }
    
    
    /////////////////////////////////////////
    // NORMALISE INTENSITY
    /////////////////////////////////////////
    
    // Normalise the intensity wrt to threshold and sensitivity thiIMCons time
    if (intensity > _sensitivity) {
        intensity = 1;
    } else {
        // Linear map from thresh...sensitivity to 0..1
        intensity = IM_MapLinearRange(intensity, _threshold, _sensitivity, 0, 1);
    }
    
    
    /////////////////////////////////////////
    // CONDITION: VELOCITY DELTA THRESHOLD
    /////////////////////////////////////////
    
    // Get the minimum transversed distance for the intensity
    IMMotionUnit deltaVelThreshold = IM_MapLinearRange(intensity, 0, 1, __deltaVelThreshForMinIntensity, __deltaPosThreshForMaxIntensity);
    
    if (fabs(signChangeDelta.vel) < deltaVelThreshold) {
        IMLogRealTime("[Hit Fail] deltaVel = %.3f < %.3f", fabs(signChangeDelta.vel), deltaVelThreshold);
        return;
    }

    
    /////////////////////////////////////////
    // CONDITION: POSITION DELTA THRESHOLD
    /////////////////////////////////////////
    
    IMMotionUnit deltaPosThreshold = IM_MapLinearRange(intensity, 0, 1, __deltaPosThreshForMinIntensity, __deltaPosThreshForMaxIntensity);
    
    IMMotionUnit deltaPos = axisMotion.pos - posAtLastAccelSC;
    
    if (fabs(deltaPos) < deltaPosThreshold) {
        IMLogRealTime("[Hit Fail] deltaPos = %.3f < %.3f ", fabs(deltaPos), deltaPosThreshold);
        return;
    }
    //if (fabs(signChangeDelta.pos) < deltaPosThreshold)
    //    return;
    
    
    /////////////////////////////////////////
    // CONDITION: TIME GATE
    /////////////////////////////////////////
    NSTimeInterval now = CACurrentMediaTime();
    NSTimeInterval timeAtLastDetection = [_timeAtLastShake[@(anAxisName)]doubleValue];
    NSTimeInterval deltaTime = now - timeAtLastDetection;
    if (deltaTime < __deltaTimeThresh) {
        IMLogRealTime("[Hit Fail] deltaTime = %.3f < %.3f ", deltaTime, __deltaTimeThresh)
        return;
    }
    
    _timeAtLastShake[@(anAxisName)] = @(now);
    
    
    /////////////////////////////////////////
    // REPORT TO DELEGATE
    /////////////////////////////////////////
    
    if (isPositiveEdgeHit && (_activeShakeAxes & positiveAxisDescr)) {
        //NSLog(@"Positive: v=%.1f aSC=%@", axisMotion.vel, (signChange.accel==kIMSignNegative?@"-":@"+"));
        
        [_delegate shakeDidOccurWithAxisDescriptor:positiveAxisDescr intensity:intensity];
    }
    
    // Else it should be a negative edge
    else if (_activeShakeAxes & negativeAxisDescr) {
        //NSLog(@"Negative: v=%.1f aSC=%@", axisMotion.vel, (signChange.accel==kIMSignNegative?@"-":@"+"));
        [_delegate shakeDidOccurWithAxisDescriptor:negativeAxisDescr intensity:intensity];
    }
}


/*
- (BOOL)_axisDescriptor:(IMHitShakeAxisDescriptor)aDescriptor includesAxis:(IMAxis)anAxis
{
    switch (anAxis) {
        case kIMMotionAxisX:        return aDescriptor & kIMHitShakeAxisDescriptorX;
        case kIMMotionAxisY:        return aDescriptor & kIMHitShakeAxisDescriptorY;
        case kIMMotionAxisZ:        return aDescriptor & kIMHitShakeAxisDescriptorZ;

        case kIMMotionAxisGyroX:    return aDescriptor & kIMHitShakeAxisDescriptorGyroX;
        case kIMMotionAxisGyroY:    return aDescriptor & kIMHitShakeAxisDescriptorGyroY;
        case kIMMotionAxisGyroZ:    return aDescriptor & kIMHitShakeAxisDescriptorGyroZ;

        case kIMMotionAxisPitch:    return aDescriptor & kIMHitShakeAxisDescriptorPitch;
        case kIMMotionAxisRoll:     return aDescriptor & kIMHitShakeAxisDescriptorRoll;
        case kIMMotionAxisYaw:      return aDescriptor & kIMHitShakeAxisDescriptorYaw;
            
        default:
            NSAssert(NO, @"Shouldn't be!");
    }
}
*/
/*
    
    if (_activeHitAxes & kIMHitAxisDescriptorGyroX) {
        intensity = _IMGetSignedHitIntensity(current.,
                                             previous.rotationalXVelocity,
                                             motionData.rotationalXAccel,
                                             _ROT_ACCEL_MAX);
        
        if (fabs(intensity) > thresh) {
            NSLog(@"XXXX: %f", intensity);
            if (intensity > 0 && (_activeHitAxes & kIMHitAxisDescriptorGyroXNegativeEdge)) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor: kIMHitAxisDescriptorGyroXNegativeEdge
                                         hitIntensity:intensity];
            }
            else if (_activeHitAxes & kIMHitAxisDescriptorGyroXPositiveEdge) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorGyroXPositiveEdge
                                         hitIntensity:intensity];
            }
        }
    }
    
    if (_activeHitAxes & kIMHitAxisDescriptorGyroY) {
        intensity = _IMGetSignedHitIntensity(motionData.rotationalYVelocity,
                                             _prevMotionData.rotationalYVelocity,
                                             motionData.rotationalYAccel,
                                             _ROT_ACCEL_MAX);

        if (fabs(intensity) > thresh) {
            NSLog(@"YYYY: %f", intensity);
            if (intensity > 0 && (_activeHitAxes & kIMHitAxisDescriptorGyroYNegativeEdge)) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorGyroYNegativeEdge
                                         hitIntensity:intensity];
                
            } else if (_activeHitAxes & kIMHitAxisDescriptorGyroYPositiveEdge) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorGyroYPositiveEdge
                                         hitIntensity:intensity];
            }
        }
    }
    
    if (_activeHitAxes & kIMHitAxisDescriptorGyroZ) {
        intensity = _IMGetSignedHitIntensity(motionData.rotationalZVelocity,
                                             _prevMotionData.rotationalZVelocity,
                                             motionData.rotationalZAccel,
                                             _ROT_ACCEL_MAX);
        

        if (fabs(intensity) > thresh) {
            NSLog(@"ZZZZ: %f", intensity);
            if (intensity > 0 && (_activeHitAxes & kIMHitAxisDescriptorGyroZNegativeEdge)) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorGyroZNegativeEdge
                                         hitIntensity:intensity];
                
            } else if (_activeHitAxes & kIMHitAxisDescriptorGyroZPositiveEdge) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorGyroZPositiveEdge
                                         hitIntensity:intensity];
            }
        }
    }
    
    /////////////////////////////////////////
    // TRANSLATION AXES
    /////////////////////////////////////////
    
    if (_activeHitAxes & kIMHitAxisDescriptorX) {
        intensity = _IMGetSignedHitIntensity(motionData.xVelocity,
                                             _prevMotionData.xVelocity,
                                             motionData.xAccel,
                                             _ACCEL_MAX);

        if (fabs(intensity) > thresh) {
            NSLog(@"xxxx: %f", intensity);
            if (intensity > 0 && (_activeHitAxes & kIMHitAxisDescriptorXNegativeEdge)) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorXNegativeEdge
                                         hitIntensity:intensity];
                
            } else if (_activeHitAxes & kIMHitAxisDescriptorXPositiveEdge) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorXPositiveEdge
                                         hitIntensity:intensity];
            }
        }
    }
    
    if (_activeHitAxes & kIMHitAxisDescriptorY) {
        intensity = _IMGetSignedHitIntensity(motionData.yVelocity,
                                             _prevMotionData.yVelocity,
                                             motionData.yAccel,
                                             _ACCEL_MAX);
        
        if (fabs(intensity) > thresh) {
            NSLog(@"yyyy: %f", intensity);
            if (intensity > 0 && (_activeHitAxes & kIMHitAxisDescriptorYNegativeEdge)) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorYNegativeEdge
                                         hitIntensity:intensity];
                
            } else if (_activeHitAxes & kIMHitAxisDescriptorYPositiveEdge) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorYPositiveEdge
                                         hitIntensity:intensity];
            }
        }
    }
    
    if (_activeHitAxes & kIMHitAxisDescriptorZ) {
        intensity = _IMGetSignedHitIntensity(motionData.zVelocity,
                                             _prevMotionData.zVelocity,
                                             motionData.zAccel,
                                             _ACCEL_MAX);
        
           // NSLog(@"zzzz: %f", intensity);
        if (fabs(intensity) > thresh) {
            NSLog(@"zzzz: %f", intensity);
            if (intensity > 0 && (_activeHitAxes & kIMHitAxisDescriptorZNegativeEdge)) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorZNegativeEdge
                                         hitIntensity:intensity];
                
            } else if (_activeHitAxes & kIMHitAxisDescriptorZPositiveEdge) {
                intensity = (fabs(intensity) - thresh) / (1.0-thresh);
                [self _doHitEventForHitAxisDescriptor:kIMHitAxisDescriptorZPositiveEdge
                                         hitIntensity:intensity];
            }
        }
    }
 */
/////////////////////////////////////////////////////////////////////////

- (void)reset
{
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////

@end

/// @}

