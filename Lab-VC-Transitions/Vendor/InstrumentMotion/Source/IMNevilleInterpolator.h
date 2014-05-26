//
//  IMPolynomialExtrapolator.h
//  InstrumentMotion
//
//  Created by Hari Karam Singh on 26/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <tgmath.h>

typedef enum {
    IMNevilleInterpolatorLinear = 1u,
    IMNevilleInterpolatorQuadratic = 2u,
    IMNevilleInterpolatorCubic = 3u,
    IMNevilleInterpolatorQuartic = 4u,
} IMNevilleInterpolatorDegree;


@interface IMNevilleInterpolator : NSObject {
    double x[6];                    //< Ring buffer for the samples.  Should need 4 at most for quadratic
    double y[6];
    NSUInteger ringIdx;             //< Idx of the first sample sequentially and the one which the NEXT data sample will replace.
    NSUInteger sampleCountCheck;   //< Safety latch, counts samples collected until the number required for the degree is collected.  
    IMNevilleInterpolatorDegree degree;
}

@property (nonatomic, readonly) BOOL hasSufficientData;

- (id)initWithDegree:(IMNevilleInterpolatorDegree)theDegree;


- (void)addSampleX:(double)theX andY:(double)theY;


- (double)interpolatedYAtX:(double)theX;

@end
