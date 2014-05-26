//
//  IMAppDelegate.h
//  InstrumentMotion
//
//  Created by Hari Karam Singh on 24/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InstrumentMotion.h"

@interface IMAppDelegate : UIResponder <UIApplicationDelegate, IMMotionObserverProtocol, IMHitShakeDetectorDelegate, IMAttitudeZoneDetectorDelegate>

@property (strong, nonatomic) UIWindow *window;



@end
