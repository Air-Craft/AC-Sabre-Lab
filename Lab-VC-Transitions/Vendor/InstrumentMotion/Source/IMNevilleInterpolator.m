//
//  IMPolynomialExtrapolator.m
//  InstrumentMotion
//
//  Created by Hari Karam Singh on 26/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IMNevilleInterpolator.h"

@implementation IMNevilleInterpolator

/** ********************************************************************/

- (id)initWithDegree:(IMNevilleInterpolatorDegree)theDegree 
{
    if (self = [super init]) {
        degree = theDegree;
    }
    return self;
}

/** ********************************************************************/

/// Default to quadratic for safety
- (id)init 
{
    return [self initWithDegree:IMNevilleInterpolatorQuadratic];
}

/** ********************************************************************/

- (BOOL)hasSufficientData 
{
    // Linear => degree = 1 => 2 samples reqd....
    return (sampleCountCheck >= degree + 1);
}

/** ********************************************************************/

- (void)addSampleX:(double)theX andY:(double)theY
{
    // Inc our safety check but conditionally to avoid overruns resetting back to 0
    if (sampleCountCheck <= degree) {
        sampleCountCheck++;
    }
    
    // Add the sample and update the buffer ring idx
    x[ringIdx] = theX;
    y[ringIdx] = theY;
    ringIdx = (ringIdx + 1) % (degree + 1);   // yields degree + 1 samples
}

/** ********************************************************************/

- (double)interpolatedYAtX:(double)theX
{
    // Neville algorithm...
    NSInteger i, iRing, imRing, m, ns = 0, N;           // N = number of Poly's in a column, ns marks where we are in the tree
    double dif = DBL_MAX, tmpDif;               // Used to get the nearest starting point to our request theX
    double denom, h_o, h_p, w;                  // Terms in the Neville equations
    double theY;                                // Return value;
    double dy;                                  // Delta Y on each round.  Final value can be used as an error estimate
    double *C, *D;                              // The key factors
 
    // Have we collected enough?
    if (!self.hasSufficientData) {
        [NSException raise:NSInternalInconsistencyException format:@"Must collect %u samples prior to interpolation.", degree + 1];
    }
    
    // Alloc and init the factors
    N = degree + 1;                             // required number of data samples
    C = malloc(sizeof(double) * N);
    D = malloc(sizeof(double) * N);
    if (!C || !D) {
        [NSException raise:NSMallocException format:@"Error allocating %lu bytes", sizeof(double)*N];
    }
    
    for (i = 0; i < N; i++) {
        
        iRing = (ringIdx + i) % (degree + 1);         // convert from our ring buffer idx
        C[i] = D[i] = y[iRing];                 // equivalent to move from m = 0 column (where P_i = 0) to m = 1
        
        // Find the closest X for a starting approx for the Y
        // ie, which "row" in the triangle we're beginning from (eg. always the last for extrapolation)
        if ( (tmpDif = fabs(theX - x[i])) < dif ) {
            ns = i;
            dif = tmpDif;
        }
    }
    
    // Starting approx
    theY = y[ns--];
    
    // Fill in the array of factors, C and D, 
    // Note we only need enough for the first column as they are recursive/culmulative and we recycle them...
    // Loop through each columns pair (cols - 1 = N - 1)
    for (m = 1; m < N; m++) {
        
        // Loop through the items in that column
        for (i = 0; i < (N - m); i++ ) {
            
            iRing = (ringIdx + i) % (degree + 1);         // convert from our ring buffer idx
            imRing = (i + m + ringIdx) % (degree + 1);
            h_o = x[iRing] - theX;
            h_p = x[imRing] - theX;
            
            w = C[i+1] - D[i];
            denom = h_o - h_p;
            if (denom == 0.0) {
                [NSException raise:NSInternalInconsistencyException format:@"Overflow error caused by two samples with equal x values (can't have it!)."];
            }
           // IMLOG("(m=%i, i=%i, iRing+m<=deg: %i+%i<=%i): x[i]=%f, x[i+m]=%f, C[i]: %f=>%f, D[i]: %f=>%f,", m, i, iRing, m, degree, x[iRing], x[iRing+m], C[i], h_o*w/denom, D[i], h_p*w/denom);
            C[i] = h_o * w / denom;
            D[i] = h_p * w / denom;
        }
        // Now update the estimate choosing C or D based on the straightest/most connected route through the triangle
        dy = (2 * (ns+1)) < (N - m) ? C[ns+1] : D[ns--];    
        theY += dy;
    }
    
    free(C);
    free(D);
                 
    return theY;
}

@end
