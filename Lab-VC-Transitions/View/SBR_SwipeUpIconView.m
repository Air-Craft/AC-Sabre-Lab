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

+ (instancetype)new
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
    /////////////////////////////////////////
    // ICON & ANIMATION
    /////////////////////////////////////////

    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    UIImageView *imgV = [[UIImageView alloc] initWithImage:[SBR_StyleKit swipeUpIcon]];
    self.frame = CGRectMake(0, 0, 44, 44);  // needs to be bigger than the image
    [self addSubview:imgV];
    
    // Set a looped animation
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fillMode = kCAFillModeForwards;
    anim.removedOnCompletion = NO;
    anim.byValue = [NSValue valueWithCGPoint:CGPointMake(0, 4)];
    anim.duration = 0.2;
    anim.repeatCount = HUGE_VALF;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.autoreverses = YES;
    [self.layer addAnimation:anim forKey:@"position"];
    
    
    anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anim.fillMode = kCAFillModeForwards;
    anim.removedOnCompletion = NO;
    anim.fromValue = @(1.0);
    anim.toValue = @(0.6);
    anim.duration = 0.2;
    anim.repeatCount = HUGE_VALF;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.autoreverses = YES;
    [self.layer addAnimation:anim forKey:@"opacity"];
    
    
    /////////////////////////////////////////
    // GESTURE RECOGNISERS
    /////////////////////////////////////////

    @weakify(self)
    
    // Tap
    UITapGestureRecognizer *tap;
    tap = [UITapGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        @strongify(self)
        if (self.userDidTriggerWithGesture) {
            self.userDidTriggerWithGesture();
        }
    }];
    tap.numberOfTouchesRequired = 1;
    tap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tap];
    
    // Swipe
    UISwipeGestureRecognizer *swipe;
    swipe = [UISwipeGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        @strongify(self);
        if (self.userDidTriggerWithGesture) {
            self.userDidTriggerWithGesture();
        }
    }];
    swipe.numberOfTouchesRequired = 1;
    swipe.direction = UISwipeGestureRecognizerDirectionUp;
    [self addGestureRecognizer:swipe];
}

//---------------------------------------------------------------------



@end
