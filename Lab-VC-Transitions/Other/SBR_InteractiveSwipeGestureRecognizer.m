//
//  SBR_InteractiveSwipeGestureRecognizer.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>
#import "SBR_InteractiveSwipeGestureRecognizer.h"

@interface UIGestureRecognizer()
//@property (nonatomic, readwrite) UIView *view;
@end

@implementation SBR_InteractiveSwipeGestureRecognizer
{
    NSTimeInterval _initialTime;
    NSTimeInterval _lastTime;
    CGPoint _initialMedianPt;              // Average position of all active touches
    CGPoint _lastMedianPt;                 // For velocity calcs
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        _thresholdDistance = 20;
        _targetDistance = 200;
    }
    return self;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////
#pragma mark - GR Event Handling
/////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _handleActiveTouchesChanged];
}

//---------------------------------------------------------------------

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIGestureRecognizerState state = self.state;
    
    // Calculate the displacement and velocity
    CGPoint newMedianPt = [self _medianPointForTouches];
    CGPoint absDeltaPt = CGPointMake(newMedianPt.x - _initialMedianPt.x,
                                     newMedianPt.y - _initialMedianPt.y);
    CGPoint lastDeltaPt = CGPointMake(newMedianPt.x - _lastMedianPt.x,
                                      newMedianPt.y - _lastMedianPt.y);
    NSTimeInterval now = CACurrentMediaTime();
    NSTimeInterval deltaT = now - _lastTime;
    
    // Displacement in the specified gesture direction
    CGFloat delta = (_direction == UISwipeGestureRecognizerDirectionUp ||
                     _direction == UISwipeGestureRecognizerDirectionDown)
                        ? absDeltaPt.y
                        : absDeltaPt.x;
    
    // Displacement along the other axis
    CGFloat altDelta = (_direction == UISwipeGestureRecognizerDirectionUp ||
                     _direction == UISwipeGestureRecognizerDirectionDown)
                        ? absDeltaPt.x
                        : absDeltaPt.y;
    
    CGFloat lastDelta = (_direction == UISwipeGestureRecognizerDirectionUp ||
                         _direction == UISwipeGestureRecognizerDirectionDown)
                        ? lastDeltaPt.y
                        : lastDeltaPt.x;
    
    // Used to normalise comparisons
    CGFloat sign = (_direction == UISwipeGestureRecognizerDirectionRight ||
                    _direction == UISwipeGestureRecognizerDirectionDown)
                        ? 1.0
                        : -1.0;
    
    // Check we haven't moved in another direction more than this one
    if ((altDelta * sign) > (delta * sign)) {
        if (state == UIGestureRecognizerStateBegan ||
            state == UIGestureRecognizerStateChanged) {
            self.state = UIGestureRecognizerStateFailed;
        }
        return;
    }
    
    // If we haven't begun then check the absolute displacement wrt the direction
    if (state != UIGestureRecognizerStateBegan &&
        state != UIGestureRecognizerStateChanged) {
        
        if (delta * sign >= _thresholdDistance) {
            self.state = UIGestureRecognizerStateBegan;
        }
    }
    
    // If we have begun than update the percentage calcs
    if (state == UIGestureRecognizerStateBegan ||
        state == UIGestureRecognizerStateChanged) {
        
        _percentCompleted = (delta * sign - _thresholdDistance) / (_targetDistance - _thresholdDistance);
        _percentCompleted = MIN(1.0, MAX(0.0, _percentCompleted));
        if (_percentCompleted == 1.0) {
            self.state = UIGestureRecognizerStateRecognized;    // NOTE! This == "Ended"!
        }
        
        _velocity = (lastDelta * sign) / deltaT;
    }
    
    _lastTime = now;
    _lastMedianPt = newMedianPt;
}

//---------------------------------------------------------------------

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _handleActiveTouchesChanged];
}

//---------------------------------------------------------------------

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self _handleActiveTouchesChanged];
}

        
//---------------------------------------------------------------------

- (void)reset
{
    _percentCompleted = 0.0;
    _velocity = 0.0;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_handleActiveTouchesChanged
{
    // End if the touch count changed after we've begun recognizing
    if (self.state == UIGestureRecognizerStateBegan ||
        self.state == UIGestureRecognizerStateChanged ||
        self.numberOfTouches != _numberOfTouchesRequired) {
        
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    // Otherwise if we've reached the required touch number then initiate tracking
    if (self.numberOfTouches == _numberOfTouchesRequired) {
        _initialTime =
        _lastTime = CACurrentMediaTime();
        _initialMedianPt =
        _lastMedianPt = [self _medianPointForTouches];
    }
}

//---------------------------------------------------------------------

- (CGPoint)_medianPointForTouches
{
    CGPoint medianPt;
    for (int i=0; i<_numberOfTouchesRequired; i++) {
        CGPoint pt = [self locationOfTouch:i inView:self.view];
        medianPt.x += pt.x;
        medianPt.y += pt.y;
    }
    
    medianPt.x /= _numberOfTouchesRequired;
    medianPt.y /= _numberOfTouchesRequired;

    return medianPt;
}



@end
