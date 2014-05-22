//
//  SBR_MenuRevealAnimation.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "GPUImage.h"
#import <POP.h>
#import "SBR_MenuTransitionPresentAnimator.h"

#import "SBR_ControllerFactory.h"
#import "SBR_InstrumentVC.h"
#import "SBR_MenuNavVC.h"

#import "SBR_AnimatedFilterSnapshotView.h"

#import "SBR_StyleKit.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static SBR_ControllerFactory *Factory;

static const NSTimeInterval _SBR_ANIM_INSTRUMENT_DIM_ALPHA = 0.4;   // in addition to the filter effects
static const NSTimeInterval _SBR_ANIM_STAGE2_TIME = 0.25;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@interface SBR_MenuTransitionPresentAnimator()

@property (nonatomic) CGFloat animPercent;

@end

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_MenuTransitionPresentAnimator
{
    UIView *_containerView;
    UIView *_presentingView;
    SBR_CompositeGPUFilterAbstract *_instrumentViewFilter;
    SBR_CompositeGPUFilterAbstract *_presentingViewFilter;
    
    SBR_AnimatedFilterSnapshotView *_presentingSnapshotView;
    
    CGFloat _percentTransitioned;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithContainerView:(UIView *)containerView
                instrumentViewFilter:(SBR_CompositeGPUFilterAbstract *)instrumentViewFilter
                presentingViewFilter:(SBR_CompositeGPUFilterAbstract *)presentingViewFilter
{
    SBR_MenuTransitionPresentAnimator *me = [[self alloc] init];
    if (me) {
        me->_containerView = containerView;
        me->_instrumentViewFilter = instrumentViewFilter;
        me->_presentingViewFilter = presentingViewFilter;
        Factory = [SBR_ControllerFactory sharedInstance];
        [me _setup];
    }
    return me;
}

//---------------------------------------------------------------------

- (void)_setup
{
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

- (void)beginTransitionToView:(UIView *)presentingView
{
    _presentingView = presentingView;
}

//---------------------------------------------------------------------

- (void)updateWithPercent:(CGFloat)percent
{
    _percentTransitioned = percent;
    
    // Move the panel down in 3D
    Factory.instrumentVC.panelView.layer.transform = [SBR_StyleKit menuTransitionPanelTransformForAmount:percent];
}

//---------------------------------------------------------------------

- (void)abortAndRevert
{
    if (_percentTransitioned == 0) return;
    
    // Panel either animated the rest of the way down or back to the original position
    CATransform3D panelTransform = [SBR_StyleKit menuTransitionPanelTransformForAmount:0];
    
    [UIView
     animateWithDuration:_SBR_ANIM_STAGE2_TIME * (1 - _percentTransitioned)
     animations:^{
         [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
         Factory.instrumentVC.panelView.layer.transform = panelTransform;
     }];
}

//---------------------------------------------------------------------

- (void)finishWithCompletion:(void (^)(void))completion
{
    /////////////////////////////////////////
    // PANEL DOWN COMPLETION
    /////////////////////////////////////////
    [UIView
     animateWithDuration:_SBR_ANIM_STAGE2_TIME * (1 - _percentTransitioned)
     animations:^{
        
         [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
         CATransform3D transform = [SBR_StyleKit menuTransitionPanelTransformForAmount:1];
         Factory.instrumentVC.panelView.layer.transform = transform;
        
     } completion:^(BOOL finished) {
         /////////////////////////////////////////
         // BG DIM & FADE
         /////////////////////////////////////////
         // Snapshot and dim...
         SBR_AnimatedFilterSnapshotView *view
         = [SBR_AnimatedFilterSnapshotView
            newWithSourceView:Factory.instrumentVC.view
            filter:_instrumentViewFilter
            initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view){
                [Factory.instrumentVC.view removeFromSuperview];
                [_containerView insertSubview:view belowSubview:_presentingSnapshotView];
                
                NSTimeInterval dur = _SBR_ANIM_STAGE2_TIME * _percentTransitioned;
                [view filterWithDuration:dur];
                
                // Also fade the view
                [UIView animateWithDuration:dur animations:^{
                    view.alpha = _SBR_ANIM_INSTRUMENT_DIM_ALPHA;
                }];
            }];
         
         // Public reference for later
         _frozenBGSnapshotView = view;
     }];
    

    /////////////////////////////////////////
    // MENU: FILTER ANIM
    /////////////////////////////////////////
    
    _presentingSnapshotView = [SBR_AnimatedFilterSnapshotView newWithSourceView:_presentingView filter:_presentingViewFilter initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view){
    }];
    [_containerView addSubview:_presentingSnapshotView];
    
    [_presentingSnapshotView filterWithDuration:_SBR_ANIM_STAGE2_TIME];
   
    
    /////////////////////////////////////////
    // MENU: CA ANIMS
    /////////////////////////////////////////
    _presentingSnapshotView.layer.transform = [SBR_StyleKit menuTransitionMenuTransformForAmount:1];
    _presentingSnapshotView.alpha = 0.0;
    
    [UIView animateWithDuration:_SBR_ANIM_STAGE2_TIME animations:^{
        // ANIMATION: ANGLE-PAN IN
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
        
        _presentingSnapshotView.alpha = 1.0;
        _presentingSnapshotView.layer.transform = [SBR_StyleKit menuTransitionMenuTransformForAmount:0];
        
    } completion:^(BOOL finished) {
        [self _handleTransitionAnimationCompleted];
        
        if (completion) completion();
    }];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_handleTransitionAnimationCompleted
{
    // Swap the presented view's snapshot for the real deal
    [_containerView addSubview:_presentingView];
    [_presentingSnapshotView removeFromSuperview];
    _presentingSnapshotView = nil;
}

@end
