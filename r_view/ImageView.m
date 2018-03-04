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
    BOOL _panning;
    NSTouch *_initialTouch[2];
    NSTouch *_currentTouch[2];
}

@end

@implementation ImageView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    _zoom = 0.25f;
    _origin.x = 0;
    _origin.y = 0;
    _panning = NO;

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
        NSLog(@"Origin = %g %g\n", rect.origin.x, rect.origin.y);
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
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    NSLog(@"began count = %d", (int) touches.count);
    if (touches.count == 2) {
        if (!_panning) {
            NSArray *array = [touches allObjects];
            _initialTouch[0] = [array objectAtIndex:0];
            _initialTouch[1] = [array objectAtIndex:1];
            _currentTouch[0] = _initialTouch[0];
            _currentTouch[1] = _initialTouch[1];
            _panning = YES;
        }
    } else {
        _panning = NO;
    }
}

- (void)touchesMovedWithEvent:(NSEvent *)event {
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
    NSLog(@"moved count = %d", (int) touches.count);
    if (touches.count == 2) {
        if (_panning) {
            NSArray *array = [touches allObjects];
            _currentTouch[0] = [array objectAtIndex:0];
            _currentTouch[1] = [array objectAtIndex:1];

            // Swap if necessary.
            if ([_currentTouch[0] isEqual:_initialTouch[1]]) {
                _currentTouch[0] = [array objectAtIndex:1];
                _currentTouch[1] = [array objectAtIndex:0];
            }

            // Compute distance.
            CGFloat ix = (_initialTouch[0].normalizedPosition.x + _initialTouch[1].normalizedPosition.x)/2;
            CGFloat iy = (_initialTouch[0].normalizedPosition.y + _initialTouch[1].normalizedPosition.y)/2;
            CGFloat cx = (_currentTouch[0].normalizedPosition.x + _currentTouch[1].normalizedPosition.x)/2;
            CGFloat cy = (_currentTouch[0].normalizedPosition.y + _currentTouch[1].normalizedPosition.y)/2;

            // Update pan.
            NSLog(@"Update: %g %g -> %g %g", ix, iy, cx, cy);
            _origin.x += (cx - ix)*10;
            _origin.y += (cy - iy)*10;
            [self setNeedsDisplay:YES];
        }
    } else {
        _panning = NO;
    }
}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    _panning = NO;
}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    _panning = NO;
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
