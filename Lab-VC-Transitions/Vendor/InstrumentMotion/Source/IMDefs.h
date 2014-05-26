

#ifdef __cplusplus
extern "C" {
#endif

/////////////////////////////////////////////////////////////////////////
#pragma mark - Basic Types
/////// @name  Basic Types
/////////////////////////////////////////////////////////////////////////

/**
 Used for now, for all motion values and their derivatives.  CGFloat handles 32/64bit based on the processor type
 */
typedef CGFloat IMMotionUnit;

/// @}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Motion Representation Types
/** @name  Motion Representation Types
 
 */
/////////////////////////////////////////////////////////////////////////


/**
 Generic axis params.  Access via x,y,z, or pitch,roll,yaw
 */
typedef union {
    struct {
        IMMotionUnit x, y, z;
    };
    struct {
        IMMotionUnit pitch, roll, yaw;
    };
} IMVectorCoord;



/**
 Motion params for single axis.  Representational basis alternative to IMVectorCoord
 */
typedef struct {
    IMMotionUnit pos, vel, accel;
} IMMotionCoord;



/**
 Sensor reading plus derived components off all axes for a particular CoreMotion sensor set (eg gyroscope).
 
 Done in the basis of IMVectorCoord rather than IMMotionCoord as the CM framework readers are similarly structed (ending in .x, or .pitch rather than .pos, .vel, .accel).
 
 NOTE: Not all values are set for all motion sets. See IMMotionAnalyzer notes
 */
typedef struct {
    IMVectorCoord pos, vel, accel;
    
    /** Sign Change: -1.0, 0.0, or 1.0 (or kIMSign*) for each component */
    IMVectorCoord posSC, velSC, accelSC;
    
    /** The (signed) amount transvered since subsequent sign changes of its derivative.  Eg. posDeltaSinceSC is position transversed since last velocity sign change. With motionanalyzer this value is maximum at the point of a new sign change and resets on subsequent 
     */
    IMVectorCoord posDeltaSinceSC, velDeltaSinceSC;
    
    NSTimeInterval timestamp;
} IMMotionSample;


/**
 Complete set of samples from each CM sensor set.  Not all params of all will be filled */
typedef struct {
    IMMotionSample accelerometer, gyroscope, attitude;
    
    /** Check to see whether these values are being computed */
    BOOL hasAccelerometer, hasGyroscope, hasAttitude;
    
    NSTimeInterval timestamp;     ///< dup of internal one for convenience
    
} IMMotionSampleSet;

/// @}



/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts & Enums
/////// @name  Consts & Enums
/////////////////////////////////////////////////////////////////////////

    
/** Const used to indicate undefined values.  =FLT_MAX */
extern IMMotionUnit const kIMMotionUnitUndefined;

    
    
// @{
/** Maximum values for various read an derived motion parameters.  These are practical caps for intense motion.  Real values may exceed them! */
extern IMMotionUnit const kIMMaxAccelerationX;
extern IMMotionUnit const kIMMaxAccelerationY;
extern IMMotionUnit const kIMMaxAccelerationZ;
// @}

    

/**
 Enum constants for indicating positive and negative motion directions.
 */
typedef enum : NSUInteger {
    kIMDirectionPositive,
    kIMDirectionNegative
} IMDirection;



/**
 Convenient representations of 0.0, +-1.0 for communicating sign changes between two coords boundary crossings, etc.  These are IMMotionUnit type so they can be used with the structs above
 */
extern IMMotionUnit const kIMSignNone;
extern IMMotionUnit const kIMSignPositive;
extern IMMotionUnit const kIMSignNegative;



/**
 Representation of an axis in a core motion data set
 */
typedef enum : NSUInteger {
    kIMAxisAccelX = 1 << 0,  ///< Accel*erometer*, not accel*eration*
    kIMAxisAccelY = 1 << 1,
    kIMAxisAccelZ = 1 << 2,
    kIMAxisGyroX = 1 << 3,
    kIMAxisGyroY = 1 << 4,
    kIMAxisGyroZ = 1 << 5,
    kIMAxisPitch = 1 << 6,
    kIMAxisRoll = 1 << 7,
    kIMAxisYaw = 1 << 8
} IMAxis;
   
    
/**
 Designate different types of motion readings
 */
typedef enum : NSUInteger {
    kIMMotionTypePosition = 1 << 0,
    kIMMotionTypeVelocity = 1 << 1,
    kIMMotionTypeAcceleration = 1 << 2
} IMMotionType;


/** Bitflags for describing a "hit" */
typedef enum : NSUInteger {
    kIMHitShakeAxisDescriptorNone = 0,
    kIMHitShakeAxisDescriptorXPositive = 1,
    kIMHitShakeAxisDescriptorXNegative = 2,
    kIMHitShakeAxisDescriptorYPositive = 4,
    kIMHitShakeAxisDescriptorYNegative = 8,
    kIMHitShakeAxisDescriptorZPositive = 16,
    kIMHitShakeAxisDescriptorZNegative = 32,
    
    kIMHitShakeAxisDescriptorGyroXPositive = 64,
    kIMHitShakeAxisDescriptorGyroXNegative = 128,
    kIMHitShakeAxisDescriptorGyroYPositive = 256,
    kIMHitShakeAxisDescriptorGyroYNegative = 512,
    kIMHitShakeAxisDescriptorGyroZPositive = 1024,
    kIMHitShakeAxisDescriptorGyroZNegative = 2048,
    
    kIMHitShakeAxisDescriptorPitchPositive = 4096,
    kIMHitShakeAxisDescriptorPitchNegative = 8192,
    kIMHitShakeAxisDescriptorRollPositive = 16384,
    kIMHitShakeAxisDescriptorRollNegative = 32768,
    kIMHitShakeAxisDescriptorYawPositive = 65536,
    kIMHitShakeAxisDescriptorYawNegative = 131072,
    
    
    kIMHitShakeAxisDescriptorX = kIMHitShakeAxisDescriptorXPositive | kIMHitShakeAxisDescriptorXNegative,
    kIMHitShakeAxisDescriptorY = kIMHitShakeAxisDescriptorYPositive | kIMHitShakeAxisDescriptorYNegative,
    kIMHitShakeAxisDescriptorZ = kIMHitShakeAxisDescriptorZPositive | kIMHitShakeAxisDescriptorZNegative,
    
    kIMHitShakeAxisDescriptorGyroX = kIMHitShakeAxisDescriptorGyroXPositive | kIMHitShakeAxisDescriptorGyroXNegative,
    kIMHitShakeAxisDescriptorGyroY = kIMHitShakeAxisDescriptorGyroYPositive | kIMHitShakeAxisDescriptorGyroYNegative,
    kIMHitShakeAxisDescriptorGyroZ = kIMHitShakeAxisDescriptorGyroZPositive | kIMHitShakeAxisDescriptorGyroZNegative,
    
    kIMHitShakeAxisDescriptorPitch = kIMHitShakeAxisDescriptorPitchPositive | kIMHitShakeAxisDescriptorPitchNegative,
    kIMHitShakeAxisDescriptorRoll = kIMHitShakeAxisDescriptorRollPositive | kIMHitShakeAxisDescriptorRollNegative,
    kIMHitShakeAxisDescriptorYaw = kIMHitShakeAxisDescriptorYawPositive | kIMHitShakeAxisDescriptorYawNegative,
    
    
    kIMHitShakeAxisDescriptorAnyTranslationalPositive = kIMHitShakeAxisDescriptorXPositive | kIMHitShakeAxisDescriptorYPositive | kIMHitShakeAxisDescriptorZPositive,
    kIMHitShakeAxisDescriptorAnyTranslationalNegative = kIMHitShakeAxisDescriptorXNegative | kIMHitShakeAxisDescriptorYNegative | kIMHitShakeAxisDescriptorZNegative,
    kIMHitShakeAxisDescriptorAnyTranslational = kIMHitShakeAxisDescriptorAnyTranslationalPositive | kIMHitShakeAxisDescriptorAnyTranslationalNegative,
    
    kIMHitShakeAxisDescriptorAnyGyroPositive = kIMHitShakeAxisDescriptorGyroXPositive | kIMHitShakeAxisDescriptorGyroYPositive | kIMHitShakeAxisDescriptorGyroZPositive,
    kIMHitShakeAxisDescriptorAnyGyroNegative = kIMHitShakeAxisDescriptorGyroXNegative | kIMHitShakeAxisDescriptorGyroYNegative | kIMHitShakeAxisDescriptorGyroZNegative,
    kIMHitShakeAxisDescriptorAnyGyro = kIMHitShakeAxisDescriptorAnyGyroPositive | kIMHitShakeAxisDescriptorAnyGyroNegative,
    
    kIMHitShakeAxisDescriptorAnyAttitudePositive = kIMHitShakeAxisDescriptorPitchPositive | kIMHitShakeAxisDescriptorRollPositive | kIMHitShakeAxisDescriptorYawPositive,
    kIMHitShakeAxisDescriptorAnyAttitudeNegative = kIMHitShakeAxisDescriptorPitchNegative | kIMHitShakeAxisDescriptorRollNegative | kIMHitShakeAxisDescriptorYawNegative,
    kIMHitShakeAxisDescriptorAnyAttitude = kIMHitShakeAxisDescriptorAnyAttitudePositive | kIMHitShakeAxisDescriptorAnyAttitudeNegative,
    
    kIMHitShakeAxisDescriptorAnyPositive = kIMHitShakeAxisDescriptorAnyTranslationalPositive | kIMHitShakeAxisDescriptorAnyGyroPositive |
    kIMHitShakeAxisDescriptorAnyAttitudePositive,
    
    kIMHitShakeAxisDescriptorAnyNegative = kIMHitShakeAxisDescriptorAnyTranslationalNegative | kIMHitShakeAxisDescriptorAnyGyroNegative |
    kIMHitShakeAxisDescriptorAnyAttitudePositive,
    
    kIMHitShakeAxisDescriptorAny = kIMHitShakeAxisDescriptorAnyPositive | kIMHitShakeAxisDescriptorAnyNegative | kIMHitShakeAxisDescriptorAnyAttitude
} IMHitShakeAxisDescriptor;

/// @}
    
#ifdef __cplusplus
}
#endif

/// @}


