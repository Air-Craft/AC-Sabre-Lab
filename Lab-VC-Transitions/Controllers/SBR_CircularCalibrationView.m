//
//  SBR_CircularCalibrationView.m
//  Lab-VC-Transitions
//
//  Created by Chris Mitchelmore on 27/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_CircularCalibrationView.h"
#import "SBR_StyleKitExported.h"


@implementation SBR_CircularCalibrationView


/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

- (void)setMaximum:(CGFloat)maximum
{
    _maximum = maximum;
    [self setNeedsDisplay];
}

//---------------------------------------------------------------------

- (void)setMinimum:(CGFloat)minimum
{
    _minimum = minimum;
    [self setNeedsDisplay];
}

//---------------------------------------------------------------------

- (void)setExcludeMaximum:(CGFloat)excludeMaximum
{
    _excludeMaximum = excludeMaximum;
    [self setNeedsDisplay];
}

//---------------------------------------------------------------------

- (void)setExcludeMinimum:(CGFloat)excludeMinimum
{
    _excludeMinimum = excludeMinimum;
    [self setNeedsDisplay];
}

//---------------------------------------------------------------------

- (void)setOrientation:(SBRWidgetOrientation)orientation
{
    _orientation = orientation;
    [self setNeedsDisplay];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _maximum = 2;
        _minimum = 191;
        _excludeMaximum = 60;
        _excludeMinimum = 144;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

//---------------------------------------------------------------------

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [SBR_StyleKitExported drawCircularCalibratorWithFrame:rect maximum:_maximum minimum:_minimum showExluded:_showExcluded excludeMinimum:_excludeMinimum excludeMaximum:_excludeMaximum alignment:_orientation];
}

@end
