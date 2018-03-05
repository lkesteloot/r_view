//
//  ViewController.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Image.h"

@protocol ViewControllerDelegate

- (void)updateZoom:(float)zoom picker:(uint32_t)color;

@end

@interface ViewController : NSViewController

@property (nonatomic) id<ViewControllerDelegate> delegate;
@property (nonatomic) Image *image;

- (void)zoomIn;
- (void)zoomOut;

@end

