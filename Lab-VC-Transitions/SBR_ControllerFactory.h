//
//  SBR_Factory.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBR_MainVC.h"
#import "SBR_SettingsNavVC.h"
#import "SBR_SettingsTopMenuVC.h"
#import "SBR_ModalTransitionController.h"
#import "SBR_ModalTransitionAnimator.h"

#import "SBR_InteractiveSwipeGestureRecognizer.h"


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

/** One purpose and it's not DI or IOC etc. It's just to keep everything as flat as is prudent without cluttering up VC inits with construction code */
@interface SBR_ControllerFactory : NSObject

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)sharedInstance;

/** Need this to be set before we can do much else */
@property (nonatomic, weak) SBR_MainVC *mainVC;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Controller
/////////////////////////////////////////////////////////////////////////

- (SBR_InstrumentVC *)instrumentVC;
- (SBR_SettingsNavVC *)settingsNavVC;
- (SBR_SettingsTopMenuVC *)settingsTopMenuVC;

- (SBR_ModalTransitionController *)menuTransitionController;



- (void)releaseMemory;

@end
