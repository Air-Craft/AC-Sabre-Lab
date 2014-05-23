//
//  SBR_AnimatedFilterSnapshotView.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "GPUImageView.h"
#import "SBR_CompositeGPUFilterAbstract.h"

/** Normally I'm trying to handle process via composition and controllers rather than inheritance and wrapping but POP and GPUImage are so verbose I thought it best to wrap in this short lived case */
@interface SBR_AnimatedFilterSnapshotView : GPUImageView

+ (instancetype)newWithSourceView:(UIView *)sourceView
                           filter:(SBR_CompositeGPUFilterAbstract *)filter
               initDrawCompletion:(void (^)(SBR_AnimatedFilterSnapshotView *view))completion;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

- (void)filterWithDuration:(NSTimeInterval)duration;
- (void)unfilterWithDuration:(NSTimeInterval)duration;
- (void)unfilterWithDuration:(NSTimeInterval)duration completion:(void(^)(void))completion;

/////////////////////////////////////////////////////////////////////////
#pragma mark - Protected
/////////////////////////////////////////////////////////////////////////

/** @protected
    Override to tap into the animation to perform additional operations 
 */
- (void)_updateForFilterAmount:(CGFloat)filterAmount;


@end
