//
//  ViewController.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Image.h"
#import "ImageView.h"
#import "PickedColor.h"

@interface ViewController : NSViewController

@property (nonatomic) Image *image;
@property (strong) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet ImageView *imageView;
@property (nonatomic,readonly) PickedColor *pickedColor;

- (void)findBestZoomForSize:(CGSize)size;

@end

