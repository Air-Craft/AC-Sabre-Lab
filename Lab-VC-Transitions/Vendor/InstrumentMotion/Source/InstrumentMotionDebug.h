/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 08/11/2012.
 \copyright  Copyright (c) 2012 Club 15CC. All rights reserved.
 @{ 
 */
/// \file InstrumentMotionDebug.h


/////////////////////////////////////////////////////////////////////////
#pragma mark - Debug Output Control
/////////////////////////////////////////////////////////////////////////

/** @name  md3 Marshmallow Debug Output Control
 
 Extern constants for controlling internal log output.  Defaults to none but can be set in a separate linkage unit via the extern MarshmallowDebugLogLevel.  Constants are bitwise, ie you can have RealTime w/o Info and Details
 */


typedef enum {
    kIMDebugLogLevelNone = 0,
    kIMDebugLogLevelWarn = 1 << 0,
    kIMDebugLogLevelInfo = 1 << 1,
    kIMDebugLogLevelDetail = 1 << 2,
    kIMDebugLogLevelRealTime = 1 << 3,
    kIMDebugLogLevelAll = kIMDebugLogLevelWarn |
    kIMDebugLogLevelInfo |
    kIMDebugLogLevelDetail |
    kIMDebugLogLevelRealTime
} IMDebugLogLevelType;

extern IMDebugLogLevelType InstrumentMotionDebugLogLevel;



/**
 These are for internal use primarily
 */
#define IMLogWarn(fmt, ...) { \
if (InstrumentMotionDebugLogLevel & kIMDebugLogLevelWarn) { \
NSLog((@"[IM_WARN!!] " fmt), ##__VA_ARGS__); \
} \
}

#define IMLogInfo(fmt, ...) { \
if (InstrumentMotionDebugLogLevel & kIMDebugLogLevelInfo) { \
NSLog((@"[IM_INFO] " fmt), ##__VA_ARGS__); \
} \
}

#define IMLogDetail(fmt, ...) { \
if (InstrumentMotionDebugLogLevel & kIMDebugLogLevelDetail) { \
NSLog((@"[IM_DETAIL] " fmt), ##__VA_ARGS__); \
} \
}

#define IMLogRealTime(fmt, ...) { \
if (InstrumentMotionDebugLogLevel & kIMDebugLogLevelRealTime) { \
NSLog((@"[IM_REALTIME] " fmt), ##__VA_ARGS__); \
} \
}


#ifdef DEBUG
#	define IMLOG(fmt, ...) NSLog((@"%s [L%d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#   define IMLOGi(val) NSLog((@"%s [L%d] %i"), __PRETTY_FUNCTION__, __LINE__, (int)val);
#   define IMLOGf(val) NSLog((@"%s [L%d] %f"), __PRETTY_FUNCTION__, __LINE__, (float)val);
#   define IMLOGs(val) NSLog((@"%s [L%d] %@"), __PRETTY_FUNCTION__, __LINE__, val);
#   define IMLOGvi(varname, val) NSLog((@"%s [L%d] %s=%i"), __PRETTY_FUNCTION__, __LINE__, varname, (int)val);
#   define IMLOGvf(varname, val) NSLog((@"%s [L%d] %s=%f"), __PRETTY_FUNCTION__, __LINE__, varname, (float)val);
#   define IMLOGvs(varname, val) NSLog((@"%s [L%d] %s=%@"), __PRETTY_FUNCTION__, __LINE__, varname, val);
#else
#	define IMLOG(...)
#	define IMLOGi(...)
#	define IMLOGf(...)
#	define IMLOGs(...)
#	define IMLOGvi(...)
#	define IMLOGvf(...)
#	define IMLOGvs(...)
#endif


/// @}



/// @}