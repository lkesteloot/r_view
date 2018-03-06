//
//  Image.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/4/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "PickedColor.h"

@interface Image : NSObject

@property (nonatomic,readonly) NSString *pathname;
@property (nonatomic,readonly) NSImage *nsImage;
@property (nonatomic,readonly) int width;
@property (nonatomic,readonly) int height;

- (id)initFromPathname:(NSString *)pathname;

// Returns nil if the point is outside the image.
- (PickedColor *)sampleAtX:(int)x y:(int)y;

@end
