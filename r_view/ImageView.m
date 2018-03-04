//
//  ImageView.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ImageView.h"

@interface ImageView () {
    NSPoint _origin;
}

@end

@implementation ImageView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    _zoom = 0.25f;
    _origin.x = 0;
    _origin.y = 0;

    // So we can do two-finger pan.
    [self setAcceptsTouchEvents:YES];

    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [NSGraphicsContext saveGraphicsState];

    // Neutral background.
    [[NSColor grayColor] set];
    [NSBezierPath fillRect:dirtyRect];

    // Draw the image.
    if (_image != nil) {
        NSRect rect;

        rect.origin = _origin;
        rect.size = _image.size;
        rect.size.width *= _zoom;
        rect.size.height *= _zoom;

        NSDictionary *hints = @{
                                NSImageHintInterpolation: [NSNumber numberWithInt:_zoom >= 1 ? NSImageInterpolationNone : NSImageInterpolationHigh]
                                };
        [_image drawInRect:rect
                  fromRect:NSZeroRect
                 operation:NSCompositingOperationSourceOver
                  fraction:1.0f
            respectFlipped:YES
                     hints:hints];
    }

    [NSGraphicsContext restoreGraphicsState];
}

// So that we can get key events.
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    [super keyDown:event];

    switch ([event keyCode]) {
        default:
            NSLog(@"keyDown: %d", [event keyCode]);
            break;
    }
}

- (void)touchesBeganWithEvent:(NSEvent *)event {
    NSLog(@"began: %@", event);
}

- (void)touchesMovedWithEvent:(NSEvent *)event {
    NSLog(@"moved: %@", event);

}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    NSLog(@"ended: %@", event);

}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    NSLog(@"cancelled: %@", event);

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
