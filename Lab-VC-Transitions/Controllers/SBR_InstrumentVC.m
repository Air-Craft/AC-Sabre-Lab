//
//  SBR_InstrumentVC.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 19/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <BlocksKit+UIKit.h>
#import "SBR_InstrumentVC.h"

@interface SBR_InstrumentVC ()

@end

@implementation SBR_InstrumentVC
{
}

+ (instancetype)instrumentVC
{
    SBR_InstrumentVC *me = [[self alloc] init];
    if (me) {
        
        [me _setup];
    }
    
    return me;
}

//---------------------------------------------------------------------

- (void)_setup
{
    // DEBUG: Add fake BG & panel
    UIImage *img = [UIImage imageNamed:@"temp-beams"];
    UIImageView *imgV = [[UIImageView alloc] initWithImage:img];
    self.view.frame = imgV.frame;
    [self.view addSubview:imgV];
    
    img = [UIImage imageNamed:@"temp-flower"];
    UIView *panelView = [[UIImageView alloc] initWithImage:img];
    [self.view addSubview:panelView];
    _panelView = panelView;
}
//---------------------------------------------------------------------



@end
