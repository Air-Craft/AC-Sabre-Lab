//
//  SBR_StyleKit.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>


/** Factory for colors images and drawing assets */
@interface SBR_StyleKit : NSObject

+ (UIColor *)backgroundColor;

+ (UIImage *)swipeUpIcon;
+ (UIImage *)swipeRightIcon;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Dervied Values
/////////////////////////////////////////////////////////////////////////
+ (CATransform3D)menuTransitionPanelTransformForAmount:(CGFloat)amount;

+ (CATransform3D)menuTransitionMenuTransformForAmount:(CGFloat)amount;



@end
