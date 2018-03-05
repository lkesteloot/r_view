//
//  ImageView.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Image.h"

@interface ImageView : NSView

@property (nonatomic) float zoom;
@property (nonatomic) Image *image;

@end
