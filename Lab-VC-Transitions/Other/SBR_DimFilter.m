//
//  SBR_DimFilter.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_DimFilter.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGFloat _SBR_FILTER1_FROM = 1;
static const CGFloat _SBR_FILTER1_TO = 0.1;
static const CGFloat _SBR_FILTER2_FROM = 0;
static const CGFloat _SBR_FILTER2_TO = 0;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_DimFilter
{
    GPUImageSaturationFilter *_filter1;
    GPUImageGaussianBlurFilter *_filter2;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _filter1 = [[GPUImageSaturationFilter alloc] init];
        _filter2 = [[GPUImageGaussianBlurFilter alloc] init];
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
    
    // Linear Map to our ranges
    _filter1.saturation =
    filterAmount * (_SBR_FILTER1_TO - _SBR_FILTER1_FROM) + _SBR_FILTER1_FROM;
    _filter2.blurRadiusInPixels =
    filterAmount * (_SBR_FILTER2_TO - _SBR_FILTER2_FROM) + _SBR_FILTER2_FROM;
}

@end
