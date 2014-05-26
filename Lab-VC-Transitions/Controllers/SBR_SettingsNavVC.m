//
//  SBR_MenuNavVC.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 23/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_SettingsNavVC.h"
#import "SBR_SettingsNavAnimController.h"
#import "SBR_StyleKit.h"
#import "SBR_InteractiveSwipeGestureRecognizer.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Constants
/////////////////////////////////////////////////////////////////////////

static const CGFloat _SBR_SWIPE_RIGHT_INIT_X = 0;
static const CGFloat _SBR_SWIPE_RIGHT_DISTANCE_PERCENT = 0.3;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_SettingsNavVC
{
    SBR_SettingsNavAnimController *_animController;
    UIButton *_swipeRightButton;
}

- (void)viewDidLoad
{
    self.view.opaque = NO;
    self.view.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    
    // Preload the animation controller
    _animController = [SBR_SettingsNavAnimController new];
    
    // Create the slide-to-pop control and hide
    _swipeRightButton = [SBR_StyleKit swipeRightIconButton];
    _swipeRightButton.alpha = 0.0;
    [self.view addSubview:_swipeRightButton];
    _swipeRightButton.x = _SBR_SWIPE_RIGHT_INIT_X;
    [_swipeRightButton setBottomMargin:44];
    
    // Link up the touch and the slide GR.  Use a tap rather than the ControlEvent to prevent double triggers on slide
    
    [_swipeRightButton bk_addEventHandler:^(id sender) {
        [self popViewControllerAnimated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    SBR_InteractiveSwipeGestureRecognizer *gr = [[SBR_InteractiveSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleRightSwipeUpdate:)];
    gr.numberOfTouchesRequired = 1;
    gr.direction = UISwipeGestureRecognizerDirectionRight;
    gr.thresholdDistance = 0;
    gr.targetDistance = _SBR_SWIPE_RIGHT_DISTANCE_PERCENT * self.view.width;
    [_swipeRightButton addGestureRecognizer:gr];
}

//---------------------------------------------------------------------

- (void)_handleRightSwipeUpdate:(SBR_InteractiveSwipeGestureRecognizer *)swipe
{
    switch (swipe.state) {
            
        // BEGIN: Set the animCon to interactive and initiate the pop
		case UIGestureRecognizerStateBegan:
            _animController.isInteractive = YES;
            [self popViewControllerAnimated:YES];
            break;
            

		// CHANGED: Report percentage to the animCon
        case UIGestureRecognizerStateChanged:
            [_animController updateWithPercent:swipe.percentCompleted];
            
            // Update the control too
            _swipeRightButton.x = _SBR_SWIPE_RIGHT_INIT_X + swipe.percentCompleted * _SBR_SWIPE_RIGHT_DISTANCE_PERCENT * self.view.width;
            _swipeRightButton.alpha = 1.0 - swipe.percentCompleted;
            break;
            
            
        // CANCELLED: If thresholds are met then complete the transition. Else abort
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            BOOL abort = (swipe.percentCompleted < 0.75) && (swipe.velocity < 500);
            if (abort) {
                [_animController abort];
                _swipeRightButton.alpha = 1.0;
                _swipeRightButton.x = _SBR_SWIPE_RIGHT_INIT_X;
                [self _updateSwipeRightButtonVisibilty];
            } else
                [_animController finishWithCompletion:^{
                    _swipeRightButton.x = _SBR_SWIPE_RIGHT_INIT_X;
                    [self _updateSwipeRightButtonVisibilty];
                }];
            break;
        }
            
        // ENDED/SUCCESS: Complete the animation/transition
        case UIGestureRecognizerStateEnded:
        //case UIGestureRecognizerStateRecognized:  // same as "Ended"
        {
            [_animController finishWithCompletion:^{
                _swipeRightButton.x = _SBR_SWIPE_RIGHT_INIT_X;
                [self _updateSwipeRightButtonVisibilty];
            }];
            break;
        }
            
        default:
        case UIGestureRecognizerStatePossible:
            break;
    }
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Delegate Fulfillment
/////////////////////////////////////////////////////////////////////////

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self _updateSwipeRightButtonVisibilty];
}

//---------------------------------------------------------------------

- (void)_updateSwipeRightButtonVisibilty
{
    [self.view bringSubviewToFront:_swipeRightButton];
    [UIView animateWithDuration:0.25 animations:^{
        _swipeRightButton.alpha = (self.viewControllers.count > 1) ? 1.0 : 0.0;
    }];
}

//---------------------------------------------------------------------

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}

//---------------------------------------------------------------------

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    // Feed the system our AnimController
    // Note, isInteractive is set via the gesture which engages the interactive animation which happens right before the push and hence this method
    _animController.operation = operation;
    return _animController;
    
}

//---------------------------------------------------------------------

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    // Return animController only if it's an interactive operation
    if (_animController.isInteractive) {
        return _animController;
    }
    return nil;
 }




@end
