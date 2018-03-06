//
//  ViewController.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ImageViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _imageView.delegate = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.

    // XXX what is this?
}

- (void)setImage:(Image *)image {
    _image = image;
    _imageView.image = image;
    _imageView.frame = CGRectMake(0, 0, image.width, image.height);
}

- (void)zoomIn {
    if (_imageView.zoom < 16) {
        _imageView.zoom *= 2;
        [self update];
    }
}

- (void)zoomOut {
    if (_imageView.zoom > 0.0625) {
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
