//
//  SBR_SwipeUpIconView.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 21/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBR_SwipeUpIconView : UIView

@property (nonatomic, copy) void (^userDidTriggerWithGesture)();

@end
