//
//  SBR_AnimatedFilterSnapshotView.m
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <POP.h>
#import "SBR_AnimatedFilterSnapshotView.h"

@implementation SBR_AnimatedFilterSnapshotView
{
    CGFloat _filterAmount;  // 0..1
    SBR_CompositeGPUFilterAbstract *_filter;
    GPUImagePicture *_snapshotPicture;
    POPAnimatableProperty *_animProp;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newWithSourceView:(UIView *)sourceView
                           filter:(SBR_CompositeGPUFilterAbstract *)filter
               initDrawCompletion:(void (^)(SBR_AnimatedFilterSnapshotView *view))completion
{
    // Get the snapshot so we know the frame size. Can't plain `init` a GPUImageView.
    UIImage *snapshot = [sourceView renderAsImage];
    CGRect f = {0, 0, snapshot.size};
    SBR_AnimatedFilterSnapshotView *me = [[self alloc] initWithFrame:f];
    
    if (me) {
        
        // Clear BG
        me.backgroundColor = [UIColor clearColor];
        me.opaque = NO;
        
        // Link up the filter chain
        me->_snapshotPicture = [[GPUImagePicture alloc] initWithImage:snapshot];
        me->_filter = filter;
        [me->_snapshotPicture addTarget:filter.inputFilter];
        [filter.outputFilter addTarget:me];
        [me->_snapshotPicture processImageWithCompletionHandler:^{
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(me);
                });
            }
        }];
        
        // Create the custom animation property for use later on
        POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"co.air-SBR_AnimatedFilterSnapshotView.filterAmount" initializer:^(POPMutableAnimatableProperty *prop) {
            prop.readBlock = ^(id obj, CGFloat values[]) {
                values[0] = me->_filterAmount;
            };
            
            // write value
            prop.writeBlock = ^(id obj, const CGFloat values[]) {
                me->_filterAmount = values[0];
                [me _updateForFilterAmount:me->_filterAmount];
            };
        }];
        me->_animProp = prop;
    }
    return me;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods
/////////////////////////////////////////////////////////////////////////

- (void)filterWithDuration:(NSTimeInterval)duration
{
    POPBasicAnimation *anim = [POPBasicAnimation easeOutAnimation];
    anim.fromValue = @(0.0);
    anim.toValue = @(1.0);
    anim.duration = duration;
    anim.property = _animProp;
    [self pop_addAnimation:anim forKey:@"co.air-craft.SBR_AnimatedFilterSnapshotView.filterAnim"];
}

//---------------------------------------------------------------------

- (void)unfilterWithDuration:(NSTimeInterval)duration
{
    [self unfilterWithDuration:duration completion:nil];
}

//---------------------------------------------------------------------

- (void)unfilterWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion
{
    POPBasicAnimation *anim = [POPBasicAnimation easeOutAnimation];
    anim.fromValue = @(1.0);
    anim.toValue = @(0.0);
    anim.duration = duration;
    anim.property = _animProp;
    [anim setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        if (completion) completion();
    }];
    [self pop_addAnimation:anim forKey:@"co.air-craft.SBR_AnimatedFilterSnapshotView.unfilterAnim"];
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Protected
/////////////////////////////////////////////////////////////////////////

- (void)_updateForFilterAmount:(CGFloat)filterAmount
{
    _filter.filterAmount = filterAmount;
    [_snapshotPicture processImage];
}


@end
