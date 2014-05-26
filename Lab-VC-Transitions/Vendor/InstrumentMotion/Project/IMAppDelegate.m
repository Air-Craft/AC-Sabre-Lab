//
//  IMAppDelegate.m
//  InstrumentMotion
//
//  Created by Hari Karam Singh on 24/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IMAppDelegate.h"
#import "PerformanceThread.h"
#import "InstrumentMotionDebug.h"


@implementation IMAppDelegate
{
    IMMotionAnalyzer *ima;
    IMHitShakeDetector *hsd;
    IMAttitudeZoneDetector *zd;
    IMTimeAveragedMagnitudeDetector *_timeAverager;
    IMAxis _timeAveragerAxisBitmask;
    IMMotionType _timeAveragerMotionType;
}

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    InstrumentMotionDebugLogLevel = kIMDebugLogLevelAll;
    
    /////////////////////////////////////////
    // INSTRUMENT MOTION SETUP
    /////////////////////////////////////////

    PerformanceThread *thread = [PerformanceThread thread];
    ima = [[IMMotionAnalyzer alloc] initWithPollingInterval:0.02 oversamplingRatio:1 attitudeReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical controlThread:thread];
    
    hsd = [[IMHitShakeDetector alloc] init];
    hsd.activeHitAxes = kIMHitShakeAxisDescriptorAnyGyro;
    hsd.delegate = self;
//[ima addDetector:hsd];

    zd = [[IMAttitudeZoneDetector alloc] init];
    zd.minYaw = -M_PI_2;
    zd.maxYaw = M_PI_2;
    zd.pitchZones = 2;      // hemispheres
    zd.yawZones = 5;
    zd.rollZones = 1;
    zd.delegate = self;
    //[ima addDetector:zd];
    
    _timeAverager = [IMTimeAveragedMagnitudeDetector new];
    _timeAveragerAxisBitmask = kIMAxisPitch | kIMAxisYaw;
    _timeAveragerMotionType = kIMMotionTypeVelocity;
    
    [_timeAverager setDetectionForAxis:_timeAveragerAxisBitmask motionType:_timeAveragerMotionType timeWindow:5.0];
    __weak id ws = self;
    _timeAverager.onUpdateBlock = ^(IMTimeAveragedMagnitudeDetector *s) { [ws _handleTimeAveragerUpdate]; };
    [ima addDetector:_timeAverager];
    
    //[ima addMotionObserver:self];
    
    [ima engage];
    [thread start];
    
    
    return YES;
}

- (void)_handleTimeAveragerUpdate
{
    IMLOGf([_timeAverager normalizedValueForDetectionAxis:_timeAveragerAxisBitmask motionType:_timeAveragerMotionType]);
}

- (void)handleMotionUpdateForData:(IMMotionSampleSet)current
                     previousData:(IMMotionSampleSet)previous
{
    //[self _showSignChanges:current];
    
    /*if (current.attitude.vel.pitchSC != kIMMotionDirectionNone && current.attitude.accel.pitch > 0.5) {
        NSLog(@"SWITCH: Pitch");
    }
*///
    /*static IMMotionUnit mx=0, my=0, mz=0;
    if (fabs(current.attitude.accel.x) > mx) {
        mx = fabs(current.attitude.accel.x);
        NSLog(@"X! %+-8.1f", mx);
    }

    if (fabs(current.attitude.accel.y) > my) {
        my = fabs(current.attitude.accel.y);
        NSLog(@"Y! %+-8.1f", my);
    }
        
    if (fabs(current.attitude.accel.z) > mz) {
        mz = fabs(current.attitude.accel.z);
        NSLog(@"Z! %+-8.1f", mz);
    }*/

       
    
/*    NSLog(@"%+5.5f => %+5.5f",
          previous.attitude.vel.yaw,
          current.attitude.vel.yaw
          );*/
}

- (void)_showSignChanges:(IMMotionSampleSet)current
{
    if (current.attitude.velSC.roll != kIMSignNone) {
        NSLog(@"INITCH [YAW]: %+-8.1f", current.attitude.posDeltaSinceSC.roll * 180/M_PI);
    }

}

- (void)hitDidOccurWithAxisDescriptor:(IMHitShakeAxisDescriptor)anAxisDescriptor intensity:(IMMotionUnit)anIntensity
{
    IMLOG(@"HIT %@: %.3f", IM_GetStringForHitShakeAxisDescriptor(anAxisDescriptor), anIntensity);
}

- (void)didEnterNewAttititudeZoneWithIndicesForPitch:(NSInteger)pitchZoneIdx roll:(NSInteger)rollZoneIdx yaw:(NSInteger)yawZoneIdx
{
    IMLOG(@"New Zone: (%i, %i, %i)", pitchZoneIdx, rollZoneIdx, yawZoneIdx);
}

- (void)didEnterOrExitBoundaryWithExitStatesForPitch:(IMMotionUnit)pitchBoundarySign roll:(IMMotionUnit)rollBoundarySign yaw:(IMMotionUnit)yawBoundarySign
{
    IMLOG(@"Boundary Crossed (%+.1f, %+.1f, %+.1f)", pitchBoundarySign, rollBoundarySign, yawBoundarySign);
}

@end
