//
//  SBR_SwipeUpIconView.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_SwipeUpIconView.h"

#import "SBR_StyleKit.h"

@implementation SBR_SwipeUpIconView

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newSwipeUpIconView
{
    SBR_SwipeUpIconView *me = [[self alloc] init];
    if (me) {
        [me _setup];
    }
    return me;
}

//---------------------------------------------------------------------

- (void)_setup
{
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    UIImageView *imgV = [[UIImageView alloc] initWithImage:[SBR_StyleKit swipeUpIcon]];
    self.frame = CGRectMake(0, 0, imgV.image.size.width, imgV.image.size.height);
    [self addSubview:imgV];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
