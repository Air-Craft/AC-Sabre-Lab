//
//  SBR_MenuTransitionUXController.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBR_InstrumentVC.h"
#import "SBR_ModalTransitionAnimator.h"


@interface SBR_ModalTransitionController : NSObject

+ (instancetype)newWithContainerVC:(UIViewController *)containerVC
                          animator:(SBR_ModalTransitionAnimator *)animator;



@end
