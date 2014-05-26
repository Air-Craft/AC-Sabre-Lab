//
//  SBR_Factory.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_Factory.h"

#import "SBR_ModalTransitionAnimator.h"
#import "SBR_DimFilter.h"
#import "SBR_MaterializeFilter.h"

@implementation SBR_Factory
{
    SBR_InstrumentVC *_instrumentVC;
    SBR_ModalTransitionController *_menuTransitionController;
    
    SBR_SettingsNavVC *_settingsNavVC;
    SBR_SettingsTopMenuVC *_settingsTopMenuVC;
    
    MPerformanceThread *_controlThread;
    IMMotionAnalyzer *_motionAnalyzer;
    
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

//---------------------------------------------------------------------

- (void)releaseMemory
{
    _settingsNavVC = nil;
    _settingsTopMenuVC = nil;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Controllers
/////////////////////////////////////////////////////////////////////////

- (SBR_InstrumentVC *)instrumentVC
{
    return _instrumentVC;
}

//---------------------------------------------------------------------

- (SBR_SettingsNavVC *)settingsNavVC
{
//    NSParameterAssert(_mainVC);
    
    if (!_settingsNavVC) {
        _settingsNavVC = [[SBR_SettingsNavVC alloc] initWithRootViewController:[self settingsTopMenuVC]];
        _settingsNavVC.toolbarHidden = YES;
        _settingsNavVC.navigationBarHidden = YES;
        _settingsNavVC.view.frame = _mainVC.view.frame;
        
    }
    return _settingsNavVC;
}

//---------------------------------------------------------------------

- (SBR_SettingsTopMenuVC *)settingsTopMenuVC
{
    if (!_settingsTopMenuVC) {
        _settingsTopMenuVC = [SBR_SettingsTopMenuVC new];
    }
    return _settingsTopMenuVC;
}

//---------------------------------------------------------------------

- (SBR_ModalTransitionController *)menuTransitionController
{
    NSParameterAssert(self.mainVC);
    
    if (!_menuTransitionController) {
        // Construct the animators first. They share a GPU filter
        SBR_CompositeGPUFilterAbstract *menuFilter = [SBR_MaterializeFilter new];
        SBR_CompositeGPUFilterAbstract *instrumentFilter = [SBR_DimFilter new];
        
        SBR_ModalTransitionAnimator *animator =
        [SBR_ModalTransitionAnimator newWithContainerView:self.mainVC.view
                                           instrumentViewFilter:instrumentFilter
                                           presentedViewFilter:menuFilter];
        
        _menuTransitionController =
        [SBR_ModalTransitionController newWithContainerVC:self.mainVC
                                         animator:animator];
    }
    return _menuTransitionController;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Other Objects
/////////////////////////////////////////////////////////////////////////

- (MPerformanceThread *)controlThread
{
    if (!_controlThread) {
        _controlThread = [MPerformanceThread new];
        _controlThread.timingResolution = 0.01;
    }
    return _controlThread;
}

//---------------------------------------------------------------------

- (IMMotionAnalyzer *)motionAnalyzer
{
    if (!_motionAnalyzer) {
        _motionAnalyzer = [[IMMotionAnalyzer alloc] initWithPollingInterval:0.01 oversamplingRatio:1.0 attitudeReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical controlThread:(id<IMControlThreadProtocol>)self.controlThread];
    }
    
    return _motionAnalyzer;
}

@end
