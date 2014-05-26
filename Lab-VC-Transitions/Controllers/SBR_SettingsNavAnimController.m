//
//  SBR_MenuDrilldownAnimation.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 20/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "SBR_SettingsNavAnimController.h"
#import "SBR_AnimatedFilterSnapshotView.h"
#import "SBR_BlurOutFilter.h"
#import "SBR_MaterializeFilter.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Defs
/////////////////////////////////////////////////////////////////////////

static const CGFloat _SBR_SHRINK_SCALE = 0.7;      // Initial scale for incoming w/ push or final scale for outgoing w/ pop
static const CGFloat _SBR_ANIM_DURATION = 0.4;

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation SBR_SettingsNavAnimController
{
    SBR_CompositeGPUFilterAbstract *_filter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _filter = [SBR_BlurOutFilter new];
    }
    return self;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewControllerAnimatedTransitioning
/////////////////////////////////////////////////////////////////////////

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionCtx
{
    //Get references to the view hierarchy
    UIView *contView = [transitionCtx containerView];
    UIViewController *fromVC = [transitionCtx viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionCtx viewControllerForKey:UITransitionContextToViewControllerKey];
    NSTimeInterval duration = _SBR_ANIM_DURATION; //[self transitionDuration:transitionCtx];
    CGAffineTransform shrinkTransform = CGAffineTransformMakeScale(_SBR_SHRINK_SCALE, _SBR_SHRINK_SCALE);
    
    /////////////////////////////////////////
    // PUSH ANIMATION
    /////////////////////////////////////////

    if (self.operation == UINavigationControllerOperationPush) {
    
        // PRELOAD filter
        // CONSTANTS
        // TEST!
        
        // Grab a snapshot of the destination so we can do gpu fxs
        _filter.filterAmount = 1;
        __block SBR_AnimatedFilterSnapshotView *toViewSnapshot = [SBR_AnimatedFilterSnapshotView newWithSourceView:toVC.view filter:_filter initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view) {
        
            // Also fade and shrink the destination
            toViewSnapshot.transform = shrinkTransform;
            toViewSnapshot.alpha = 0.0;
            
            [contView addSubview:toViewSnapshot];
            
            // Animate it all in while panning/fading the fromView as well
            [toViewSnapshot unfilterWithDuration:duration];
            [UIView
             animateWithDuration:duration
             animations:^{
                 
                 toViewSnapshot.transform = CGAffineTransformIdentity;
                 toViewSnapshot.alpha = 1.0;
                 
                 fromVC.view.x -= contView.width;
                 fromVC.view.alpha = 0.0;
                 fromVC.view.transform = shrinkTransform;
                 
             } completion:^(BOOL finished) {
                 // Swap the snapshot view
                 [toViewSnapshot removeFromSuperview];
                 [contView addSubview:toVC.view];
                 
                 // Clean up the from View
                 fromVC.view.transform = CGAffineTransformIdentity;
                 fromVC.view.origin = CGPointZero;
                 
                 [transitionCtx completeTransition:YES];
             }];
            
        }]; // END SBR_AnimatedFilterSnapshotView new...
        

    
    /////////////////////////////////////////
    // POP ANIMATION
    /////////////////////////////////////////

    } else if (self.operation == UINavigationControllerOperationPop) {
        
        // Grab snapshot of the fromView
        _filter.filterAmount = 0;
        __block SBR_AnimatedFilterSnapshotView *fromViewSnapshot = [SBR_AnimatedFilterSnapshotView newWithSourceView:fromVC.view filter:_filter initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view) {
            
            // Swap out the fromView with the snapshot and prep the toVC view thats coming back
            [contView addSubview:fromViewSnapshot];
            [fromVC.view removeFromSuperview];
            toVC.view.y = 0;
            toVC.view.x = -contView.width;
            toVC.view.transform = CGAffineTransformMakeScale(_SBR_SHRINK_SCALE, _SBR_SHRINK_SCALE);
            toVC.view.alpha = 0;
            [contView addSubview:toVC.view];
            
            // Do the anims...
            [fromViewSnapshot filterWithDuration:duration];
            [UIView
             animateWithDuration:duration
             animations:^{
                 fromViewSnapshot.alpha = 0.0;
                 fromViewSnapshot.transform = shrinkTransform;
                 
                 toVC.view.transform = CGAffineTransformIdentity;
                 toVC.view.x = 0;
                 toVC.view.alpha = 1;
             }
             completion:^(BOOL finished) {
                 [fromViewSnapshot removeFromSuperview];
                 [transitionCtx  completeTransition:YES];
             }];
        }]; // END Snapshot init draw
    }
}

//---------------------------------------------------------------------

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionCtx {
    return _SBR_ANIM_DURATION;
}

//---------------------------------------------------------------------

-(void)animationEnded:(BOOL)transitionCompleted {
    self.isInteractive = NO;
}



/////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewControllerInteractiveTransitioning & Interactive API
/////////////////////////////////////////////////////////////////////////

-(void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionCtx {
    //Maintain reference to context
//    _context = transitionCtx;
//    
//    //Get references to view hierarchy
//    UIView *containerView = [transitionCtx containerView];
//    UIViewController *fromViewController = [transitionCtx viewControllerForKey:UITransitionContextFromViewControllerKey];
//    UIViewController *toViewController = [transitionCtx viewControllerForKey:UITransitionContextToViewControllerKey];
//    
//    //Insert 'to' view into hierarchy
//    toViewController.view.frame = [transitionCtx finalFrameForViewController:toViewController];
//    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
//    
//    //Save reference for view to be scaled
//    _transitioningView = fromViewController.view;
}

//---------------------------------------------------------------------

- (void)updateWithPercent:(CGFloat)percent
{
    
}




@end
