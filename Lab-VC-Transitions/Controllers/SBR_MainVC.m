//
//  ACViewController.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 19/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_MainVC.h"

#import "SBR_ControllerFactory.h"
#import "SBR_InstrumentVC.h"
#import "SBR_MenuTransitionController.h"

#import "SBR_StyleKit.h"
#import "SBR_InteractiveSwipeGestureRecognizer.h"

static SBR_ControllerFactory *Factory;

@interface SBR_MainVC ()

@end

@implementation SBR_MainVC
{
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
    [super viewDidLoad];
    Factory = [SBR_ControllerFactory sharedInstance];
    
    // Setup the view hier & gestural segue control
    Factory.mainVC = self;
    self.view.backgroundColor = [SBR_StyleKit backgroundColor];
    [self.view addSubview:Factory.instrumentVC.view];
}

//---------------------------------------------------------------------

- (void)didReceiveMemoryWarning
{
    [Factory releaseMemory];
}



/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////




@end
