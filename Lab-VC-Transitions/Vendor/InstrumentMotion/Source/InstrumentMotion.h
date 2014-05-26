/**
 \defgroup  InstrumentMotion
 \brief     Advanced motion analysis using CoreMotion primarily to detect musical instrument gestures.
 
 \section DEV NOTES
 - 0 is considered positive where relevant (ie sign change detection)
 
 */

/**
 \file      InstrumentMotion.h
 \ingroup   InstrumentMotion
 \brief     Public header file - to be used externally, by the client, only.
 */
#import "IMDefs.h"
#import "IMFunctions.h"
#import "IMMotionObserverProtocol.h"
#import "IMMotionAnalyzer.h"
#import "IMPluckDetectorDelegate.h"
#import "IMPluckDetector.h"
#import "IMHitShakeDetectorDelegate.h"
#import "IMHitShakeDetector.h"
#import "IMAttitudeZoneDetectorDelegate.h"
#import "IMAttitudeZoneDetector.h"
#import "IMTimeAveragedMagnitudeDetector.h"