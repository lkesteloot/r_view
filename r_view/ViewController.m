//
//  ViewController.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ViewController.h"
#import "ImageView.h"

@interface ViewController () {
    ImageView *_imageView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _imageView = (ImageView *) self.view;
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
    }
}

- (void)zoomOut {
    if (_imageView.zoom > 0.0625) {
        _imageView.zoom /= 2;
    }
}

@end
