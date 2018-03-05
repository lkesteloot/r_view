//
//  ViewController.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ViewController.h"
#import "ImageView.h"

@interface ViewController () <ImageViewDelegate> {
    ImageView *_imageView;
    uint32_t _pickerColor;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _imageView = (ImageView *) self.view;
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

    uint8_t red, green, blue, alpha;

    BOOL success = [_image getRed:&red green:&green blue:&blue alpha:&alpha atX:x y:y];
    if (success) {
        _pickerColor = (red << 16) | (green << 8) | (blue << 0);
        [self update];
    }
}

- (void)update {
    if (_delegate != nil) {
        [_delegate updateZoom:_imageView.zoom picker:_pickerColor];
    }
}

@end
