//
//  SBR_CircularCalibrationView.h
//  Lab-VC-Transitions
//
//  Created by Chris Mitchelmore on 27/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBR_StyleKitExported.h"

@interface SBR_CircularCalibrationView : UIView

@property (nonatomic) CGFloat maximum;
@property (nonatomic) CGFloat minimum;
@property (nonatomic) CGFloat excludeMaximum;
@property (nonatomic) CGFloat excludeMinimum;
@property (nonatomic) BOOL showExcluded;
@property (nonatomic) SBRWidgetOrientation orientation;
@end
