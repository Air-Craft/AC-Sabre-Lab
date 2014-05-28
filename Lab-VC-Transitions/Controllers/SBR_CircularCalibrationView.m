//
//  SBR_CircularCalibrationView.m
//  Lab-VC-Transitions
//
//  Created by Chris Mitchelmore on 27/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_CircularCalibrationView.h"
#import "StyleKitName.h"


@implementation SBR_CircularCalibrationView 
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _maximum = 0;
        _minimum = 90;
    }
    return self;
}
- (void)setMaximum:(CGFloat)maximum
{
    _maximum = maximum;
    [self setNeedsDisplay];
}

- (void)setMinimum:(CGFloat)minimum
{
    _minimum = minimum;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [StyleKitName drawCircularCalibratorWithFrame:rect minAngle:_minimum maxAngle:_maximum];
}


@end
