//
//  SBR_MenuTransitionUXController.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBR_InstrumentVC.h"
#import "SBR_MenuTransitionPresentAnimator.h"
#import "SBR_MenuTransitionDismissAnimator.h"
#import "SBR_MainVC.h"


@interface SBR_MenuTransitionController : NSObject

+ (instancetype)newWithContainerVC:(UIViewController *)containerVC
                   presentAnimator:(SBR_MenuTransitionPresentAnimator *)presentAnimator
                   dismissAnimator:(SBR_MenuTransitionDismissAnimator *)dismissAnimator;



@end
