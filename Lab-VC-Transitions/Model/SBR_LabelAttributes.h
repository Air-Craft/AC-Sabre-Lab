//
//  SBR_LabelAttributes.h
//  Lab-VC-Transitions
//
//  Created by Hari Karam Singh on 23/05/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBR_LabelAttributes : NSObject

@property (nonatomic, copy) UIFont *font;
@property (nonatomic, copy) UIColor *color;
@property (nonatomic) NSTextAlignment alignment;
@property (nonatomic) CGFloat fontSize;

@property (nonatomic) CGFloat maskWidth;


@end
