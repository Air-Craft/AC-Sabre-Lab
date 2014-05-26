//
//  SBR_SettingsMIDIConnectionsVC.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 24/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_SettingsMIDIConnectionsVC.h"
#import "SBR_SettingsMenuButton.h"

// TEMP
static const CGFloat _SBR_MENU_X0 = 50;
static const CGFloat _SBR_MENU_Y0 = 100;
static const CGFloat _SBR_MENU_LINE_SPACE = 30;


@interface SBR_SettingsMIDIConnectionsVC ()

@end

@implementation SBR_SettingsMIDIConnectionsVC

- (void)viewDidLoad
{
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    
    // TEMP
    
    SBR_SettingsMenuButton *music = [SBR_SettingsMenuButton newWithText:@"Add Connection  >"];
    SBR_SettingsMenuButton *connections = [SBR_SettingsMenuButton newWithText:@"List connections >"];
    SBR_SettingsMenuButton *visual = [SBR_SettingsMenuButton newWithText:@"Refresh >"];
    
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
}


@end
