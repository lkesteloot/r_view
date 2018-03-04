//
//  ViewController.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ViewController.h"
#import "ImageView.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.

    // XXX what is this?
}

- (void)setImage:(NSImage *)image {
    _image = image;
    ImageView *imageView = (ImageView *) self.view;
    imageView.image = image;
}

@end
