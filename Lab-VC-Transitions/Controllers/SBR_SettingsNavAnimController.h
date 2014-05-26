//
//  SBR_MenuDrilldownAnimation.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <UIKit/UIKit.h>

/** A proper iOS7+ AnimController. Handles both the interactive transitions as well as the single trigger ones.  Gesturing is handled in the NavC though. */
@interface SBR_SettingsNavAnimController : NSObject<UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning>

/** NO = single-trigger animation */
@property (nonatomic) BOOL isInteractive;

/** Push/pop */
@property (nonatomic) UINavigationControllerOperation operation;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Methods for Interactive Pop
/////////////////////////////////////////////////////////////////////////

/** For interactive transitions... */
- (void)updateWithPercent:(CGFloat)percent;

/** Gesture was cancelled/failed. Unwind with animation. */
- (void)abort;

- (void)finishWithCompletion:(void(^)(void))completion;


@end
