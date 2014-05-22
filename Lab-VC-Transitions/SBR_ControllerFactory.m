//
//  SBR_Factory.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_ControllerFactory.h"

#import "SBR_MenuTransitionPresentAnimator.h"
#import "SBR_MenuTransitionDismissAnimator.h"
#import "SBR_MenuTransitionMenuFilter.h"

@implementation SBR_ControllerFactory
{
    SBR_InstrumentVC *_instrumentVC;
    SBR_MenuTransitionController *_menuTransitionController;
    
    SBR_MenuNavVC *_menuNavVC;
}
    
/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [self new];
    });
    return shared;
}

//---------------------------------------------------------------------

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // Allocate the ones we need available always
        _instrumentVC = [SBR_InstrumentVC instrumentVC];
    }
    return self;
}

//---------------------------------------------------------------------

- (void)setMainVC:(SBR_MainVC *)mainVC
{
    _mainVC = mainVC;
    
    // Link in the menu transition controller
    [self menuTransitionController];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Controllers
/////////////////////////////////////////////////////////////////////////

- (void)releaseMemory
{
    _menuNavVC = nil;
}

//---------------------------------------------------------------------

- (SBR_InstrumentVC *)instrumentVC
{
    return _instrumentVC;
}

//---------------------------------------------------------------------

- (SBR_MenuNavVC *)menuNavVC
{
    if (!_menuNavVC) _menuNavVC = [SBR_MenuNavVC menuNavVC];
    return _menuNavVC;
}

//---------------------------------------------------------------------

- (SBR_MenuTransitionController *)menuTransitionControllerWithContainerVC
{
    NSParameterAssert(self.mainVC);
    
    if (_menuTransitionController) {
        // Construct the animators first. They share a GPU filter
        SBR_MenuTransitionMenuFilter *filter = [SBR_MenuTransitionMenuFilter new];
        SBR_MenuTransitionPresentAnimator *presentAnim = [SBR_MenuTransitionPresentAnimator newWithMenuFilter:filter];
        SBR_MenuTransitionDismissAnimator *dismissAnim = [SBR_MenuTransitionDismissAnimator newWithMenuFilter:filter];
        
        _menuTransitionController = [SBR_MenuTransitionController newWithContainerVC:self.mainVC
                                                                     presentAnimator:presentAnim
                                                                     dismissAnimator:dismissAnim];
    }
    return _menuTransitionController;
}



//---------------------------------------------------------------------


@end
