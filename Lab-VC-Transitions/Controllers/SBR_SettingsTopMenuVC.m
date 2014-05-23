//
//  SBR_MenuVC.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 19/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_SettingsTopMenuVC.h"
#import "SBR_SettingsMenuButton.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGFloat _SBR_MENU_X0 = 50;
static const CGFloat _SBR_MENU_Y0 = 100;
static const CGFloat _SBR_MENU_LINE_SPACE = 30;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_SettingsTopMenuVC
{
}

+ (instancetype)new
{
    SBR_SettingsTopMenuVC *me = [[self alloc] init];
    if (me) {
    }
    
    return me;
}

//---------------------------------------------------------------------

- (void)viewDidLoad
{
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];

//  // DEBUG: Add fake BG & panel
//    UIImage *img = [UIImage imageNamed:@"temp-mainmenu"];
//    UIImageView *imgV = [[UIImageView alloc] initWithImage:img];
//    self.view.frame = imgV.frame;
//    [self.view addSubview:imgV];
    
    SBR_SettingsMenuButton *music = [SBR_SettingsMenuButton newWithText:@"Music >"];
    SBR_SettingsMenuButton *connections = [SBR_SettingsMenuButton newWithText:@"Connections >"];
    SBR_SettingsMenuButton *visual = [SBR_SettingsMenuButton newWithText:@"Visual >"];
    SBR_SettingsMenuButton *help = [SBR_SettingsMenuButton newWithText:@"Help >"];
    
    CGPoint drawAt = { _SBR_MENU_X0, _SBR_MENU_Y0 };
    CGFloat H = music.frame.size.height;    // should be the same for all
    
    CGRect f1 = {drawAt, music.frame.size};
    music.frame = f1;
    [self.view addSubview:music];
    drawAt.y += H + _SBR_MENU_LINE_SPACE;
    
    CGRect f2 = {drawAt, connections.frame.size};
    connections.frame = f2;
    [self.view addSubview:connections];
    drawAt.y += H + _SBR_MENU_LINE_SPACE;
    
    CGRect f3 = {drawAt, visual.frame.size};
    visual.frame = f3;
    [self.view addSubview:visual];
    drawAt.y += H + _SBR_MENU_LINE_SPACE;
    
    CGRect f4 = {drawAt, help.frame.size};
    help.frame = f4;
    [self.view addSubview:help];
}


@end
