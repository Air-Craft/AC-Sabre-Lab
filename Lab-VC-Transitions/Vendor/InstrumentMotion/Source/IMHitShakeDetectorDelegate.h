/**
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 31/10/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{
 */
/// \file IMHitShakeDetectorDelegate.h


#import <Foundation/Foundation.h>
#import "IMDefs.h"

@protocol IMHitShakeDetectorDelegate <NSObject>

- (void)hitDidOccurWithAxisDescriptor:(IMHitShakeAxisDescriptor)anAxisDescriptor intensity:(IMMotionUnit)anIntensity;

- (void)shakeDidOccurWithAxisDescriptor:(IMHitShakeAxisDescriptor)anAxisDescriptor intensity:(IMMotionUnit)anIntensity;

@end


/// @}