//
//  PickedColor.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/5/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PickedColor : NSObject

@property (nonatomic) int x;
@property (nonatomic) int y;
@property (nonatomic) uint8_t red;
@property (nonatomic) uint8_t green;
@property (nonatomic) uint8_t blue;
@property (nonatomic) uint8_t alpha;
@property (nonatomic) BOOL hasAlpha;
@property (nonatomic,readonly) uint32_t rgb;
@property (nonatomic,readonly) uint32_t rgba;

- (NSString *)toString;
- (NSString *)toRgbString;
- (NSColor *)toNsColor;

@end
