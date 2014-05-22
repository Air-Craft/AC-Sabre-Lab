//
//  SBR_MenuTransitionMenuFilter.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_MenuTransitionMenuFilter.h"

/** NOTE, you need to change the property assignments below too! */
typedef GPUImageMotionBlurFilter _SBR_FILTER_TYPE;
static const CGFloat _SBR_MENU_ANIM_FILTER_FROM = 20;
static const CGFloat _SBR_MENU_ANIM_FILTER_TO = 0;

@implementation SBR_MenuTransitionMenuFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _gpuFilter = [[_SBR_FILTER_TYPE alloc] init];
    }
    return self;
}

//---------------------------------------------------------------------

- (void)setFilterAmount:(CGFloat)filterAmount
{
    _filterAmount = filterAmount;
    
    // Linear Map to our range
    CGFloat to = _SBR_MENU_ANIM_FILTER_TO,
            from = _SBR_MENU_ANIM_FILTER_FROM;
    
    CGFloat filterValue = filterAmount * (to-from) + from;
    [(_SBR_FILTER_TYPE *)_gpuFilter setBlurSize:filterValue];
}

@end
