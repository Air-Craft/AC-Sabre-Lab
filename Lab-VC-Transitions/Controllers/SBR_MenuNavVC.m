//
//  SBR_MenuVC.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 19/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_MenuNavVC.h"

@interface SBR_MenuNavVC ()

@end

@implementation SBR_MenuNavVC


+ (instancetype)menuNavVC
{
    SBR_MenuNavVC *me = [[self alloc] init];
    if (me) {
        [me _setup];
    }
    
    return me;
}

//---------------------------------------------------------------------

- (void)_setup
{
    // DEBUG: Add fake BG & panel
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    UIImage *img = [UIImage imageNamed:@"temp-mainmenu"];
    UIImageView *imgV = [[UIImageView alloc] initWithImage:img];
    self.view.frame = imgV.frame;
    [self.view addSubview:imgV];
}


@end
