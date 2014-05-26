/**
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 13/08/2011.
 \copyright  Copyright (c) 2012 Club 15CC. All rights reserved.
 @{
 */
/// \file IMConfig.h

/**  Conversion constants */
#define IM_DEG2RAD(deg) ((deg)*(M_PI/180.0))

/**  Conversion constants */
#define IM_RAD2DEG(deg) ((deg)*(180.0/M_PI))


/////////////////////////////////////////////////////////////////////////
#pragma mark - MotionAnalyzer Constants
/// @name MotionAnalyzer Constants
/////////////////////////////////////////////////////////////////////////


/** Give time for the motion analyzer to settle in */
#define IM_FRAMES_TO_DELAY_BEFORE_REPORTING     5

/**
 Cap on attitude velocity for normalised velocity (0..1) reporting
 
 Anything above this is considered the same.
 In theory the limit is 2pi * sampling rate in Hz.
 But in practice much less sensitivity is likely to be required.
 */
#define IM_ATTITUDE_MAX_VELOCITY (M_PI/0.3f) // 180deg in 0.5 seconds


#define IM_MAX_VELOCITY_X 22
#define IM_MAX_VELOCITY_Y 22
#define IM_MAX_VELOCITY_Z 28

#define IM_MAX_VELOCITY_GYRO_X (M_PI/0.1)
#define IM_MAX_VELOCITY_GYRO_Y (M_PI/0.1)
#define IM_MAX_VELOCITY_GYRO_Z (M_PI/0.1)

#define IM_MAX_VELOCITY_PITCH (M_PI/0.1)
#define IM_MAX_VELOCITY_ROLL (M_PI/0.1)
#define IM_MAX_VELOCITY_YAW (M_PI/0.1)


#define IM_MAX_ACCELERATION_X 2.24
#define IM_MAX_ACCELERATION_Y 2.24
#define IM_MAX_ACCELERATION_Z 2.85

#define IM_MAX_ACCELERATION_GYRO_X 1000 //2000
#define IM_MAX_ACCELERATION_GYRO_Y 1000 //1500
#define IM_MAX_ACCELERATION_GYRO_Z 1000 //1400

#define IM_MAX_ACCELERATION_PITCH 1000  //1500
#define IM_MAX_ACCELERATION_ROLL 1000   //1500
#define IM_MAX_ACCELERATION_YAW 1000    //1500




/** Used to remove DC offset (in Hz) from the *acceleration* (which is usually wobbly just by its nature). */
#define IM_ACCELEROMETER_HIPASS_FILTER_FREQ 0.1

#define IM_WRAP_AROUND_DETECTION_VELOCITY_THRESHOLD 85.0f

#define IM_DUPLICATE_THRESHOLD 0.0000001f

/// @}



/////////////////////////////////////////////////////////////////////////
#pragma mark - Pluck Detector
/////// @name  Pluck Detector
/////////////////////////////////////////////////////////////////////////

/**
 A safety threshold to prevent crossing of the -PI/+PI boundary
 causing all zones to be plucked
 
 Attitude velocities greater than this will cause a reset.  The fastest I could create w/o crossing the boundary was 50.  The lowest I created crossing the boundary was 160.
 */
#define IM_PD_VELOCITY_SAFETY_THRESHOLD 85.0f

/** Yaw goes nuts when pitch is +-PI so limit the pitch range for which we'll bother detecting plucks when the pluck axis is set to yaw */
#define IM_PD_MIN_PITCH_FOR_YAW_PLUCK (-60 * M_PI / 180.)
#define IM_PD_MAX_PITCH_FOR_YAW_PLUCK (80 * M_PI / 180.)

/** The angle through which you need to transverse to register a string pluck.  Related to Tao/sensitivity. When the pluck axis is "pitch" this is halved since pitch is +-PI/2 rather than +-PI */
#define IM_PD_PLUCK_THROUGH_ANGLE_RADIUS        (1 * M_PI/180.0)



/// @}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Hit/Shake Detector
/////// @name  Hit/Shake Detector
/////////////////////////////////////////////////////////////////////////
#define IM_HITSHAKE_DELTA_TIME_THRESHOLD 0.05

#define IM_HITSHAKE_DELTA_ANGLE_THRESHOLD_FOR_MIN_INTENSITY_HIT (3.0 * M_PI/180.0)
#define IM_HITSHAKE_DELTA_ANGLE_THRESHOLD_FOR_MAX_INTENSITY_HIT (8.0 * M_PI/180.0) 
#define IM_HITSHAKE_DELTA_VEL_THRESHOLD_FOR_MIN_INTENSITY_HIT 0.5
#define IM_HITSHAKE_DELTA_VEL_THRESHOLD_FOR_MAX_INTENSITY_HIT 1.25


/// @}





/// @}
