//
//  SBR_MenuRevealAnimation.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

@import UIKit;

#import "SBR_InstrumentVC.h"
#import "SBR_CompositeGPUFilterAbstract.h"

/** Not the AnimController new to iOS7 but a custom object used specifically by the ModalTransitionController */
@interface SBR_ModalTransitionAnimator : NSObject

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithContainerView:(UIView *)containerView
                instrumentViewFilter:(SBR_CompositeGPUFilterAbstract *)instrumentViewFilter
                 presentedViewFilter:(SBR_CompositeGPUFilterAbstract *)presentedViewFilter;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

/** Interactive presentation */
- (void)beginPresentingView:(UIView *)presentedView;

/** Update interactive presentation */
- (void)updatePresentingWithPercent:(CGFloat)percent;

/** Cancel the transition and revert back to previous state */
- (void)abortPresentingAndRevert;

/** Finishes the animations with completion callback */
- (void)finishPresentingWithCompletion:(void(^)(void))completion;

/** Non-interactive dismiss */
- (void)dismissWithCompletion:(void(^)(void))completion;


@end
