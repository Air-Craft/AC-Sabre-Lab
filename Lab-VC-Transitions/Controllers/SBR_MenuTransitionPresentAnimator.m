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

#import "SBR_StyleKit.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static SBR_ControllerFactory *Factory;
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
//    UIViewController *_containerVC;
//    SBR_InstrumentVC *_instrumentVC;
//    UIViewController *_menuVC;
    GPUImageView *_menuSnapshotView;
    GPUImagePicture *_snapshotPicture;
    
    SBR_MenuTransitionDirection _direction;
    CGFloat _percentTransitioned;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithMenuFilter:(SBR_MenuTransitionMenuFilter *)menuFilter
{
    SBR_MenuTransitionPresentAnimator *me = [[self alloc] init];
    if (me) {
        [me _setup];
        Factory = [SBR_ControllerFactory sharedInstance];
    }
    return me;
}

//---------------------------------------------------------------------

- (void)_setup
{
    _menuSnapshotView = [[GPUImageView alloc] initWithFrame:Factory.mainVC.view.frame];
    [_blurFilter addTarget:_menuSnapshotView];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

- (void)begin
{
}

//---------------------------------------------------------------------

- (void)updateWithPercent:(CGFloat)percent
{
    _percentTransitioned = percent;
    
    // Move the panel down in 3D
    Factory.instrumentVC.panelView.layer.transform = [SBR_StyleKit menuTransitionPanelTransformForAmount:percent];
}

//---------------------------------------------------------------------
//
- (void)endWithAbort:(BOOL)abort completion:(void (^)(void))completion
{
    // Panel either animated the rest of the way down or back to the original position
    CATransform3D panelTransform = [SBR_StyleKit menuTransitionPanelTransformForAmount:(abort ? 0 : 1)];
    
    CABasicAnimation *panelAnim = [CABasicAnimation animationWithKeyPath: @"transform"];
    panelAnim.fillMode = kCAFillModeForwards;
    panelAnim.removedOnCompletion = NO;
    panelAnim.toValue = [NSValue valueWithCATransform3D:panelTransform];
    panelAnim.duration = _SBR_ANIM_STAGE2_TIME * (1 - _percentTransitioned);
    panelAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_instrumentVC.panelView.layer addAnimation:panelAnim forKey:@"transform"];
    
    /////////////////////////////////////////
    // MENU VIEW
    /////////////////////////////////////////
    
    // Grab a snapshot, initialize its effects and add it to the view
    UIImage *snapshotImage;
    UIGraphicsBeginImageContext(_menuVC.view.frame.size);
    {
        [_menuVC.view drawViewHierarchyInRect:_menuVC.view.frame afterScreenUpdates:YES];
        snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    // Use GPUImageView for convenience with animating the blur
    if (!_blurFilter) _blurFilter = [[_SBR_FILTER_TYPE alloc] init];
    if (!_menuSnapshotView) _menuSnapshotView = [[GPUImageView alloc] initWithFrame:_menuVC.view.frame];
    
    
    
    _menuSnapshotView.opaque = NO;
    _snapshotPicture = [[GPUImagePicture alloc] initWithImage:snapshotImage];
    [_snapshotPicture addTarget:_blurFilter];
    //        [_snapshotPicture processImage];
    
    
    [_containerVC addChildViewController:_menuVC];
    [_containerVC.view addSubview:_menuSnapshotView];
    
    POPBasicAnimation *anim = [POPBasicAnimation easeOutAnimation];
    anim.fromValue = @(_SBR_MENU_ANIM_FILTER_FROM);
    anim.toValue = @(_SBR_MENU_ANIM_FILTER_TO);
    anim.duration = _SBR_ANIM_STAGE2_TIME;
    
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"co.air-craft.blurAmount" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.readBlock = ^(id obj, CGFloat values[]) {
            values[0] = [_blurFilter blurSize];
        };
        // write value
        prop.writeBlock = ^(id obj, const CGFloat values[]) {
            [_blurFilter setBlurSize:values[0]];
            [_snapshotPicture processImage];
        };
    }];
    anim.property = prop;
    [self pop_addAnimation:anim forKey:@"co.air-craft.blurInAnim"];
    
    
    // ANIMATION: ANGLE-PAN IN
    CABasicAnimation *menuAnim = [CABasicAnimation animationWithKeyPath: @"transform"];
    menuAnim.fillMode = kCAFillModeForwards;
    menuAnim.removedOnCompletion = NO;
    menuAnim.fromValue = [NSValue valueWithCATransform3D:[self _menuTransformForPercent:1]];
    menuAnim.toValue = [NSValue valueWithCATransform3D:[self _menuTransformForPercent:0]];
    menuAnim.duration = _SBR_ANIM_STAGE2_TIME;
    menuAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [_menuSnapshotView.layer addAnimation:menuAnim forKey:@"transform"];
    
    
    // ANIMATION: FADE IN
    CABasicAnimation *fadeAnim = [CABasicAnimation animationWithKeyPath: @"opacity"];
    fadeAnim.fillMode = kCAFillModeForwards;
    fadeAnim.removedOnCompletion = NO;
    fadeAnim.fromValue = @(0);
    fadeAnim.toValue = @(1.0);
    fadeAnim.duration = _SBR_ANIM_STAGE2_TIME;
    fadeAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [_menuSnapshotView.layer addAnimation:fadeAnim forKey:@"opacity"];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////


@end
