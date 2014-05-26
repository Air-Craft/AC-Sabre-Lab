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
    
    // Interactive transition references
    CGFloat _interxPercentTransitioned;
    __weak UIViewController *_interxToVC, *_interxFromVC;
    __weak UIView *_interxContView;
    __block SBR_AnimatedFilterSnapshotView *_interxFromViewSnapshot;
    id<UIViewControllerContextTransitioning> _interxCtx;      // ref for interactive xistions
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

    /////////////////////////////////////////
    // PUSH ANIMATION
    /////////////////////////////////////////

    if (self.operation == UINavigationControllerOperationPush) {
    
        // Grab a snapshot of the destination so we can do gpu fxs
        _filter.filterAmount = 1;
        __block SBR_AnimatedFilterSnapshotView *toViewSnapshot = [SBR_AnimatedFilterSnapshotView newWithSourceView:toVC.view filter:_filter initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view) {
        
            // Prep: Fade and shrink the destination
            toViewSnapshot.transform = CGAffineTransformMakeScale(_SBR_SHRINK_SCALE, _SBR_SHRINK_SCALE);
            toViewSnapshot.alpha = 0.0;
            [contView addSubview:toViewSnapshot];
            
            [self
             _animateForwardFromView:fromVC.view
             toView:toVC.view
             containerView:contView
             toViewSnapshow:toViewSnapshot
             duration:duration
             completion:^{
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
            
            [self
             _animateBackwardFromView:fromVC.view
             toView:toVC.view
             containerView:contView
             fromViewSnapshow:fromViewSnapshot
             duration:duration
             completion:^{
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
    
    // Get references to the context & view hierarchy
    _interxCtx = transitionCtx;
    _interxContView = [transitionCtx containerView];
    _interxFromVC = [transitionCtx viewControllerForKey:UITransitionContextFromViewControllerKey];
    _interxToVC = [transitionCtx viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Insert 'to' view into hierarchy
    _interxToVC.view.frame = [transitionCtx finalFrameForViewController:_interxToVC];
    [_interxContView insertSubview:_interxToVC.view belowSubview:_interxFromVC.view];
    
    // Snapshot the from view and swap it out
    _filter.filterAmount = 0;
    _interxFromViewSnapshot = [SBR_AnimatedFilterSnapshotView newWithSourceView:_interxFromVC.view filter:_filter initDrawCompletion:^(SBR_AnimatedFilterSnapshotView *view) {
        [_interxContView insertSubview:_interxFromViewSnapshot belowSubview:_interxFromVC.view];
        [_interxFromVC.view removeFromSuperview];
    }];
}

//---------------------------------------------------------------------

/** NOTE: this is Pop only */
- (void)updateWithPercent:(CGFloat)percent
{
    _interxPercentTransitioned = percent;
    
    // FROM VC: filter
    [_interxFromViewSnapshot setFilterAmountAndUpdate:percent];
    
    // FROM VC: scale & alpha
    CGFloat scale = 1 - (1 -_SBR_SHRINK_SCALE) * percent;
    _interxFromViewSnapshot.transform = CGAffineTransformMakeScale(scale, scale);
    _interxFromViewSnapshot.alpha = 1 - percent;
    
    // TO VC: position & alpha
    _interxToVC.view.alpha = percent;
    _interxToVC.view.x = -_interxContView.width * (1 - percent);
}

//---------------------------------------------------------------------

- (void)abort
{
    // Scale the time based on the percentage
    NSTimeInterval duration = _SBR_ANIM_DURATION * (1 - _interxPercentTransitioned);
    
    // Pop only.
    // NOTE: From/To is reversed with respect to Pop and a forward animation
    [self
     _animateForwardFromView:_interxToVC.view
     toView:_interxFromVC.view
     containerView:_interxContView
     toViewSnapshow:_interxFromViewSnapshot
     duration: duration
     completion:^{
         [_interxCtx completeTransition:NO];
     }];
}

//---------------------------------------------------------------------

- (void)finishWithCompletion:(void (^)(void))completion
{
    // Scale the time based on the percentage
    NSTimeInterval duration = _SBR_ANIM_DURATION * (1 - _interxPercentTransitioned);
    
    // pop only
    [self
     _animateBackwardFromView:_interxFromVC.view
     toView:_interxToVC.view
     containerView:_interxContView
     fromViewSnapshow:_interxFromViewSnapshot
     duration: duration
     completion:^{
         [_interxCtx completeTransition:YES];
         if (completion) completion();
     }];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_animateForwardFromView:(UIView *)fromView
                         toView:(UIView *)toView
                  containerView:(UIView *)contView
                 toViewSnapshow:(SBR_AnimatedFilterSnapshotView *)toViewSnapshot
                       duration:(NSTimeInterval)duration
                     completion:(void(^)(void))completion
{
    // Animate it all in while panning/fading the fromView as well
    [toViewSnapshot unfilterWithDuration:duration];
    [UIView
     animateWithDuration:duration
     animations:^{
         
         toViewSnapshot.transform = CGAffineTransformIdentity;
         toViewSnapshot.alpha = 1.0;
         
         fromView.x -= contView.width;
         fromView.alpha = 0.0;
         fromView.transform = CGAffineTransformMakeScale(_SBR_SHRINK_SCALE, _SBR_SHRINK_SCALE);
         
     } completion:^(BOOL finished) {
         // Swap the snapshot view
         [toViewSnapshot removeFromSuperview];
         toView.alpha = 1.0;
         toView.transform = CGAffineTransformIdentity;
         toView.x = 0;
         [contView addSubview:toView];
         
         // Clean up the from View
         fromView.transform = CGAffineTransformIdentity;
         fromView.origin = CGPointZero;
         [fromView removeFromSuperview];
         
         if (completion) completion();
     }];
}

//---------------------------------------------------------------------

- (void)_animateBackwardFromView:(UIView *)fromView
                          toView:(UIView *)toView
                   containerView:(UIView *)contView
                fromViewSnapshow:(SBR_AnimatedFilterSnapshotView *)fromViewSnapshot
                        duration:(NSTimeInterval)duration
                      completion:(void(^)(void))completion
{
    // Do the anims...
    [fromViewSnapshot filterWithDuration:duration];
    [UIView
     animateWithDuration:duration
     animations:^{
         fromViewSnapshot.alpha = 0.0;
         fromViewSnapshot.transform = CGAffineTransformMakeScale(_SBR_SHRINK_SCALE, _SBR_SHRINK_SCALE);
         
         toView.transform = CGAffineTransformIdentity;
         toView.x = 0;
         toView.alpha = 1;
     }
     completion:^(BOOL finished) {
         [fromViewSnapshot removeFromSuperview];
         if (completion) completion();
     }];
}



@end
