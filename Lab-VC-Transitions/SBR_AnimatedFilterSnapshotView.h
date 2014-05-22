//
//  SBR_AnimatedFilterSnapshotView.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "GPUImageView.h"
#import "SBR_CompositeGPUFilterAbstract.h"

@interface SBR_AnimatedFilterSnapshotView : GPUImageView

+ (instancetype)newWithSourceView:(UIView *)sourceView
                           filter:(SBR_CompositeGPUFilterAbstract *)filter
               initDrawCompletion:(void (^)(SBR_AnimatedFilterSnapshotView *view))completion;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

- (void)filterWithDuration:(NSTimeInterval)duration;
- (void)unfilterWithDuration:(NSTimeInterval)duration;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Protected
/////////////////////////////////////////////////////////////////////////

/** @protected
    Override to tap into the animation to perform additional operations 
 */
- (void)_updateForFilterAmount:(CGFloat)filterAmount;


@end
