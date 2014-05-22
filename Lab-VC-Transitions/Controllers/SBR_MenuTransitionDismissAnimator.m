//
//  SBR_MenuTransitionDismissAnimator.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "GPUImage.h"
#import <POP.h>
#import "SBR_MenuTransitionDismissAnimator.h"

#import "SBR_ControllerFactory.h"
#import "SBR_InstrumentVC.h"
#import "SBR_MenuNavVC.h"

#import "SBR_AnimatedFilterSnapshotView.h"

#import "SBR_StyleKit.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static SBR_ControllerFactory *Factory;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_MenuTransitionDismissAnimator
{
    UIView *_containerView;
    UIView *_presentedView;
    SBR_CompositeGPUFilterAbstract *_instrumentViewFilter;
    SBR_CompositeGPUFilterAbstract *_presentedViewFilter;
    
    SBR_AnimatedFilterSnapshotView *_targetSnapshotView;
    
    CGFloat _percentTransitioned;
}

+ (instancetype)newWithContainerView:(UIView *)containerView
                instrumentViewFilter:(SBR_CompositeGPUFilterAbstract *)instrumentViewFilter
                 presentedViewFilter:(SBR_CompositeGPUFilterAbstract *)presentedViewFilter
{
    SBR_MenuTransitionDismissAnimator *me = [[self alloc] init];
    if (me) {
        me->_containerView = containerView;
        me->_instrumentViewFilter = instrumentViewFilter;
        me->_presentedViewFilter = presentedViewFilter;
        Factory = [SBR_ControllerFactory sharedInstance];
        [me _setup];
    }
    return me;
}



//---------------------------------------------------------------------

- (void)_setup
{
}


@end
