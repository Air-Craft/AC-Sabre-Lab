//
//  SBR_MenuTransitionDismissAnimator.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBR_CompositeGPUFilterAbstract.h"

@interface SBR_MenuTransitionDismissAnimator : NSObject


+ (instancetype)newWithContainerView:(UIView *)containerView
                instrumentViewFilter:(SBR_CompositeGPUFilterAbstract *)instrumentViewFilter
                 presentedViewFilter:(SBR_CompositeGPUFilterAbstract *)presentedViewFilter;


- (void)dismissWithCompletion:(void(^)(void))completion;

@end
