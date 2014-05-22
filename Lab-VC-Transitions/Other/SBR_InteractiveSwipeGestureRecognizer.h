//
//  SBR_InteractiveSwipeGestureRecognizer.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBR_InteractiveSwipeGestureRecognizer : UIGestureRecognizer <UIGestureRecognizerDelegate>

@property (nonatomic) NSUInteger numberOfTouchesRequired;
@property (nonatomic) UISwipeGestureRecognizerDirection direction;

/** Amount you need to displace in `direction` before your target starts getting reports */
@property (nonatomic) CGFloat thresholdDistance;
@property (nonatomic) CGFloat targetDistance;

/** 0..1 representing how far we've gestured wrt target distance */
@property (nonatomic, readonly) CGFloat percentCompleted;

/** While in an active phase, the most recent velocity of the touches in pt/second.  Positive in the direction of motion */
@property (nonatomic, readonly) CGFloat velocity;

@end
