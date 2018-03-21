//
//  ViewController.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ViewController.h"

static float LARGEST_ZOOM = 16;         // 16:1
static float SMALLEST_ZOOM = 0.0625;    // 1:16

@interface ViewController () <ImageViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"ViewController:viewDidLoad");

    // Always use new-style scrollers that overlay the image.
    _scrollView.scrollerStyle = NSScrollerStyleOverlay;

    _imageView.delegate = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (void)setImage:(Image *)image {
    NSLog(@"setImage: %@", image);
    _image = image;
    _imageView.image = image;
    _imageView.frame = CGRectMake(0, 0, image.width, image.height);
}

- (void)findBestZoomForSize:(CGSize)size {
    // Start with largest zoom and work backwards until it fits.
    float zoom = LARGEST_ZOOM;

    while (zoom > SMALLEST_ZOOM) {
        float width = ceil(_image.width*zoom);
        float height = ceil(_image.width*zoom);

        // See if it'll fit at this zoom.
        if (width <= size.width && height <= size.height) {
            break;
        }

        // Won't fit, keep trying.
        zoom /= 2;
    }

    _imageView.zoom = zoom;
    [self update];
}

// Magically called via first responder from menu item.
- (IBAction)zoomImageToFit:(id)sender {
    [self findBestZoomForSize:self.view.window.frame.size];;
}

// Magically called via first responder from menu item.
- (IBAction)zoomImageToActualSize:(id)sender {
    _imageView.zoom = 1;
    [self update];
}

// Magically called via first responder from menu item.
- (IBAction)zoomIn:(id)sender {
    if (_imageView.zoom < LARGEST_ZOOM) {
        _imageView.zoom *= 2;
        [self update];
    }
}

// Magically called via first responder from menu item.
- (IBAction)zoomOut:(id)sender {
    if (_imageView.zoom > SMALLEST_ZOOM) {
        _imageView.zoom /= 2;
        [self update];
    }
}

// Magically called via first responder from menu item.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    BOOL enabled;

    SEL action = menuItem.action;
    if (action == @selector(zoomImageToActualSize:)) {
        enabled = _imageView.zoom != 1;
    } else if (action == @selector(zoomIn:)) {
        enabled = _imageView.zoom < LARGEST_ZOOM;
    } else if (action == @selector(zoomOut:)) {
        enabled = _imageView.zoom > SMALLEST_ZOOM;
    } else {
        // Bubble up.
        enabled = [super validateMenuItem:menuItem];
    }

    return enabled;
}

// ImageViewDelegate
- (void)userSelectedPointX:(int)x y:(int)y {
    PickedColor *pickedColor = [_image sampleAtX:x y:y];
    if (pickedColor != nil) {
        _pickedColor = pickedColor;
        [self update];
    }
}

- (void)update {
    if (_delegate != nil) {
        [_delegate updateZoom:_imageView.zoom pickedColor:_pickedColor];
    }
}

@end
