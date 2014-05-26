//
//  IMProtocols.h
//  SoundWand
//
//  Created by Hari Karam Singh on 14/08/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMDefs.h"
#import "IMMotionData.h"

/**
 \ingroup   InstrumentMotion
 \brief     Defines requirements for any class to be an observer on IMMotionAnalyzer
 */
@protocol IMMotionObserverProtocol <NSObject>

/// Receives motion data updates at the polling rate * oversampling ratio
- (void)handleMotionUpdateForData:(IMMotionSampleSet)current previousData:(IMMotionSampleSet)previous;

@optional

/// Optional.  Reported by the MA when added.  The value takes into account oversampling
- (void)handleMotionObserverAddedWithSampleRate:(NSTimeInterval)aSampleRate;

/// Optional.  Called immediately after removal from motionanalyzer; 
- (void)handleMotionObserverRemoved;


/// Sent by IMMotionAnalyzer when reset is called on it.  Use to clear latches and stored data that may no longer be relevant (eg on a re-engage after disengage)
- (void)reset;

@end
