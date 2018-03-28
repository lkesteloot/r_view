//
//  ImageView.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Image.h"

@protocol ImageViewDelegate

- (void)userSelectedPointX:(int)x y:(int)y;

@end

typedef NS_ENUM(NSInteger, ImageViewBackground) {
    ImageViewBackgroundCheckerboard,
    ImageViewBackgroundBlack,
    ImageViewBackgroundGray,
    ImageViewBackgroundWhite
};

@interface ImageView : NSView

@property (nonatomic) id<ImageViewDelegate> delegate;
@property (nonatomic) float zoom;
@property (nonatomic) ImageViewBackground background;
@property (nonatomic) Image *image;

- (CGRect)getZoomedImageRect;

@end
