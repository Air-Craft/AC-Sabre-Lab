/** 
 \addtogroup InstrumentMotion
 \author     Created by Hari Karam Singh on 08/11/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{ 
 */

#import "IMFunctions.h"


NSString *IM_GetStringForHitShakeAxisDescriptor(IMHitShakeAxisDescriptor descr)
{
    NSMutableArray *arr = [NSMutableArray array];
    
    if (descr & kIMHitShakeAxisDescriptorXPositive) {
        [arr addObject:@"X Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorXNegative) {
        [arr addObject:@"X Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorYPositive) {
        [arr addObject:@"Y Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorYNegative) {
        [arr addObject:@"Y Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorZPositive) {
        [arr addObject:@"Z Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorZNegative) {
        [arr addObject:@"Z Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorGyroXPositive) {
        [arr addObject:@"Gyro X Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorGyroXNegative) {
        [arr addObject:@"Gyro X Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorGyroYPositive) {
        [arr addObject:@"Gyro Y Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorGyroYNegative) {
        [arr addObject:@"Gyro Y Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorGyroZPositive) {
        [arr addObject:@"Gyro Z Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorGyroZNegative) {
        [arr addObject:@"Gyro Z Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorPitchPositive) {
        [arr addObject:@"Pitch Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorPitchNegative) {
        [arr addObject:@"Pitch Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorRollPositive) {
        [arr addObject:@"Roll Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorRollNegative) {
        [arr addObject:@"Roll Negative"];
    }
    if (descr & kIMHitShakeAxisDescriptorYawPositive) {
        [arr addObject:@"Yaw Positive"];
    }
    if (descr & kIMHitShakeAxisDescriptorYawNegative) {
        [arr addObject:@"Yaw Negative"];
    }
    
    return [NSString stringWithFormat:@"[%@]", [arr componentsJoinedByString:@", "]];
}




/// @}