//
//  SBR_MenuRevealAnimation.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

@import UIKit;

#import "SBR_InstrumentVC.h"
#import "SBR_MenuTransitionMenuFilter.h"

@interface SBR_MenuTransitionPresentAnimator : NSObject

+ (instancetype)newWithMenuFilter:(SBR_MenuTransitionMenuFilter *)menuFilter;

- (void)begin;

- (void)updateWithPercent:(CGFloat)percent;

- (void)endWithAbort:(BOOL)abort completion:(void(^)(void))completion;




@end
