//
//  IMThreadProtocol.h
//  InstrumentMotion
//
//  Created by Hari Karam Singh on 29/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IMControlThreadProtocol <NSObject>

- (void)addInvocation:(NSInvocation *)invocation desiredInterval:(NSTimeInterval)timeInterval;

- (void)removeInvocation:(NSInvocation *)invocation;

@end
