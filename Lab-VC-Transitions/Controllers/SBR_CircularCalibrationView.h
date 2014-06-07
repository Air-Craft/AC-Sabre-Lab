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

//Should the excluded zone be visable. If not then exclude min/max are not needed.
@property (nonatomic) BOOL showExcluded;
//The maximum end
@property (nonatomic) CGFloat maximum;
@property (nonatomic) CGFloat minimum;
@property (nonatomic) CGFloat excludeMaximum;
@property (nonatomic) CGFloat excludeMinimum;

@property (nonatomic) SBRWidgetOrientation orientation;
@end
