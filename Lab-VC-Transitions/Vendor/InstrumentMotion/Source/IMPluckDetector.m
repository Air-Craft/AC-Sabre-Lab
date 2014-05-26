//
//  PluckDetector.m
//  SoundWand
//
//  Created by Hari Karam Singh on 07/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IMPluckDetector.h"
#import "IMDefs.h"
#import "InstrumentMotionDebug.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - IMPluckDetector
/////////////////////////////////////////////////////////////////////////



@implementation IMPluckDetector
{
    IMMotionUnit _minEngagementtAngle;  ///< Minimum angle below which plucks won't occur on complimentary axis (yaw<->pitch)
    IMMotionUnit _maxEngagementAngle;
    
    /** The angle through which you must move in order to pluck a string.  tao/2 in the class doc's formula. */
    IMMotionUnit _pluckThroughRadius;

    /**
     Index of string whose pluck zone has been entered but not
     yet exited and therefore is a candidate for a pluck
     */
    NSUInteger _pluckZoneLatchIndex;
    
    /** Flag indicating that a zone was entered during the last sample */
    BOOL _pluckZoneIsLatched;
    
    /** Direction the latched zone was entered into via */
    IMDirection _pluckZoneLatchDirection;
    
    
    /**@{
     Values on the previous motion handling round
     */
    IMMotionUnit _prevPluckAngle;
    IMMotionUnit _prevPluckAngleVel;
    BOOL _isFirstRound;
    /**@}*/
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

- (IMPluckDetector *)initWithPluckZoneCount:(NSUInteger)cnt 
                              minPluckAngle:(IMMotionUnit)minPA
                              maxPluckAngle:(IMMotionUnit)maxPA

{
    if (self = [super init]) {
        NSAssert(cnt > 0, @"_zoneCount must be greater than 0");
        
        _isFirstRound = YES;
        self.zoneLayoutAxis = kIMAxisYaw;   // Triggers some addt'l inits
        _zoneCount = cnt;
        _zoneLayoutAxis = kIMAxisYaw;
        _minPluckAngle = minPA;
        _maxPluckAngle = maxPA;
    }
    return self;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

- (void)setZoneLayoutAxis:(IMAxis)zoneLayoutAxis
{
    _zoneLayoutAxis = zoneLayoutAxis;
    
    // Set some constants based on the angle
    switch (_zoneLayoutAxis) {
        case kIMAxisYaw:
            _minEngagementtAngle = IM_PD_MIN_PITCH_FOR_YAW_PLUCK;
            _maxEngagementAngle = IM_PD_MAX_PITCH_FOR_YAW_PLUCK;
            _pluckThroughRadius = IM_PD_PLUCK_THROUGH_ANGLE_RADIUS;
            break;
            
        case kIMAxisPitch:
            // Pitch plucks doesn't have the singularity problem wrt to yaw, like yaw plucks do wrt pitch
            _minEngagementtAngle = -M_PI;
            _maxEngagementAngle = M_PI;
            
            // Pitch on +-M_PI/2 in total so reduce the pluck through radius proportionally
            _pluckThroughRadius = IM_PD_PLUCK_THROUGH_ANGLE_RADIUS * 0.5;
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException format:@"Only Pitch and Yaw are supported at the moment."];
            // Unsupported
            
    }
    
    [self _resetDetection];
}

//---------------------------------------------------------------------

- (void)setZoneCount:(NSUInteger)zoneCount
{
    _zoneCount = zoneCount;
    [self _resetDetection];
}

//---------------------------------------------------------------------

- (void)setMinPluckAngle:(IMMotionUnit)minPluckAngle
{
    _minPluckAngle = minPluckAngle;
    [self _resetDetection];
}

//---------------------------------------------------------------------

- (void)setMaxPluckAngle:(IMMotionUnit)maxPluckAngle
{
    _maxPluckAngle = maxPluckAngle;
    [self _resetDetection];
}

//---------------------------------------------------------------------

@synthesize currentPluckAngle=_currentPluckAngle;

- (IMMotionUnit)currentPluckAngle
{
    @synchronized(self) {
        return _currentPluckAngle;
    }
}



/////////////////////////////////////////////////////////////////////////
#pragma mark - Public API
/////////////////////////////////////////////////////////////////////////

- (void)reset
{
    @synchronized(self) {
        [self _resetDetection];
    }
}

/////////////////////////////////////////////////////////////////////////

- (void)handleMotionUpdateForData:(IMMotionSampleSet)current previousData:(IMMotionSampleSet)previous
{
    IMVectorCoord positionData = current.attitude.pos;
    IMVectorCoord velocityData = current.attitude.vel;
    
    float interpolZoneIndexWRTPositiveEdge = 0.0;   // see method notes
    float interpolZoneIndexWRTNegativeEdge = 0.0;
    float interpolZoneIndexWRTCenter = 0.0;
    float prevInterpolZoneIndexWRTPositiveEdge = 0.0;
    float prevInterpolZoneIndexWRTNegativeEdge = 0.0;
    float prevInterpolZoneIndexWRTCenter = 0.0;
    NSInteger startIndex = 0, endIndex = 0, i;
    
    IMMotionUnit pluckAngleVel = 0.0f, pluckAngle = 0.0f, engageAngle = 0.0f, engageAngleVel = 0.0f;
    
    // placeholders for repeat calcs
    IMMotionUnit factor = 0.0f, pluckAngleMinusMin = 0.0f, _prevPluckAngleMinusMin = 0.0f;

    // Only competing element is reset and the atomic properties
    // which currently dont mutex (they probably should)
    @synchronized(self) {
        
        // Lock and get local copy of to-be thread safe vars
        // Minimises time in the lock for smoother updates from external threads (DEPRECATED)
        NSUInteger zoneCnt;
        IMMotionUnit minPluckAng, maxPluckAng, theTao;
        BOOL isFirstRnd, pluckZoneLatched;

        zoneCnt = _zoneCount;
        minPluckAng = _minPluckAngle;
        maxPluckAng = _maxPluckAngle;
        isFirstRnd = _isFirstRound;
        pluckZoneLatched = _pluckZoneIsLatched;
        theTao = _pluckThroughRadius * 2;
    
        // Grab the latest motion values wrt to assigned orientation 
        if (_zoneLayoutAxis == kIMAxisYaw) {
            // Plucks occur by sweeping device around the yaw axis (sideways)
            _currentPluckAngle = pluckAngle = positionData.yaw * (_reversePluckAngleOrientation ? -1 : 1);
            pluckAngleVel = velocityData.yaw * (_reversePluckAngleOrientation ? -1 : 1);
            engageAngle = positionData.pitch * (_reverseEngagementAngleOrientation ? -1 : 1);
            engageAngleVel = velocityData.pitch * (_reverseEngagementAngleOrientation ? -1 : 1);
        } else {
            // Or around the pitch axis (up/down)
            // Grab a ref for output
            _currentPluckAngle = pluckAngle = positionData.pitch * (_reversePluckAngleOrientation ? -1 : 1);
            pluckAngleVel = velocityData.pitch * (_reversePluckAngleOrientation ? -1 : 1);
            engageAngle = positionData.yaw * (_reverseEngagementAngleOrientation ? -1 : 1);
            engageAngleVel = velocityData.yaw * (_reverseEngagementAngleOrientation ? -1 : 1);
        }
        

        // Limit pluckAngle to our action range
        // Ensures the pluck index stays in range.  May be better to use conditionals for each pluck detection below...
        /*if (pluckAngle < minPluckAng) 
            pluckAngle = minPluckAng;
        else if (pluckAngle > maxPluckAng)
            pluckAngle = maxPluckAng;
        */
        
        // If there hasnt been enough samples then there is no velocity and nothing
        // we can do.
    //    if (!positionData.hasVelocity)
     //       return;
        
        // Initial values might detect erroneous plucks.  Wait one round...
        if (isFirstRnd) {
            _isFirstRound = NO;
            _prevPluckAngle = pluckAngle;
            _prevPluckAngleVel = pluckAngleVel;
            return;
        }
        
        // Check that we are in our engagement range, unlatch any zones if not
        // If we are outside of our range then unlatch and return...
        // Note this should come after first round detection
        if (engageAngle > _maxEngagementAngle || engageAngle < _minEngagementtAngle) {
            IMLogDetail("Moved outside of engagement angle on %@ axis", _zoneLayoutAxis == kIMAxisYaw ? @"YAW":@"AXIS");
            _pluckZoneIsLatched = NO;
            _prevPluckAngle = pluckAngle;
            _prevPluckAngleVel = pluckAngleVel;
            return;
        }
        
        
        // Safety check:  
        // If we crossed the -PI/+PI boundary we'll get one hell of a cacophony so reset if we did
        // We can only do this with velocity as any range M->N which doesnt include the boudary could be M->N the opposite
        // direction that DOES include it!
        if (fabs(pluckAngleVel) > IM_PD_VELOCITY_SAFETY_THRESHOLD) {
            IMLogDetail("Safety threshold exceeded... (+-PI boundary crossed).");
            // Reset the latches too
            _pluckZoneIsLatched = NO;
            _prevPluckAngle = pluckAngle;
            _prevPluckAngleVel = pluckAngleVel;
            return;
        }
        
        // Now for pluck detection...
        
        // The slow way: loop through virtual strings/pluck zones and calc individually...booo
        // The FAST way: invert the pluck zone position-of-zone-with-index formula and solve 
        // for the (interpolated) index of the zone *as a float* and then compare it
        // to see if we've crossed any edges
        // eg. if interp_index(current position) = 3.254 => we are on the positive side of strings 0-3
        // To do this there are 6 calculataions curr & prev position (2) x left edge & right edge &
        // center (edge crossing which begins to "pluck" the string/pluckzone).  
        pluckAngleMinusMin = (pluckAngle - minPluckAng);
        _prevPluckAngleMinusMin = (_prevPluckAngle - minPluckAng);
        factor = (IMMotionUnit)((IMMotionUnit)zoneCnt - 1.0) / (maxPluckAng - minPluckAng - theTao);

        interpolZoneIndexWRTPositiveEdge        = (pluckAngleMinusMin - theTao)        * factor;
        interpolZoneIndexWRTNegativeEdge        = pluckAngleMinusMin                * factor;
        interpolZoneIndexWRTCenter              = (pluckAngleMinusMin - theTao/2.0)    * factor;  
        prevInterpolZoneIndexWRTPositiveEdge    = (_prevPluckAngleMinusMin - theTao)        * factor;
        prevInterpolZoneIndexWRTNegativeEdge    = _prevPluckAngleMinusMin                * factor;
        prevInterpolZoneIndexWRTCenter          = (_prevPluckAngleMinusMin - theTao/2.0)    * factor;  
        
        /////////////////////////////////////////
        // PART 1: Do any obvious crossings first
        /////////////////////////////////////////
        if (pluckAngleVel > 0) {
            startIndex = (int)ceil(prevInterpolZoneIndexWRTCenter);
            endIndex = (int)floor(interpolZoneIndexWRTPositiveEdge);
        } else {
            // negative velocity
            endIndex = (int)floor(prevInterpolZoneIndexWRTCenter);
            startIndex = (int)ceil(interpolZoneIndexWRTNegativeEdge);
        }
        
        // If they arent the same then we have a whole zone (or more) crossed in the sample time
        for (i = startIndex; i <= endIndex; i++) {  
            if (i == _pluckZoneLatchIndex)       // clear index latch if required (in case of rapid direction change)
                _pluckZoneIsLatched = NO;
            if (i >= 0 && i < zoneCnt) 
                [self _doPluckEventForIndex:i pluckAngleVelocity:pluckAngleVel engagementAngle:engageAngle];
            IMLogDetail(@"Skippover pluck %i", i);
        }
        
        /////////////////////////////////////////
        // PART 2: Test for pluck on previously a latched string
        /////////////////////////////////////////
        if (_pluckZoneIsLatched) {
            //IMLogRealTime(@"%f, %f, %f, %f, %f, %f", interpolZoneIndexWRTNegativeEdge, interpolZoneIndexWRTCenter, interpolZoneIndexWRTPositiveEdge, prevInterpolZoneIndexWRTNegativeEdge, prevInterpolZoneIndexWRTCenter, prevInterpolZoneIndexWRTPositiveEdge);
            
            // If entered with a positive velocity (from the negative edge),
            // then we must exit out the positive edge
            if (_pluckZoneLatchDirection == kIMDirectionPositive) {
                
                // Have we exited out the other edge? => pluck!
                // (>= for open boundaries on exit)
                if (interpolZoneIndexWRTPositiveEdge >= _pluckZoneLatchIndex) {
                    [self _doPluckEventForIndex:_pluckZoneLatchIndex pluckAngleVelocity:pluckAngleVel engagementAngle:engageAngle];
                    _pluckZoneIsLatched = NO;
                    
                // Exited via the edge we came in through? => unlatch
                } else if (interpolZoneIndexWRTCenter < _pluckZoneLatchIndex) {
                    _pluckZoneIsLatched = NO;
                }
                
            // Invert the process for a latch with negative direction
            } else {
                if (interpolZoneIndexWRTNegativeEdge <= _pluckZoneLatchIndex) {
                    [self _doPluckEventForIndex:_pluckZoneLatchIndex pluckAngleVelocity:pluckAngleVel engagementAngle:engageAngle];
                    _pluckZoneIsLatched = NO;
                    
                    // Or via the edge we came in through => unlatch
                } else if (interpolZoneIndexWRTCenter > _pluckZoneLatchIndex) {
                    _pluckZoneIsLatched = NO;
                }
            }
        }
        //IMLogRealTime(@"%.3f->%.3f, %.3f->%.3f", prevInterpolZoneIndexWRTCenter, interpolZoneIndexWRTCenter, prevInterpolZoneIndexWRTPositiveEdge, interpolZoneIndexWRTPositiveEdge);
        /////////////////////////////////////////
        // PART 3: Test for a string to be latched, ie we've crossed into its zone but not exited out the otehr side yet
        /////////////////////////////////////////
        if (!_pluckZoneIsLatched) {
            if (pluckAngleVel > 0) {
                
                // i.e. if (inside pluck zone && wasn't inside pluck zone last time...
                NSInteger latchIdx = ceil(interpolZoneIndexWRTPositiveEdge);
                if (latchIdx >= 0 && latchIdx < zoneCnt &&
                    floor(interpolZoneIndexWRTPositiveEdge) < floor(interpolZoneIndexWRTCenter)
                    && floor(prevInterpolZoneIndexWRTCenter) < floor(interpolZoneIndexWRTCenter)) {
                    _pluckZoneIsLatched = YES;
                    _pluckZoneLatchIndex = latchIdx;
                    _pluckZoneLatchDirection = kIMDirectionPositive;
                    //IMLogRealTime(@"latched: %i", _pluckZoneLatchIndex);
                }
                
            // Approach from the positive edge (neg velocity)
            } else {
                NSInteger latchIdx = floor(interpolZoneIndexWRTNegativeEdge);
                if (latchIdx >= 0 && latchIdx < zoneCnt &&
                    floor(interpolZoneIndexWRTNegativeEdge) > floor(interpolZoneIndexWRTCenter) &&
                    floor(prevInterpolZoneIndexWRTCenter) > floor(interpolZoneIndexWRTCenter)) {
                    _pluckZoneIsLatched = YES;
                    _pluckZoneLatchIndex = latchIdx;
                    _pluckZoneLatchDirection = kIMDirectionNegative;
                    //IMLogRealTime(@"latched: %i", _pluckZoneLatchIndex);
                }
            }
        }

        // Store the pluckAngle values for the next update    
        _prevPluckAngle = pluckAngle;
        _prevPluckAngleVel = pluckAngleVel;
        
    } // end @sync(self)
}

/////////////////////////////////////////////////////////////////////////

/**
 Internal method to send a pluck to our event block.
 
 Normalises the velocity and augments in based on our pitch angle
 **/
- (void)_doPluckEventForIndex:(NSUInteger)indx pluckAngleVelocity:(IMMotionUnit)pluckAngleVel engagementAngle:(IMMotionUnit)engagementAng
{
    float normedScaledVel;
    
    // Start by normalising the vel and engageAngle to 0..1
    normedScaledVel = fabs(pluckAngleVel / IM_ATTITUDE_MAX_VELOCITY);
    
    // And apply floor ceiling
    normedScaledVel = normedScaledVel > 1.0f ? 1.0f : normedScaledVel;
    normedScaledVel = normedScaledVel < 0.0f ? 0.0f : normedScaledVel;
        
    if (_delegate) {
        [_delegate pluckDidOccurForZoneIndex:indx withVelocity:normedScaledVel];
    }
    // I think we commented this out because the events were just triggering stuff in the audio engine which was on the same thread as this anyway. I've added a "MainQueue" version above
    //dispatch_async(dispatch_get_main_queue(), ^{ [_delegate pluckDidOccurForZoneIndex:indx withNormalisedVelocity:normedScaledVel]; });

    IMLogDetail("Pluck! idx=%u angVel=%f normVel=%f engAng=%f", indx, pluckAngleVel, normedScaledVel, engagementAng);
}

/////////////////////////////////////////////////////////////////////////

/**
 Internal non thread safe version of the public API
 */
- (void)_resetDetection
{
    _pluckZoneIsLatched = NO;
    _isFirstRound = YES;     // might be necessary if we've paused for a while an then resume to prevent
    // huge sweeps being registered

}
@end
