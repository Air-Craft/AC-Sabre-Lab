/**
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 31/10/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{
 */
/// \file IMHitDetectorDelegate.h


#import <Foundation/Foundation.h>
#import "IMDefs.h"

@protocol IMPluckDetectorDelegate <NSObject>

/** Pluck event.  Velocity is normalised 0..1.  WARNING: This is triggered on the MotionAnalyzer's Control Thread.  I think that was necessary originally to keep close to the audio engine. */
- (void)pluckDidOccurForZoneIndex:(NSUInteger)zoneIndex withVelocity:(IMMotionUnit)velocity;


@end

/// @}

