//
//  SBR_CompositeGPUFilter.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

/** @abstract */
@interface SBR_CompositeGPUFilterAbstract : NSObject

/** @abstract Used for linking up to GPUImagePicture and GPUImageView's */
@property (nonatomic, readonly) GPUImageFilter *inputFilter;
@property (nonatomic, readonly) GPUImageFilter *outputFilter;

/** @abstract 0-1 for how much the composite filter is applied */
@property (nonatomic) CGFloat filterAmount;


@end
