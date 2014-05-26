//
//  SBR_SettingsMenuButton.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 23/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_SettingsMenuButton.h"
#import "SBR_StyleKit.h"

@implementation SBR_SettingsMenuButton

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithText:(NSString *)text
{
    SBR_SettingsMenuButton *me = [[self alloc] init];
    if (me) {
        UIImage *normal = [SBR_StyleKit imageForSettingsMenuGlowingTextButtonWithText:text highlighted:NO];
        UIImage *highlighted = [SBR_StyleKit imageForSettingsMenuGlowingTextButtonWithText:text highlighted:YES];
        
        [me setImage:normal forState:UIControlStateNormal];
        [me setImage:highlighted forState:UIControlStateHighlighted];
        CGRect f = {0, 0, normal.size};
        f.size.height = 44;
        me.frame = f;
    }
    return me;
}


@end
