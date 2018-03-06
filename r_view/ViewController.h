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

@protocol ViewControllerDelegate

- (void)updateZoom:(float)zoom pickedColor:(PickedColor *)pickedColor;

@end

@interface ViewController : NSViewController

@property (nonatomic) id<ViewControllerDelegate> delegate;
@property (nonatomic) Image *image;
@property (weak) IBOutlet ImageView *imageView;
@property (nonatomic,readonly) PickedColor *pickedColor;

- (void)zoomIn;
- (void)zoomOut;

@end

