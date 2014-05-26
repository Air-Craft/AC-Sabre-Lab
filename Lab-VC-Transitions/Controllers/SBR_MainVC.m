//
//  ACViewController.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 19/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_MainVC.h"

#import "SBR_Factory.h"
#import "SBR_InstrumentVC.h"
#import "SBR_ModalTransitionController.h"

#import "SBR_StyleKit.h"
#import "SBR_InteractiveSwipeGestureRecognizer.h"
#import "SBR_SettingsMenuButton.h"


//TEMP
#import "SBR_AnimatedFilterSnapshotView.h"
#import "SBR_SettingsMIDIConnectionsVC.h"
#import "SBR_BlurOutFilter.h"
#import "SBR_SettingsNavVC.h"
#import "SBR_SettingsTestVC.h"
//END

static SBR_Factory *Factory;

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
    Factory = [SBR_Factory sharedInstance];
    
    // Setup the view hier & gestural segue control
    self.view.backgroundColor = [SBR_StyleKit backgroundColor];
    Factory.mainVC = self;
    [self.view addSubview:Factory.instrumentVC.view];
    
//    id vc = Factory.settingsNavVC;
//    id vc = [SBR_SettingsTestVC new];
//    [vc view].frame = self.view.frame;
//    [self addChildViewController:vc];
//    [self.view addSubview:[vc view]];
    
//    SBR_SettingsMenuButton *btn = [SBR_SettingsMenuButton newWithText:@"HOWDY Ho! >"];
//    CGRect f = {50, 100, btn.frame.size};
//    btn.frame = f;
//    [self.view addSubview:btn];
    
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
