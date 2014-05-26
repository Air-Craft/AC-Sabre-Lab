//
//  SBR_SettingsTestVC.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 26/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_SettingsTestVC.h"

#import "SBR_Factory.h"
#import "SBR_StyleKit.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Defs
/////////////////////////////////////////////////////////////////////////

static SBR_Factory *Factory;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_SettingsTestVC
{
    IMMotionAnalyzer *_motionAnalyzer;
    MPerformanceThread *_controlThread;
    
    UILabel *_thing;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // INJECTION
        _motionAnalyzer = [SBR_Factory sharedInstance].motionAnalyzer;
        _controlThread = [SBR_Factory sharedInstance].controlThread;
        
    }
    return self;
}

//---------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _thing = [[UILabel alloc] init];
    _thing.text = @"⇪";
    _thing.size = CGSizeMake(50, 50);
    _thing.adjustsFontSizeToFitWidth = YES;
    _thing.font = [UIFont fontWithName:@"Helvetica Neue" size:50.0];
    _thing.textColor = [SBR_StyleKit yellowTextColor];
    [self.view addSubview:_thing];
    _thing.centerX = self.view.width/2;
    

    /////////////////////////////////////////
    // MOTION ANALYZER SETUP
    /////////////////////////////////////////
    
    [_motionAnalyzer addMotionObserver:self];
}

//---------------------------------------------------------------------

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_controlThread start];
    [_motionAnalyzer engage];
}

//---------------------------------------------------------------------

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _controlThread.paused = YES;
    [_motionAnalyzer disengage];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - IMMotionObserverProtocol
/////////////////////////////////////////////////////////////////////////

- (void)handleMotionUpdateForData:(IMMotionSampleSet)current previousData:(IMMotionSampleSet)previous
{
    _thing.centerY = (1 - (current.attitude.pos.pitch + M_PI_2) / M_PI) * (self.view.height - _thing.height);
    _thing.centerX = (1 - (current.attitude.pos.roll + M_PI_2) / (M_PI)) * (self.view.width - _thing.width);
    
    CGFloat p = -current.attitude.pos.pitch / M_PI_2;// + M_PI_2;  p = (p > M_PI_2) ? p-M_PI : p;
    CGFloat r = -current.attitude.pos.roll / M_PI_2;
    _thing.transform = CGAffineTransformMakeRotation(atan(p / (r+0.00001)) + M_PI_2);
}


@end
