//
//  Image.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/4/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface Image : NSObject

@property (nonatomic,readonly) NSImage *nsImage;

- (id)initFromNsImage:(NSImage *)nsImage;

- (BOOL)getRed:(uint8_t *)red green:(uint8_t *)green blue:(uint8_t *)blue alpha:(uint8_t *)alpha atX:(int)x y:(int)y;

@end
