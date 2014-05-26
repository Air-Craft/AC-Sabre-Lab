/**
\addtogroup InstrumentMotion
\author     Created by Hari Karam Singh on 08/11/2012.
\copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
@{
*/
/// \file IMFunctions.h


#import <Foundation/Foundation.h>
#import <tgmath.h>
#import "IMDefs.h"
#import "IMConfig.h"

#ifdef __cplusplus
extern "C" {
#endif


/////////////////////////////////////////////////////////////////////////
#pragma mark - Math Ops
/////// @name  Math Ops
/////////////////////////////////////////////////////////////////////////


inline static const IMMotionUnit IM_MapLinearRange(IMMotionUnit inVal, IMMotionUnit inMin, IMMotionUnit inMax, IMMotionUnit outMin, IMMotionUnit outMax)
{
    return ( (inVal-inMin) / (inMax-inMin) * (outMax-outMin) + outMin );
}

/////////////////////////////////////////////////////////////////////////

inline static const IMMotionUnit IM_MapBilinearRange(IMMotionUnit inVal, IMMotionUnit inMin, IMMotionUnit inMax, IMMotionUnit inMed, IMMotionUnit outMin, IMMotionUnit outMax, IMMotionUnit outMed)
{
    if (inVal <= inMed) {
        return IM_MapLinearRange(inVal, inMin, inMed, outMin, outMed);
    } else {
        return IM_MapLinearRange(inVal, inMed, inMax, outMed, outMax);
    }
}

/////////////////////////////////////////////////////////////////////////

inline static const IMMotionUnit IM_Clamp(IMMotionUnit inVal, IMMotionUnit minVal, IMMotionUnit maxVal)
{
    return (inVal < minVal ? minVal : (inVal > maxVal ? maxVal : inVal));
}

/////////////////////////////////////////////////////////////////////////

inline static const IMMotionUnit IM_Wrap(IMMotionUnit inVal, IMMotionUnit min, IMMotionUnit max)
{
    const IMMotionUnit range = max - min;
    
    // Optomisations
    if (inVal >= min) {
        if (inVal <= max)   return inVal;                       // within range
        else if (inVal < max + range) return inVal - range;     // within one range above
    } else if (inVal >= min - range) return inVal + range;      // within one range below
    
    // General case
    return fmod(inVal - min, range) + min;
}


/// @}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Data Type Utilities
/////// @name  Data Type Utilities
/////////////////////////////////////////////////////////////////////////



/**
 Test for 0/empty.  Be sure its been properly init'ed to {0} first!
 */
inline static const BOOL IM_IsEmptyMotionDataSample(IMMotionSample *d)
{
    IMMotionSample empty = {0};
    if (memcmp(d, &empty, sizeof(IMMotionSample)) == 0) return YES;
    return NO;
};



/**
 Test for 0/empty.  Be sure its been properly init'ed to {0} first!
 */
inline static const BOOL IM_IsEmptyMotionDataSet(IMMotionSampleSet *d)
{
    IMMotionSampleSet empty = {0};
    if (memcmp(d, &empty, sizeof(IMMotionSampleSet)) == 0) return YES;
    return NO;
}



/**
 Reset to {0}
 */
inline static void IM_ClearMotionDataSet(IMMotionSampleSet *d)
{
    memset(d, 0, sizeof(IMMotionSampleSet));
}



inline static IMVectorCoord const IM_GetVectorCoordFromSample(IMMotionSample aMotionSample,
                                                              IMMotionType aMotionType)
{
    switch (aMotionType) {
        case kIMMotionTypePosition: return aMotionSample.pos;
        case kIMMotionTypeVelocity: return aMotionSample.vel;
        case kIMMotionTypeAcceleration: return aMotionSample.accel;
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
    }
}




inline static IMMotionUnit const IM_GetMotionValueFromSampleSet(IMMotionSampleSet motionSampleSet,
                                                                IMAxis anAxis,
                                                                IMMotionType aMotionType)
{
    switch (anAxis) {
        case kIMAxisAccelX: return IM_GetVectorCoordFromSample(motionSampleSet.accelerometer, aMotionType).x;
        case kIMAxisAccelY: return IM_GetVectorCoordFromSample(motionSampleSet.accelerometer, aMotionType).y;
        case kIMAxisAccelZ: return IM_GetVectorCoordFromSample(motionSampleSet.accelerometer, aMotionType).z;
            
        case kIMAxisGyroX: return IM_GetVectorCoordFromSample(motionSampleSet.gyroscope, aMotionType).x;
        case kIMAxisGyroY: return IM_GetVectorCoordFromSample(motionSampleSet.gyroscope, aMotionType).y;
        case kIMAxisGyroZ: return IM_GetVectorCoordFromSample(motionSampleSet.gyroscope, aMotionType).z;
            
        case kIMAxisPitch: return IM_GetVectorCoordFromSample(motionSampleSet.attitude, aMotionType).pitch;
        case kIMAxisRoll: return IM_GetVectorCoordFromSample(motionSampleSet.attitude, aMotionType).roll;
        case kIMAxisYaw: return IM_GetVectorCoordFromSample(motionSampleSet.attitude, aMotionType).yaw;
            
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
    }
}

/**
 Extract data for a single axis from IMMotionSample into IMMotionCoord's. Also can be used to get a correlated axis from another sample type, for example pass in an attitude sample plus kIMAxisGyroX to get Pitch motion data.
 */
inline static void IM_GetMotionCoordDataFromSampleForAxis(IMMotionSample const *inSample,
                                                          IMAxis axisName,
                                                          IMMotionCoord *outMotionCoord,
                                                          IMMotionCoord *outMotionSC,
                                                          IMMotionCoord *outSCDelta)
{
    switch (axisName) {
        case kIMAxisAccelX:
        case kIMAxisGyroX:
        case kIMAxisPitch:
            outMotionCoord->pos = inSample->pos.x;
            outMotionCoord->vel = inSample->vel.x;
            outMotionCoord->accel = inSample->accel.x;
            outMotionSC->pos = inSample->posSC.x;
            outMotionSC->vel = inSample->velSC.x;
            outMotionSC->accel = inSample->accelSC.x;
            outSCDelta->pos = inSample->posDeltaSinceSC.x;
            outSCDelta->vel = inSample->velDeltaSinceSC.x;
            outSCDelta->accel = 0;
            break;
            
        case kIMAxisAccelY:
        case kIMAxisGyroY:
        case kIMAxisRoll:
            outMotionCoord->pos = inSample->pos.y;
            outMotionCoord->vel = inSample->vel.y;
            outMotionCoord->accel = inSample->accel.y;
            outMotionSC->pos = inSample->posSC.y;
            outMotionSC->vel = inSample->velSC.y;
            outMotionSC->accel = inSample->accelSC.y;
            outSCDelta->pos = inSample->posDeltaSinceSC.y;
            outSCDelta->vel = inSample->velDeltaSinceSC.y;
            outSCDelta->accel = 0;
            break;
            
        case kIMAxisAccelZ:
        case kIMAxisGyroZ:
        case kIMAxisYaw:
            outMotionCoord->pos = inSample->pos.z;
            outMotionCoord->vel = inSample->vel.z;
            outMotionCoord->accel = inSample->accel.z;
            outMotionSC->pos = inSample->posSC.z;
            outMotionSC->vel = inSample->velSC.z;
            outMotionSC->accel = inSample->accelSC.z;
            outSCDelta->pos = inSample->posDeltaSinceSC.z;
            outSCDelta->vel = inSample->velDeltaSinceSC.z;
            outSCDelta->accel = 0;
            break;
            
            
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
            break;
    }
}
   
    
    
/** Returns the correlated attitude axis for a gyro axis, eg, GyroX -> Pitch, GyroY -> Roll
 \throws NSException::NSInvalidArgumentException if axis is not kIMAxisGyro[XYZ] 
 */
inline static IMAxis const IM_GetCorrelatedAttitudeAxisForGyroAxis(IMAxis anAxis)
{
    switch (anAxis) {
        case kIMAxisGyroX: return kIMAxisPitch;
        case kIMAxisGyroY: return kIMAxisRoll;
        case kIMAxisGyroZ: return kIMAxisYaw;
        
        default:
            [NSException raise:NSInvalidArgumentException format:@"anAxis must be a Gyro axis"];
            break;
    }
    return kIMAxisPitch;    // prevent warnings
}
    
    

/** Returns IMHitShakeAxisDescriptor enum for the positive edge for the given IMAxis.  I.e, converts IMAxis type to IMHitShakeAxisDescriptor */
inline static IMHitShakeAxisDescriptor const IM_GetPositiveHitShakeAxisDescriptorAxis(IMAxis anAxis) {
    switch (anAxis) {
        case kIMAxisAccelX:        return kIMHitShakeAxisDescriptorXPositive;
        case kIMAxisAccelY:        return kIMHitShakeAxisDescriptorYPositive;
        case kIMAxisAccelZ:        return kIMHitShakeAxisDescriptorZPositive;
            
        case kIMAxisGyroX:    return kIMHitShakeAxisDescriptorGyroXPositive;
        case kIMAxisGyroY:    return kIMHitShakeAxisDescriptorGyroYPositive;
        case kIMAxisGyroZ:    return kIMHitShakeAxisDescriptorGyroZPositive;
            
        case kIMAxisPitch:    return kIMHitShakeAxisDescriptorPitchPositive;
        case kIMAxisRoll:     return kIMHitShakeAxisDescriptorRollPositive;
        case kIMAxisYaw:      return kIMHitShakeAxisDescriptorYawPositive;
            
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
    }
}



/** Returns IMHitShakeAxisDescriptor enum for the negative edge for the given IMAxis.  I.e, converts IMAxis type to IMHitShakeAxisDescriptor */
inline static IMHitShakeAxisDescriptor const IM_GetNegativeHitShakeAxisDescriptorAxis(IMAxis anAxis)
{
    switch (anAxis) {
        case kIMAxisAccelX:        return kIMHitShakeAxisDescriptorXNegative;
        case kIMAxisAccelY:        return kIMHitShakeAxisDescriptorYNegative;
        case kIMAxisAccelZ:        return kIMHitShakeAxisDescriptorZNegative;
            
        case kIMAxisGyroX:    return kIMHitShakeAxisDescriptorGyroXNegative;
        case kIMAxisGyroY:    return kIMHitShakeAxisDescriptorGyroYNegative;
        case kIMAxisGyroZ:    return kIMHitShakeAxisDescriptorGyroZNegative;
            
        case kIMAxisPitch:    return kIMHitShakeAxisDescriptorPitchNegative;
        case kIMAxisRoll:     return kIMHitShakeAxisDescriptorRollNegative;
        case kIMAxisYaw:      return kIMHitShakeAxisDescriptorYawNegative;
            
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
    }
}

    /// @}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Motion Calculations
/// @name Motion Calculations
/////////////////////////////////////////////////////////////////////////
/// @{


/**
 Check two values and return sign change.  0 is considered positive.
 \return +1.0, 0.0, -1.0
 */
inline static IMMotionUnit IM_GetSignChange(IMMotionUnit x0, IMMotionUnit x1)
{
    if (x0 < 0 && x1 >= 0) return kIMSignPositive;
    if (x0 > 0 && x1 <= 0) return kIMSignNegative;
    return kIMSignNone;
}
    
    
    
/** Return the max magnitude (>=0) for acceleration for each axis
 
    These are practical values and can be exceeded @see IMConfig.h 
 */
inline static IMMotionUnit const IM_GetMaxAccelerationForAxis(IMAxis anAxis)
{
    switch (anAxis) {
        case kIMAxisAccelX:        return IM_MAX_ACCELERATION_X;
        case kIMAxisAccelY:        return IM_MAX_ACCELERATION_Y;
        case kIMAxisAccelZ:        return IM_MAX_ACCELERATION_Z;
            
        case kIMAxisGyroX:    return IM_MAX_ACCELERATION_GYRO_X;
        case kIMAxisGyroY:    return IM_MAX_ACCELERATION_GYRO_Y;
        case kIMAxisGyroZ:    return IM_MAX_ACCELERATION_GYRO_Z;
            
        case kIMAxisPitch:    return IM_MAX_ACCELERATION_PITCH;
        case kIMAxisRoll:     return IM_MAX_ACCELERATION_ROLL;
        case kIMAxisYaw:      return IM_MAX_ACCELERATION_YAW;
            
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
    }
}
    
    
    
/** Return the max magnitude (>=0) for velocity for each axis
 
 These are practical values and can be exceeded @see IMConfig.h.  Accelerometer currently not supported
 \throws NSException(NSInvalidArgumentException) for Accelerometer axes
 */
inline static IMMotionUnit const IM_GetMaxVelocityForAxis(IMAxis anAxis)
{
    switch (anAxis) {
        case kIMAxisAccelX:
        case kIMAxisAccelY:
        case kIMAxisAccelZ:
            [NSException raise:NSInvalidArgumentException format:@"Velocity not supported for Accelerometer"];
            
        case kIMAxisGyroX:    return IM_MAX_VELOCITY_GYRO_X;
        case kIMAxisGyroY:    return IM_MAX_VELOCITY_GYRO_Y;
        case kIMAxisGyroZ:    return IM_MAX_VELOCITY_GYRO_Z;
            
        case kIMAxisPitch:    return IM_MAX_VELOCITY_PITCH;
        case kIMAxisRoll:     return IM_MAX_VELOCITY_ROLL;
        case kIMAxisYaw:      return IM_MAX_VELOCITY_YAW;
            
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
    }
}
    
    
    
/** Return the max magnitude (>=0) of position for an axis
 
 These are practical values and can be exceeded @see IMConfig.h.  Accelerometer and Gyroscope not supported
 \param
 \throws NSException(NSInvalidArgumentException) for Accelerometer * Gyroscope axes
 */
inline static IMMotionUnit const IM_GetMaxPositionForAxis(IMAxis anAxis)
{
    switch (anAxis) {
        case kIMAxisAccelX:
        case kIMAxisAccelY:
        case kIMAxisAccelZ:
            [NSException raise:NSInvalidArgumentException format:@"Position not supported for Accelerometer"];
            
        case kIMAxisGyroX:
        case kIMAxisGyroY:
        case kIMAxisGyroZ:
            [NSException raise:NSInvalidArgumentException format:@"Position not supported for Gyroscope (use Attitude)"];
            
        case kIMAxisPitch:    return M_PI_2;
        case kIMAxisRoll:     return M_PI;
        case kIMAxisYaw:      return M_PI;
            
        default:
            [NSException raise:NSGenericException format:@"Shouldn't be!!!"];
    }
}

    

/** Generic version of above which also supports max vector magnitude of combined axes.  
 
 Calls the appropriate function above. Note, some values arent supported and some are practical limits which might be exceeded.  See the funcitons above. 
 
 \param anAxisBitmask An IMAxis or bitmask combo thereof
 \throws NSException(NSInvalidArgumentException) for unsupported axis/motiontypes like position and kIMAxisAccelX 
 \throws NSException(NSInvalidArgumentException) if aMotionType is not exactly one of the enums (no bitmasking support for this one)*/
inline static IMMotionUnit const IM_GetMaxMagnitudeForMotionOnAxes(IMAxis anAxisBitmask, IMMotionType aMotionType)
{

    // Get the corresponding function pointer
    const IMMotionUnit (*getMaxFunc)(IMAxis);
    switch (aMotionType) {
        case kIMMotionTypePosition: getMaxFunc = &IM_GetMaxPositionForAxis; break;
        case kIMMotionTypeVelocity: getMaxFunc = &IM_GetMaxVelocityForAxis; break;
        case kIMMotionTypeAcceleration: getMaxFunc = &IM_GetMaxAccelerationForAxis; break;
        default: [NSException raise:NSInvalidArgumentException format:@"Invalid motion type."];
    }
    
    
    IMMotionUnit sumSquared = 0;
    switch (anAxisBitmask) {
            // Just a simple axis?  Return the max
        case kIMAxisAccelX: case kIMAxisAccelY: case kIMAxisAccelZ:
        case kIMAxisGyroX: case kIMAxisGyroY: case kIMAxisGyroZ:
        case kIMAxisPitch: case kIMAxisRoll: case kIMAxisYaw:
            return getMaxFunc(anAxisBitmask);
            break;
            
            // Otherwise do the vector magnitude
        default:
            sumSquared = 0;
            
            IMAxis axes[] = { kIMAxisAccelX, kIMAxisAccelY, kIMAxisAccelZ, kIMAxisGyroX, kIMAxisGyroY, kIMAxisGyroZ, kIMAxisPitch, kIMAxisRoll, kIMAxisYaw };
            
            for (int i=0; i<9; i++) {
                if (anAxisBitmask & axes[i]) {
                    IMMotionUnit val = getMaxFunc(axes[i]);
                    sumSquared += val * val;
                }
            }
            
            return sqrt(sumSquared);
            break;
    }
}
    
    
    
    
    
/** For a single axis returns the abs value of the specified motiontype.  For a multiple bitmask axis, computes the vector magnitude
 \param anAxisBitmask   Bitmask of IMAxis enums for the combo to compute
 \param aMotionType     Does NOT support bitmasking (though the enum does)
 \throws NSException if aMotionType is a bitmasked multiple 
 */
    inline static IMMotionUnit const IM_GetMotionMagnitudeOfAxesOnSampleSet(IMMotionSampleSet motionSampleSet,
                                                                     IMAxis anAxisBitmask,
                                                                     IMMotionType aMotionType)
    {
    IMMotionUnit sumSquared;
    
    switch (anAxisBitmask) {
            
            // First do exact axes as absolute values as this is more common and quicker than squaring and then square rooting
        case kIMAxisAccelX:
        case kIMAxisAccelY:
        case kIMAxisAccelZ:
        case kIMAxisGyroX:
        case kIMAxisGyroY:
        case kIMAxisGyroZ:
        case kIMAxisPitch:
        case kIMAxisRoll:
        case kIMAxisYaw:
            return fabs(IM_GetMotionValueFromSampleSet(motionSampleSet, anAxisBitmask, aMotionType));
            
            // Otherwise get vector compute the magnitude
        default:
            sumSquared = 0;
            
            IMAxis axes[] = { kIMAxisAccelX, kIMAxisAccelY, kIMAxisAccelZ, kIMAxisGyroX, kIMAxisGyroY, kIMAxisGyroZ, kIMAxisPitch, kIMAxisRoll, kIMAxisYaw };
            
            for (int i=0; i<9; i++) {
                if (anAxisBitmask & axes[i]) {
                    IMMotionUnit val = IM_GetMotionValueFromSampleSet(motionSampleSet, axes[i], aMotionType);
                    sumSquared += val * val;
                }
            }
            
            return sqrt(sumSquared);
    }
}

    
/// @}



/////////////////////////////////////////////////////////////////////////
#pragma mark - Logging & Addit'l Debugging
/////// @name  Logging & Addit'l Debugging
/////////////////////////////////////////////////////////////////////////
    
extern NSString *IM_GetStringForHitShakeAxisDescriptor(IMHitShakeAxisDescriptor descr);
    

#ifdef __cplusplus
}
#endif


/// @}

