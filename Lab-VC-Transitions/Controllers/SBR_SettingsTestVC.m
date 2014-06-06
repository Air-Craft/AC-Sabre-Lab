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

#import "SBR_CircularCalibrationView.h"

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
    SBR_CircularCalibrationView *_calibrator;
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
    
    _calibrator = [[SBR_CircularCalibrationView alloc] initWithFrame:CGRectMake(70, 60, 180, 180)];
    [self.view addSubview:_calibrator];
    UIButton *excluded = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    excluded.frame = CGRectMake(110, self.view.frame.size.height-50, 100, 50);
    [excluded setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [excluded setTitle:@"Excluded" forState:UIControlStateNormal];
    [excluded addTarget:self action:@selector(_toggleExcluded) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:excluded];
    UIColor* backgroundColor = [UIColor colorWithRed: 0.082 green: 0.082 blue: 0.067 alpha: 1];

    self.view.backgroundColor = backgroundColor;
    
    
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
#pragma mark - Private API
/////////////////////////////////////////////////////////////////////////

static CGFloat min = 0;
static CGFloat max = 0;
- (void)_toggleExcluded
{
    static BOOL show = NO;
    show = !show;
    min = max = 0;
    _calibrator.showExcluded = show;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - IMMotionObserverProtocol
/////////////////////////////////////////////////////////////////////////

- (void)handleMotionUpdateForData:(IMMotionSampleSet)current previousData:(IMMotionSampleSet)previous
{

    CGFloat pitch = (0.5 - (current.attitude.pos.pitch + M_PI_2) / M_PI) * 360;
    max = pitch > max ? pitch : max;
    min = pitch < min ? pitch : min;
    CGFloat mx = 90+ (max * -1);
    CGFloat mn = 90+ (min * -1);

    if ( _calibrator.showExcluded ){
        _calibrator.excludeMaximum = mx;
        _calibrator.excludeMinimum = mn;
        _calibrator.minimum = 270;
        _calibrator.maximum = 0;
    }else{
        _calibrator.excludeMinimum = mx;
        _calibrator.minimum = mn;
    }
    
//    CGFloat p = -current.attitude.pos.pitch / M_PI_2;// + M_PI_2;  p = (p > M_PI_2) ? p-M_PI : p;
//    CGFloat r = -current.attitude.pos.roll / M_PI_2;
//    _thing.transform = CGAffineTransformMakeRotation(atan(p / (r+0.00001)) + M_PI_2);
}


@end
