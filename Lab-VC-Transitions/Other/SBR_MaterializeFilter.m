//
//  SBR_MenuTransitionMenuFilter.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_MaterializeFilter.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGFloat _SBR_FILTER1_FROM = 20;
static const CGFloat _SBR_FILTER1_TO = 0;
static const CGFloat _SBR_FILTER2_FROM = 0.1;
static const CGFloat _SBR_FILTER2_TO = 0.00001;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_MaterializeFilter
{
    GPUImageMotionBlurFilter *_filter1;
    GPUImagePixellateFilter *_filter2;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _filter1 = [[GPUImageMotionBlurFilter alloc] init];
        [_filter1 setBlurAngle:90];
        
        _filter2 = [[GPUImagePixellateFilter alloc] init];
        [_filter1 addTarget:_filter2];
    }
    return self;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Abstract Fulfillment
/////////////////////////////////////////////////////////////////////////

- (GPUImageFilter *)inputFilter { return _filter1; }
- (GPUImageFilter *)outputFilter { return _filter2; }

//---------------------------------------------------------------------

@synthesize filterAmount=_filterAmount;

- (void)setFilterAmount:(CGFloat)filterAmount
{
    _filterAmount = filterAmount;
    
    // Linear Map to our range
    CGFloat to1 = _SBR_FILTER1_TO,
            from1 = _SBR_FILTER1_FROM,
            to2 = _SBR_FILTER2_TO,
            from2 = _SBR_FILTER2_FROM;
    
    // Linear Map to our ranges
    _filter1.blurSize =
    filterAmount * (_SBR_FILTER1_TO - _SBR_FILTER1_FROM) + _SBR_FILTER1_FROM;
    
    _filter2.fractionalWidthOfAPixel =
    filterAmount * (_SBR_FILTER2_TO - _SBR_FILTER2_FROM) + _SBR_FILTER2_FROM;
}

@end
