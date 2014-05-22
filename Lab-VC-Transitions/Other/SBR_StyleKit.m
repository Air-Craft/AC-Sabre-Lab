//
//  SBR_StyleKit.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_StyleKit.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGFloat _SBR_PANEL_ANIM_Y = 210;
static const CGFloat _SBR_PANEL_ANIM_Z = 300;
static const CGFloat _SBR_PANEL_ANIM_ANGLE = 120;
static const CGFloat _SBR_PANEL_ANIM_PERSPECTIVE = 300;

static const CGFloat _SBR_MENU_ANIM_X = 120;
static const CGFloat _SBR_MENU_ANIM_Z = 800;
static const CGFloat _SBR_MENU_ANIM_Z_FROM = 800;
static const CGFloat _SBR_MENU_ANIM_Z_TO = 100;
static const CGFloat _SBR_MENU_ANIM_ANGLE = 90;
static const CGFloat _SBR_MENU_ANIM_PERSPECTIVE = 200;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


@implementation SBR_StyleKit

+ (UIColor *)backgroundColor
{
    return [UIColor blackColor];
}

+ (UIImage *)swipeUpIcon
{
    return [UIImage imageNamed:@"icon-swipe"];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Derived Values
/////////////////////////////////////////////////////////////////////////

+ (CATransform3D)menuTransitionPanelTransformForAmount:(CGFloat)amount
{
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DTranslate(transform, 0, _SBR_PANEL_ANIM_Y * amount, _SBR_PANEL_ANIM_Z * amount);
    transform.m34 = -1.0 / _SBR_PANEL_ANIM_PERSPECTIVE;
    transform = CATransform3DRotate(transform, _SBR_PANEL_ANIM_ANGLE * amount * M_PI / 180.0f, 1, 0, 0);
    return transform;
}

//---------------------------------------------------------------------

+ (CATransform3D)menuTransitionMenuTransformForAmount:(CGFloat)amount
{
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DTranslate(transform, _SBR_MENU_ANIM_X * amount, 0, _SBR_MENU_ANIM_Z*(1-amount)+1);
    transform.m34 = -1.0 / _SBR_MENU_ANIM_PERSPECTIVE;
    transform = CATransform3DRotate(transform, -_SBR_MENU_ANIM_ANGLE * amount * M_PI / 180.0f, 0, 1, 0);
    return transform;

}

@end
