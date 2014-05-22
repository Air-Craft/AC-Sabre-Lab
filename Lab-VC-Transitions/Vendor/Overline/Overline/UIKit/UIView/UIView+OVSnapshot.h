//
//  UIView+OVSnapshot.h
//  Overline
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft Media Ltd. MIT License.
//
//

#import <UIKit/UIKit.h>

@interface UIView (OVSnapshot)

/** Returns a UIImage snapshot rather than a UIView one */
- (UIImage *)snapshotImageAfterScreenUpdates:(BOOL)afterUpdates;

@end
