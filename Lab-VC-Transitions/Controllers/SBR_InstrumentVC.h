//
//  SBR_InstrumentVC.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 19/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBR_InstrumentVC : UIViewController

@property (nonatomic, weak) UIView *panelView;

@property (nonatomic, copy) void (^vcRequestedMenu)();

+ (instancetype)instrumentVC;


@end
