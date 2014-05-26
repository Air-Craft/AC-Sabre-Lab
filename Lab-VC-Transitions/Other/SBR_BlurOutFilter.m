//
//  SBR_BlurInFilter.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 25/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_BlurOutFilter.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGFloat _SBR_FILTER1_FROM = 0.001;
static const CGFloat _SBR_FILTER1_TO = 0.1;
//static const CGFloat _SBR_FILTER2_FROM = 0.1;
//static const CGFloat _SBR_FILTER2_TO = 0.00001;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_BlurOutFilter

{
    GPUImagePixellateFilter *_filter1;
//    GPUImagePixellateFilter *_filter2;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _filter1 = [[GPUImagePixellateFilter alloc] init];
        _filter1.fractionalWidthOfAPixel = _SBR_FILTER1_FROM;
        
//        _filter2 = [[GPUImagePixellateFilter alloc] init];
//        [_filter1 addTarget:_filter2];
    }
    return self;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Abstract Fulfillment
/////////////////////////////////////////////////////////////////////////

- (GPUImageFilter *)inputFilter { return _filter1; }
- (GPUImageFilter *)outputFilter { return _filter1; }

//---------------------------------------------------------------------

@synthesize filterAmount=_filterAmount;

- (void)setFilterAmount:(CGFloat)filterAmount
{
    _filterAmount = filterAmount;
    
    // Linear Map to our ranges
    _filter1.fractionalWidthOfAPixel =
    filterAmount * (_SBR_FILTER1_TO - _SBR_FILTER1_FROM) + _SBR_FILTER1_FROM;
    
//    _filter2.fractionalWidthOfAPixel =
//    filterAmount * (_SBR_FILTER2_TO - _SBR_FILTER2_FROM) + _SBR_FILTER2_FROM;
}


@end
