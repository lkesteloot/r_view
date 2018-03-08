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
    [self resetFrame];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [NSGraphicsContext saveGraphicsState];

    // Neutral background.
    [[NSColor grayColor] set];
    [NSBezierPath fillRect:dirtyRect];

    // Draw the image.
    if (_image != nil) {
        // Where to draw in the view.
        CGRect rect = [self getDisplayedImageRect];

        // Checkerboard background.
        if (_image.isSemiTransparent) {
            // One color.
            [[NSColor whiteColor] set];
            [NSBezierPath fillRect:rect];

            // Other color.
            [[NSColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0] set];
            int tileSize = 8;
            BOOL indented = NO;
            CGRect tile = CGRectMake(0, 0, tileSize, tileSize);
            for (int y = 0; y < rect.size.height; y += tileSize) {
                tile.origin.y = rect.origin.y + y;
                for (int x = indented ? tileSize : 0; x < rect.size.width; x += tileSize*2) {
                    tile.origin.x = rect.origin.x + x;
                    [NSBezierPath fillRect:CGRectIntersection(tile, rect)];
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
    CGRect frame = [self getZoomedImageRect];

    // Never be smaller than our parent in either dimension.
    CGRect parentBounds = self.superview.bounds;
    if (frame.size.width < parentBounds.size.width) {
        frame.size.width = parentBounds.size.width;
    }
    if (frame.size.height < parentBounds.size.height) {
        frame.size.height = parentBounds.size.height;
    }

    self.frame = frame;
}

- (void)updateColorPicker:(NSEvent *)event {
    // Convert to view coordinates.
    NSPoint viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];

    // Convert to image coordinates.
    CGPoint imagePoint = [self toImagePointFromViewPoint:viewPoint];

    // Convert to integer.
    int x = (int) (imagePoint.x + 0.5);
    int y = (int) (imagePoint.y + 0.5);

    if (_delegate != nil && x >= 0 && y >= 0 && x < _image.width && y < _image.height) {
        [_delegate userSelectedPointX:x y:y];
    }
}

- (CGPoint)toImagePointFromViewPoint:(CGPoint)viewPoint {
    // Find where we're displaying the image within our view.
    CGPoint imageOrigin = [self getDisplayedImageRect].origin;

    // Convert to image coordinates.
    return CGPointMake((viewPoint.x - imageOrigin.x)/_zoom,
                       (viewPoint.y - imageOrigin.y)/_zoom);
}

- (CGPoint)toViewPointFromImagePoint:(CGPoint)imagePoint {
    // Find where we're displaying the image within our view.
    CGPoint imageOrigin = [self getDisplayedImageRect].origin;

    // Convert to view coordinates.
    return CGPointMake(imagePoint.x*_zoom + imageOrigin.x,
                       imagePoint.y*_zoom + imageOrigin.y);
}

// Size of zoomed image. This is the size of the original image times
// the zoom.
- (CGSize)getZoomedImageSize {
    return CGSizeMake(_image.width*_zoom, _image.height*_zoom);
}

// The rect of the image, including the zoom but not including any offset.
- (CGRect)getZoomedImageRect {
    CGSize displaySize = [self getZoomedImageSize];

    CGRect rect;
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size = displaySize;

    return rect;
}

// Where the image is displayed in the view. The size is the image
// display size. The offset is usually zero, unless the scroll view is too
// large, in which case the image is translated so that it's centered.
- (CGRect)getDisplayedImageRect {
    CGRect rect = [self getZoomedImageRect];

    // Center in scroll view if we're too small.
    NSScrollView *scrollView = [self enclosingScrollView];
    CGSize parentSize = scrollView.bounds.size;
    if (parentSize.width > rect.size.width) {
        rect.origin.x = (parentSize.width - rect.size.width)/2;
    }
    if (parentSize.height > rect.size.height) {
        rect.origin.y = (parentSize.height - rect.size.height)/2;
    }

    return rect;
}

@end
