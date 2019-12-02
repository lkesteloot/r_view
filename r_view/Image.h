//
//  Image.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/4/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PickedColor.h"

@interface Image : NSDocument

@property (nonatomic,readonly) NSImage *nsImage;
@property (nonatomic,readonly) int width;
@property (nonatomic,readonly) int height;
// Has at least one non-opaque pixel:
@property (nonatomic,readonly) BOOL isSemiTransparent;

- (instancetype)initWithImage:(NSImage *)image;

// Returns nil if the point is outside the image.
- (PickedColor *)sampleAtX:(int)x y:(int)y;

@end
