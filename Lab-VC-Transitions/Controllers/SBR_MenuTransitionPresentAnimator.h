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

@interface SBR_MenuTransitionPresentAnimator : NSObject

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithContainerView:(UIView *)containerView
                instrumentViewFilter:(SBR_CompositeGPUFilterAbstract *)instrumentViewFilter
                presentingViewFilter:(SBR_CompositeGPUFilterAbstract *)presentingViewFilter;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

/** Set to the snapshot view equivalent of the instrument view.  Needed by the DismissAnimator */
@property (nonatomic, readonly) UIView *frozenBGSnapshotView;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

- (void)beginTransitionToView:(UIView *)presentingView;

- (void)updateWithPercent:(CGFloat)percent;

/** Cancel the transition and revert back to previous state */
- (void)abortAndRevert;

/** Finishes the animations with completion callback */
- (void)finishWithCompletion:(void(^)(void))completion;




@end
