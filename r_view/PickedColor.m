//
//  PickedColor.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/5/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "PickedColor.h"

@implementation PickedColor

- (uint32_t)rgb {
    return (_red << 16) | (_green << 8) | (_blue << 0);
}

- (uint32_t)rgba {
    return (self.rgb << 8) | (_hasAlpha ? _alpha : 0xFF);
}

- (NSString *)toString {
    NSString *s = [NSString stringWithFormat:@"(%d,%d) → (%d,%d,%d",
                   _x, _y, (int) _red, (int) _green, (int) _blue];

    if (_hasAlpha) {
        s = [s stringByAppendingFormat:@",%d", (int) _alpha];
    }

    s = [s stringByAppendingString:@") #"];
    s = [s stringByAppendingString:[self toRgbString]];

    return s;
}

- (NSString *)toRgbString {
    return [NSString stringWithFormat:@"%06X", self.rgb];
}

- (NSColor *)toNsColor {
    // Not sure this is the best way to convert integer to float.
    return [NSColor colorWithRed:_red/255.0
                           green:_green/255.0
                            blue:_blue/255.0
                           alpha:_hasAlpha ? _alpha/255.0 : 1.0f];
}

@end
