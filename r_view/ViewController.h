//
//  ViewController.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (nonatomic) NSImage *image;

- (void)zoomIn;
- (void)zoomOut;

@end

