/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 12/11/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{ 
 */

#import "IMAttitudeZoneDetector.h"
#import <tgmath.h>

#import "IMFunctions.h"
#import "InstrumentMotionDebug.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Helper Functions
/////////////////////////////////////////////////////////////////////////

/** Returns the index in range -+floor(zoneCount/2) represented by the input angles \todo Optimise by having precomputed divisor and min index*/
inline static NSInteger _IM_APD_GetZoneIdx(IMMotionUnit inputAngle, IMMotionUnit minAngle, IMMotionUnit maxAngle, NSUInteger zoneCount)
{
    // Zero based 0
    NSInteger i = floor( (zoneCount * (inputAngle - minAngle)) / (maxAngle - minAngle) );
    
    // Convert to centered
    //i -= floor(zoneCount*0.5);
    
    return i;
}



/////////////////////////////////////////////////////////////////////////
#pragma mark - IMAttitudeProximityDetector
/////////////////////////////////////////////////////////////////////////

@implementation IMAttitudeZoneDetector
{
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Init
/////////////////////////////////////////////////////////////////////////

- (id)init
{
    if (self = [super init]) {
        // Init to full range
        _minPitch = -M_PI_2;
        _maxPitch = +M_PI_2;
        _minRoll = -M_PI;
        _maxRoll = +M_PI;
        _minYaw = +M_PI;
        _maxYaw = -M_PI;
        
        // Init to 1 zone for each.
        _pitchZones = _rollZones = _yawZones = 1;
        
        // Init zone idx's to 0
        _currentPitchZoneIdx = _currentRollZoneIdx = _currentYawZoneIdx = 0;
        
        _currentExitedPitchBoundary = _currentExitedRollBoundary = _currentExitedYawBoundary = kIMSignNone;
    }
    return self;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Property Accessors
// Define our own synchro'
/////////////////////////////////////////////////////////////////////////
@synthesize minPitch=_minPitch, maxPitch=_maxPitch, minRoll=_minRoll, maxRoll=_maxRoll, minYaw=_minYaw, maxYaw=_maxYaw;
@synthesize pitchZones=_pitchZones, rollZones=_rollZones, yawZones=_yawZones;
@synthesize currentExitedPitchBoundary=_currentExitedPitchBoundary, currentExitedYawBoundary=_currentExitedYawBoundary, currentExitedRollBoundary=_currentExitedRollBoundary;
@synthesize currentPitchZoneIdx=_currentPitchZoneIdx, currentRollZoneIdx=_currentRollZoneIdx, currentYawZoneIdx=_currentYawZoneIdx;

//===========================================================
//  minPitch
//===========================================================
- (IMMotionUnit)minPitch { @synchronized(self) {return _minPitch;} }
- (void)setMinPitch:(IMMotionUnit)aMinPitch
{
    @synchronized(self) {
        _minPitch = aMinPitch;
    }
}

//===========================================================
//  maxPitch
//===========================================================
- (IMMotionUnit)maxPitch { @synchronized(self) {return _maxPitch;} }
- (void)setMaxPitch:(IMMotionUnit)aMaxPitch
{
    @synchronized(self) {
        _maxPitch = aMaxPitch;
    }
}

//===========================================================
//  minRoll
//===========================================================
- (IMMotionUnit)minRoll { @synchronized(self) {return _minRoll;} }
- (void)setMinRoll:(IMMotionUnit)aMinRoll
{
    @synchronized(self) {
        _minRoll = aMinRoll;
    }
}

//===========================================================
//  maxRoll
//===========================================================
- (IMMotionUnit)maxRoll { @synchronized(self) {return _maxRoll;} }
- (void)setMaxRoll:(IMMotionUnit)aMaxRoll
{
    @synchronized(self) {
        _maxRoll = aMaxRoll;
    }
}

//===========================================================
//  minYaw
//===========================================================
- (IMMotionUnit)minYaw { @synchronized(self) {return _minYaw;} }
- (void)setMinYaw:(IMMotionUnit)aMinYaw
{
    @synchronized(self) {
        _minYaw = aMinYaw;
    }
}

//===========================================================
//  maxYaw
//===========================================================
- (IMMotionUnit)maxYaw { @synchronized(self) {return _maxYaw;} }
- (void)setMaxYaw:(IMMotionUnit)aMaxYaw
{
    @synchronized(self) {
        _maxYaw = aMaxYaw;
    }
}

//===========================================================
//  pitchZones
//===========================================================
- (NSUInteger)pitchZones { @synchronized(self) {return _pitchZones;} }
- (void)setPitchZones:(NSUInteger)aPitchZones
{
    @synchronized(self) {
        _pitchZones = aPitchZones;
    }
}

//===========================================================
//  rollZones
//===========================================================
- (NSUInteger)rollZones { @synchronized(self) {return _rollZones;} }
- (void)setRollZones:(NSUInteger)aRollZones
{
    @synchronized(self) {
        _rollZones = aRollZones;
    }
}

//===========================================================
//  yawZones
//===========================================================
- (NSUInteger)yawZones { @synchronized(self) {return _yawZones;} }
- (void)setYawZones:(NSUInteger)aYawZones
{
    @synchronized(self) {
        _yawZones = aYawZones;
    }
}

//===========================================================
//  currentPitchZoneIdx
//===========================================================
- (NSInteger)currentPitchZoneIdx { @synchronized(self) {return _currentPitchZoneIdx;} }


//===========================================================
//  currentRollZoneIdx
//===========================================================
- (NSInteger)currentRollZoneIdx { @synchronized(self) {return _currentRollZoneIdx;} }


//===========================================================
//  currentYawZoneIdx
//===========================================================
- (NSInteger)currentYawZoneIdx { @synchronized(self) {return _currentYawZoneIdx;} }


//===========================================================
//  currentExitedPitchBoundary
//===========================================================
- (IMMotionUnit)currentExitedPitchBoundary { @synchronized(self) {return _currentExitedPitchBoundary;} }


//===========================================================
//  currentExitedRollBoundary
//===========================================================
- (IMMotionUnit)currentExitedRollBoundary { @synchronized(self) {return _currentExitedRollBoundary;} }


//===========================================================
//  currentExitedYawBoundary
//===========================================================
- (IMMotionUnit)currentExitedYawBoundary { @synchronized(self) {return _currentExitedYawBoundary;} }



/////////////////////////////////////////////////////////////////////////
#pragma mark - IMMotionDetectorProtocol
/////////////////////////////////////////////////////////////////////////


- (void)handleMotionUpdateForData:(IMMotionSampleSet)current previousData:(IMMotionSampleSet)previous
{
    // We want to update the atomic ivars inside the synchro but report to our delegate outside the synchro to prevent circular locks.  Thus all these...
    NSInteger newPitchIdx, newRollIdx, newYawIdx;
    BOOL isNewPitchIdx, isNewRollIdx, isNewYawIdx;
    IMMotionUnit pitchExitBoundary, rollExitBoundary, yawExitBoundary;
    BOOL isPitchBoundaryChange, isRollBoundaryChange, isYawBoundaryChange;
    pitchExitBoundary = rollExitBoundary = yawExitBoundary = kIMSignNone; // default
    
    @synchronized(self) {
        newPitchIdx = _IM_APD_GetZoneIdx(current.attitude.pos.pitch,
                                         _minPitch,
                                         _maxPitch,
                                         _pitchZones);
        newRollIdx = _IM_APD_GetZoneIdx(current.attitude.pos.roll,
                                        _minRoll,
                                        _maxRoll,
                                        _rollZones);
        newYawIdx = _IM_APD_GetZoneIdx(current.attitude.pos.yaw,
                                       _minYaw,
                                       _maxYaw,
                                       _yawZones);
        
        // Check (and cap) for boundaries and changes.  Do the cap before the changes as not double report boundary exits/entries
        
        // Pitch
        if (newPitchIdx >= _pitchZones) {
            newPitchIdx = _pitchZones-1;
            pitchExitBoundary = kIMSignPositive;
        } else if (newPitchIdx < 0) {
            newPitchIdx = 0;
            pitchExitBoundary = kIMSignNegative;
        }
        isNewPitchIdx = (newPitchIdx != _currentPitchZoneIdx);
        isPitchBoundaryChange = (pitchExitBoundary != _currentExitedPitchBoundary);
        
        // Roll
        if (newRollIdx >= _rollZones) {
            newRollIdx = _rollZones-1;
            rollExitBoundary = kIMSignPositive;
        } else if (newRollIdx < 0) {
            newRollIdx = 0;
            rollExitBoundary = kIMSignNegative;
        }
        isNewRollIdx = (newRollIdx != _currentRollZoneIdx);
        isRollBoundaryChange = (rollExitBoundary != _currentExitedRollBoundary);

        // Yaw
        if (newYawIdx >= _yawZones) {
            newYawIdx = _yawZones-1;
            yawExitBoundary = kIMSignPositive;
        } else if (newYawIdx < 0) {
            newYawIdx = 0;
            yawExitBoundary = kIMSignNegative;
        }
        isNewYawIdx = (newYawIdx != _currentYawZoneIdx);
        isYawBoundaryChange = (yawExitBoundary != _currentExitedYawBoundary);
        
        // Assign new values.  Don't bother checking for change...
        _currentPitchZoneIdx = newPitchIdx;
        _currentRollZoneIdx = newRollIdx;
        _currentYawZoneIdx = newYawIdx;
        _currentExitedPitchBoundary = pitchExitBoundary;
        _currentExitedRollBoundary = rollExitBoundary;
        _currentExitedYawBoundary = yawExitBoundary;
    }
    
    /////////////////////////////////////////
    // NOTIFY DELEGATE
    /////////////////////////////////////////

    
    // Don't use our atomic props but the 'cached' stack vars instead
    
    // New zone...
    if (isNewPitchIdx || isNewRollIdx || isNewYawIdx) {
        
        IMLogDetail(@"Zone changed.  New indices: Pitch=%i  Roll=%i  Yaw=%i", newPitchIdx, newRollIdx, newYawIdx);
        
        if (!_delegate) return;
        
        if ([_delegate respondsToSelector:@selector(detector:didReportNewAttititudeZoneWithIndicesForPitch:roll:yaw:)]) {
            // Main thread or this one?
            if (_notifyDelegateOnMainThread) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Not all these are necessarily new/changed, fyi
                    [_delegate detector:self didReportNewAttititudeZoneWithIndicesForPitch:newPitchIdx roll:newRollIdx yaw:newYawIdx];
                });
            } else {
                [_delegate detector:self didReportNewAttititudeZoneWithIndicesForPitch:newPitchIdx roll:newRollIdx yaw:newYawIdx];
            }
        }
    }
    
    // Boundary enter/exit (ie change)
    if (isPitchBoundaryChange || isRollBoundaryChange || isYawBoundaryChange) {
        
        IMLogDetail(@"Boundary crossed.  New exit states: Pitch=%+.0f  Roll=%+.0f Yaw=%.0f", pitchExitBoundary, rollExitBoundary, yawExitBoundary);
        
        if (!_delegate) return;
        
        if ([_delegate respondsToSelector:@selector(detector:didReportEntryOrExitBoundaryWithExitStatesForPitch:roll:yaw:)]) {
            if (_notifyDelegateOnMainThread) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate detector:self didReportEntryOrExitBoundaryWithExitStatesForPitch:pitchExitBoundary roll:rollExitBoundary yaw:yawExitBoundary];
                });
            } else {
                [_delegate detector:self didReportEntryOrExitBoundaryWithExitStatesForPitch:pitchExitBoundary roll:rollExitBoundary yaw:yawExitBoundary];
            }
        }
    }
}





@end

/// @}