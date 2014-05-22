//
//  SBR_MenuTransitionMenuFilter.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

@interface SBR_MenuTransitionMenuFilter : NSObject

/** Reference to the underlying GPUImageFilter */
@property (nonatomic, readonly) GPUImageFilter *gpuFilter;

/** 0-1 for how much filter is applied */
@property (nonatomic) CGFloat filterAmount;

@end
