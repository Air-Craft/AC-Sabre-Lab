//
//  UIView+OVSnapshot.m
//  Overline
//
//  Created by Hari Karam Singh on 22/05/2014.
//  Copyright (c) 2014 Air Craft Media Ltd. MIT License.
//

#import "UIView+OVSnapshot.h"

@implementation UIView (OVSnapshot)

- (UIImage *)snapshotImageAfterScreenUpdates:(BOOL)afterUpdates
{
    UIImage *snapshotImage;
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    {
        [self drawViewHierarchyInRect:self.frame afterScreenUpdates:afterUpdates];
        snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}

@end
