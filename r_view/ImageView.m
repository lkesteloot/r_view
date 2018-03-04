//
//  ImageView.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ImageView.h"

@implementation ImageView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    _zoom = 0.25f;

    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [[NSColor grayColor] set];
    [NSBezierPath fillRect:dirtyRect];

    if (_image != nil) {
        NSRect rect;

        rect.origin.x = 0;
        rect.origin.y = 0;
        rect.size = _image.size;
        rect.size.width *= _zoom;
        rect.size.height *= _zoom;

        NSDictionary *hints = @{
                                NSImageHintInterpolation: [NSNumber numberWithInt:NSImageInterpolationNone]
                                };
        [_image drawInRect:rect
                  fromRect:NSZeroRect
                 operation:NSCompositingOperationSourceOver
                  fraction:1.0f
            respectFlipped:YES
                     hints:hints];
    }
}

- (void)setImage:(NSImage *)image {
    _image = image;
    [self setNeedsDisplay:YES];
}

- (void)setZoom:(float)zoom {
    _zoom = zoom;
    [self setNeedsDisplay:YES];
}

@end
