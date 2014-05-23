//
//  SBR_MenuTransitionUXController.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBR_InstrumentVC.h"
#import "SBR_MenuTransitionAnimator.h"


@interface SBR_MenuTransitionController : NSObject

+ (instancetype)newWithContainerVC:(UIViewController *)containerVC
                          animator:(SBR_MenuTransitionAnimator *)animator;



@end
