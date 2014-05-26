//
//  SBR_MenuRevealAnimation.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "GPUImage.h"
#import <POP.h>
#import "SBR_ModalTransitionAnimator.h"

#import "SBR_ControllerFactory.h"
#import "SBR_InstrumentVC.h"
#import "SBR_SettingsTopMenuVC.h"

#import "SBR_AnimatedFilterSnapshotView.h"

#import "SBR_StyleKit.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static SBR_ControllerFactory *Factory;

static const CGFloat _SBR_PANEL_ANIM_Y = 210;
static const CGFloat _SBR_PANEL_ANIM_Z = 300;
static const CGFloat _SBR_PANEL_ANIM_ANGLE = 120;
static const CGFloat _SBR_PANEL_ANIM_PERSPECTIVE = 300;
static const CGFloat _SBR_ANIM_INSTRUMENT_DIM_ALPHA = 0.4;   // in addition to the filter effects

static const CGFloat _SBR_MENU_ANIM_X = 120;
static const CGFloat _SBR_MENU_ANIM_Z = 800;
static const CGFloat _SBR_MENU_ANIM_Z_FROM = 800;
static const CGFloat _SBR_MENU_ANIM_Z_TO = 100;
static const CGFloat _SBR_MENU_ANIM_ANGLE = 90;
static const CGFloat _SBR_MENU_ANIM_PERSPECTIVE = 200;

/** Timings */
static const NSTimeInterval _SBR_PRESENT_ANIM_STAGE2_TIME = 1.25;
static const NSTimeInterval _SBR_DISMISS_ANIM_STAGE1_TIME = 1.1;
static const NSTimeInterval _SBR_DISMISS_ANIM_STAGE2_TIME = 1.15;



/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@interface SBR_ModalTransitionAnimator()

@property (nonatomic) CGFloat animPercent;

@end

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_ModalTransitionAnimator
{
    UIView *_containerView;
    UIView *_presentedView;
    SBR_CompositeGPUFilterAbstract *_instrumentViewFilter;
    SBR_CompositeGPUFilterAbstract *_presentedViewFilter;
    
    SBR_AnimatedFilterSnapshotView *_presentedSnapshotView;
    SBR_AnimatedFilterSnapshotView *_frozenBGSnapshotView;
    
    CGFloat _percentTransitioned;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithContainerView:(UIView *)containerView
                instrumentViewFilter:(SBR_CompositeGPUFilterAbstract *)instrumentViewFilter
                presentedViewFilter:(SBR_CompositeGPUFilterAbstract *)presentedViewFilter
{
    SBR_ModalTransitionAnimator *me = [[self alloc] init];
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


////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

- (void)beginPresentingView:(UIView *)presentedView
{
    _presentedView = presentedView;
}

//---------------------------------------------------------------------

- (void)updatePresentingWithPercent:(CGFloat)percent
{
    _percentTransitioned = percent;
    
    // Move the panel down in 3D
    Factory.instrumentVC.panelView.layer.transform = [self _panelTransformForAmount:percent];
}

//---------------------------------------------------------------------

- (void)abortPresentingAndRevert
{
    if (_percentTransitioned == 0) return;
    
    // Panel either animated the rest of the way down or back to the original position
    CATransform3D panelTransform = [self _panelTransformForAmount:0];
    
    [UIView
     animateWithDuration:_SBR_PRESENT_ANIM_STAGE2_TIME * (1 - _percentTransitioned)
     animations:^{
         [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
         Factory.instrumentVC.panelView.layer.transform = panelTransform;
     }];
}

//---------------------------------------------------------------------

- (void)finishPresentingWithCompletion:(void (^)(void))completion
{
    /////////////////////////////////////////
    // PANEL DOWN COMPLETION
    /////////////////////////////////////////
    [UIView
     animateWithDuration:_SBR_PRESENT_ANIM_STAGE2_TIME * (1 - _percentTransitioned)
     animations:^{
        
         [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
         CATransform3D transform = [self _panelTransformForAmount:1];
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
                [_containerView insertSubview:view belowSubview:_presentedSnapshotView];
                
                NSTimeInterval dur = _SBR_PRESENT_ANIM_STAGE2_TIME * _percentTransitioned;
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
    
    _presentedViewFilter.filterAmount = 1.0;
    _presentedSnapshotView = [SBR_AnimatedFilterSnapshotView newWithSourceView:_presentedView filter:_presentedViewFilter initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view){
    }];
    [_containerView addSubview:_presentedSnapshotView];
    
    [_presentedSnapshotView unfilterWithDuration:_SBR_PRESENT_ANIM_STAGE2_TIME];
   
    
    /////////////////////////////////////////
    // MENU: CA ANIMS
    /////////////////////////////////////////
    _presentedSnapshotView.layer.transform = [self _presentedViewTransformForAmount:1];
    _presentedSnapshotView.alpha = 0.0;
    
    [UIView animateWithDuration:_SBR_PRESENT_ANIM_STAGE2_TIME animations:^{
        // ANIMATION: ANGLE-PAN IN
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
        
        _presentedSnapshotView.alpha = 1.0;
        _presentedSnapshotView.layer.transform = [self _presentedViewTransformForAmount:0];
        
    } completion:^(BOOL finished) {
        [self _handleTransitionAnimationCompleted];
        
        if (completion) completion();
    }];
}

//---------------------------------------------------------------------

- (void)dismissWithCompletion:(void (^)(void))completion
{
    // FADE IN BG
    [UIView animateWithDuration:_SBR_DISMISS_ANIM_STAGE1_TIME animations:^{
        _frozenBGSnapshotView.alpha = 1.0;
    }];
    
    // UNFILTER BG
    [_frozenBGSnapshotView unfilterWithDuration:_SBR_DISMISS_ANIM_STAGE1_TIME completion:^{
        
        // Swap out the snapshot for the real thing
        [_containerView insertSubview:Factory.instrumentVC.view belowSubview:_presentedView];
        [_frozenBGSnapshotView removeFromSuperview];
        
        // Now simultaneously do the panel 3d xform and anim out the
        // PANEL ANIM
        [UIView
         animateWithDuration:_SBR_PRESENT_ANIM_STAGE2_TIME
         animations:^{
             Factory.instrumentVC.panelView.layer.transform = [self _panelTransformForAmount:0];
         }];
        
        // MENU OUT: FILTER
        // Swap the menu for the snapshow
        _presentedViewFilter.filterAmount = 0.0;
        _presentedSnapshotView = [SBR_AnimatedFilterSnapshotView
                                   newWithSourceView:_presentedView
                                   filter:_presentedViewFilter
                                   initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view) {
                                       [_containerView addSubview:view];
                                       [_presentedView removeFromSuperview];
                                       _presentedView = nil; // no longer needed
                                   }];
        [_presentedSnapshotView filterWithDuration:_SBR_DISMISS_ANIM_STAGE2_TIME];
        
        
        // MENU OUT: GEOMETRY
        [UIView
         animateWithDuration:_SBR_DISMISS_ANIM_STAGE2_TIME
         animations:^{
             _presentedSnapshotView.layer.transform = [self _presentedViewTransformForAmount:1];
             _presentedSnapshotView.alpha = 0;
         }
         completion:^(BOOL finished) {
             
             // Remove the snapshot
             [_presentedSnapshotView removeFromSuperview];
             _presentedSnapshotView = nil;
             
             if (completion) completion();
         }];
        
    }]; // end unfilter
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_handleTransitionAnimationCompleted
{
    // Swap the presented view's snapshot for the real deal
    [_containerView addSubview:_presentedView];
    [_presentedSnapshotView removeFromSuperview];
    _presentedSnapshotView = nil;
}

//---------------------------------------------------------------------

/** 0 = untransformed, 1 = full transform  */
- (CATransform3D)_panelTransformForAmount:(CGFloat)amount
{
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DTranslate(transform, 0, _SBR_PANEL_ANIM_Y * amount, _SBR_PANEL_ANIM_Z * amount);
    transform.m34 = -1.0 / _SBR_PANEL_ANIM_PERSPECTIVE;
    transform = CATransform3DRotate(transform, _SBR_PANEL_ANIM_ANGLE * amount * M_PI / 180.0f, 1, 0, 0);
    return transform;
}

//---------------------------------------------------------------------

- (CATransform3D)_presentedViewTransformForAmount:(CGFloat)amount
{
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DTranslate(transform, _SBR_MENU_ANIM_X * amount, 0, _SBR_MENU_ANIM_Z*(1-amount)+1);
    transform.m34 = -1.0 / _SBR_MENU_ANIM_PERSPECTIVE;
    transform = CATransform3DRotate(transform, -_SBR_MENU_ANIM_ANGLE * amount * M_PI / 180.0f, 0, 1, 0);
    return transform;
    
}



@end
