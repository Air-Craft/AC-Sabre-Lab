//
//  SBR_MenuTransitionUXController.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_MenuTransitionController.h"

#import "SBR_ControllerFactory.h"
#import "SBR_InteractiveSwipeGestureRecognizer.h"

#import "SBR_SwipeUpIconView.h"

static SBR_ControllerFactory *Factory;

@implementation SBR_MenuTransitionController
{
    UIViewController *_containerVC;
    SBR_MenuTransitionPresentAnimator *_presentAnimator;
    SBR_MenuTransitionDismissAnimator *_dismissAnimator;
    UIViewController *_presentedVC;
    
    SBR_SwipeUpIconView *_swipeUpIconView;
    UIGestureRecognizer *_presentGR;
    UIGestureRecognizer *_dismissTapGR;
    UIGestureRecognizer *_dismissSwipeGR;
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithContainerVC:(UIViewController *)containerVC presentAnimator:(SBR_MenuTransitionPresentAnimator *)presentAnimator dismissAnimator:(SBR_MenuTransitionDismissAnimator *)dismissAnimator
{
    SBR_MenuTransitionController *me = [[self alloc] init];
    if (me) {
        me->_containerVC = containerVC;
        me->_presentAnimator = presentAnimator;
        me->_dismissAnimator = dismissAnimator;
        Factory = [SBR_ControllerFactory sharedInstance];
        [me _setup];
    }
    return me;
}

//---------------------------------------------------------------------

- (void)_setup
{
    // Setup the GR for presentation
    SBR_InteractiveSwipeGestureRecognizer *gr = [[SBR_InteractiveSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePresentGesture:)];
    gr.numberOfTouchesRequired = 1;
    gr.direction = UISwipeGestureRecognizerDirectionDown;
    [_containerVC.view addGestureRecognizer:gr];
    _presentGR = gr;
    
    
    // Create and hide the swipe up icon for dismissing.  Also link up it's gesture recognisers but disable them
    _swipeUpIconView = [SBR_SwipeUpIconView newSwipeUpIconView];
    _swipeUpIconView.center = CGPointMake(_containerVC.view.frame.size.width/2,
                                          _containerVC.view.frame.size.height - _swipeUpIconView.frame.size.height - 10);
    _swipeUpIconView.hidden = YES;
    [_containerVC.view addSubview:_swipeUpIconView];
    _swipeUpIconView.userDidTriggerWithGesture = ^{
        [self _handleDismissGesture];
    };
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Presenting...
/////////////////////////////////////////////////////////////////////////

- (void)_handlePresentGesture:(SBR_InteractiveSwipeGestureRecognizer *)swipe
{
    switch (swipe.state) {
		case UIGestureRecognizerStateBegan:
            [_presentAnimator begin];
            break;
            
		case UIGestureRecognizerStateChanged:
            [_presentAnimator updateWithPercent:swipe.percentCompleted];
            break;
            
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        //case UIGestureRecognizerStateRecognized:  // same as "Ended"
        {
        
            BOOL abort;
            if (swipe.state == UIGestureRecognizerStateRecognized) {
                abort = NO;
            } else {
                abort = (swipe.velocity < 100.0 && swipe.percentCompleted <= 0.7);
            }
            
            if (abort) {
                [_presentAnimator endWithAbort:YES completion:nil];
            } else {
                // Don't consider the xsition to have begun until it's certain
                _presentedVC = Factory.menuNavVC;
                [_presentAnimator endWithAbort:NO completion:^{ [self _handlePresentComplete]; }];
                
                // Must  be after the animator -end for screenshot method to work
                [_containerVC addChildViewController:_presentedVC];
            }
            break;
        }
            
        default:
        case UIGestureRecognizerStatePossible:
            break;
    }
}

//---------------------------------------------------------------------

- (void)_handlePresentComplete
{
    [_presentedVC didMoveToParentViewController:_containerVC];
    
    _presentGR.enabled = NO;
    _swipeUpIconView.hidden = NO;
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Dismissing
/////////////////////////////////////////////////////////////////////////

- (void)_handleDismissGesture
{
    
}

//---------------------------------------------------------------------


- (void)_handleDismissComplete
{
    [_presentedVC removeFromParentViewController];
    _presentedVC = nil;
    _presentGR.enabled = YES;
    
}


//---------------------------------------------------------------------





/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_initiatePresentingTransition
{
    
    
}



@end
