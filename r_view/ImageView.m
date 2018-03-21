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

    if (self) {
        _zoom = 1;
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    // Stop listening to size changes of our old superview.
    if (self.superview != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.superview];
    }
}

- (void)viewDidMoveToSuperview {
    // Listen for changes to the superview size so we can
    // adapt ours.
    [self.superview setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(superviewWasResized:) name:NSViewFrameDidChangeNotification object:self.superview];
    [self resetFrame];
}

- (void)superviewWasResized:(NSNotification *)notification {
    // The frame size will be the same, but this forces the centering clip view
    // to re-center the image.
    [self resetFrame];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [NSGraphicsContext saveGraphicsState];

    // Draw the image.
    if (_image != nil) {
        // Where to draw in the view.
        CGRect rect = [self getZoomedImageRect];

        // Checkerboard background.
        if (_image.isSemiTransparent) {
            // One color.
            [[NSColor whiteColor] set];
            NSRectFill(dirtyRect);

            // Other color.
            [[NSColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0] set];
            int tileSize = 8; // Must be power of two.
            int tileMask = tileSize - 1;
            int x1 = (int) dirtyRect.origin.x & ~tileMask;
            int x2 = (int) dirtyRect.origin.x + dirtyRect.size.width;
            int y1 = (int) dirtyRect.origin.y & ~tileMask;
            int y2 = (int) dirtyRect.origin.y + dirtyRect.size.height;
            BOOL indented = NO;
            CGRect tile = CGRectMake(0, 0, tileSize, tileSize);
            for (int y = y1; y <= y2; y += tileSize) {
                tile.origin.y = rect.origin.y + y;
                for (int x = x1 + (indented ? tileSize : 0); x <= x2; x += tileSize*2) {
                    tile.origin.x = rect.origin.x + x;
                    NSRectFill(CGRectIntersection(tile, rect));
                }
                indented = !indented;
            }
        }

        // Draw the image.
        NSDictionary *hints = @{
                                NSImageHintInterpolation: [NSNumber numberWithInt:_zoom >= 1 ? NSImageInterpolationNone : NSImageInterpolationHigh]
                                };
        [_image.nsImage drawInRect:rect
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

// Make origin in upper-left.
- (BOOL)isFlipped {
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

- (void)mouseDown:(NSEvent *)event {
    [self updateColorPicker:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self updateColorPicker:event];
}

- (void)setImage:(Image *)image {
    _image = image;
    [self resetFrame];
    [self setNeedsDisplay:YES];
}

- (void)setZoom:(float)zoom {
    if (zoom == 0) {
        // Safety.
        NSLog(@"Can't zoom to zero.");
        return;
    }

    // Find center of parent view.
    NSScrollView *scrollView = [self enclosingScrollView];
    CGSize parentSize = scrollView.bounds.size;
    CGPoint parentViewCenter = CGPointMake(parentSize.width/2, parentSize.height/2);

    // Convert to our own view.
    NSPoint viewCenter = [self convertPoint:parentViewCenter fromView:scrollView];

    // Find view center in image.
    CGPoint viewCenterInImage = [self toImagePointFromViewPoint:viewCenter];

    // Update zoom.
    _zoom = zoom;

    // Add background if necessary.
    [self resetFrame];

    // Move back to new view center.
    CGPoint newViewCenter = [self toViewPointFromImagePoint:viewCenterInImage];

    // New view origin. This is a point in our own view that we want to display
    // in the upper-left.
    CGPoint newViewOrigin = CGPointMake(newViewCenter.x - parentViewCenter.x,
                                        newViewCenter.y - parentViewCenter.y);

    // Scroll there.
    [self scrollPoint:newViewOrigin];

    [self setNeedsDisplay:YES];
}

- (void)resetFrame {
    self.frame = [self getZoomedImageRect];
}

- (void)updateColorPicker:(NSEvent *)event {
    // Convert to view coordinates.
    NSPoint viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];

    // Convert to image coordinates.
    CGPoint imagePoint = [self toImagePointFromViewPoint:viewPoint];

    // Convert to integer. Always round down.
    int x = (int) imagePoint.x;
    int y = (int) imagePoint.y;

    if (_delegate != nil && x >= 0 && y >= 0 && x < _image.width && y < _image.height) {
        [_delegate userSelectedPointX:x y:y];
    }
}

- (CGPoint)toImagePointFromViewPoint:(CGPoint)viewPoint {
    // Convert to image coordinates.
    return CGPointMake(viewPoint.x/_zoom, viewPoint.y/_zoom);
}

- (CGPoint)toViewPointFromImagePoint:(CGPoint)imagePoint {
    // Convert to view coordinates.
    return CGPointMake(imagePoint.x*_zoom, imagePoint.y*_zoom);
}

// Size of zoomed image. This is the size of the original image times
// the zoom.
- (CGSize)getZoomedImageSize {
    return CGSizeMake(_image.width*_zoom, _image.height*_zoom);
}

// The rect of the image, including the zoom.
- (CGRect)getZoomedImageRect {
    CGSize displaySize = [self getZoomedImageSize];

    CGRect rect;
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size = displaySize;

    return rect;
}

@end
