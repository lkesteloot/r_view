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

    // Always use new-style scrollers that overlay the image.
    _scrollView.scrollerStyle = NSScrollerStyleOverlay;

    _imageView.delegate = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (void)setImage:(Image *)image {
    _image = image;
    _imageView.image = image;
    _imageView.frame = CGRectMake(0, 0, image.width, image.height);
}

- (void)resetZoom {
    _imageView.zoom = 1;
    [self update];
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

- (void)zoomIn {
    if (_imageView.zoom < LARGEST_ZOOM) {
        _imageView.zoom *= 2;
        [self update];
    }
}

- (void)zoomOut {
    if (_imageView.zoom > SMALLEST_ZOOM) {
        _imageView.zoom /= 2;
        [self update];
    }
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
