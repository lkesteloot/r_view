//
//  Image.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/4/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "Image.h"

@interface Image () {
    int _stride;
    uint8_t *_data;
}

@end

@implementation Image

- (id)initFromPathname:(NSString *)pathname {
    self = [super init];

    if (self) {
        _pathname = pathname;

        NSImage *nsImage = [[NSImage alloc] initWithContentsOfFile:pathname];
        NSLog(@"Image: %@", nsImage);

        _nsImage = nsImage;

        // First, grab the raw pixels before we draw this image. As soon as an image is
        // drawn, its internal representation is changed to match the display and the
        // original data is lost.
        NSImageRep *rep = [nsImage.representations objectAtIndex:0];
        _width = (int) rep.pixelsWide;
        _height = (int) rep.pixelsHigh;

        if (![rep isKindOfClass:[NSBitmapImageRep class]]) {
            NSLog(@"Representation isn't bitmap: %@", rep);
            return nil;
        }

        NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *) rep;

        // Make sure we handle this format.
        if ((bitmapRep.bitmapFormat & NSAlphaFirstBitmapFormat) != 0) {
            NSLog(@"We do not handle alpha-first formats");
            return nil;
        }
        if ((bitmapRep.bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) != 0) {
            NSLog(@"We do not handle alpha non-premultiplied formats");
            return nil;
        }
        if ((bitmapRep.bitmapFormat & NSFloatingPointSamplesBitmapFormat) != 0) {
            NSLog(@"We do not handle floating point formats");
            return nil;
        }
        if ((bitmapRep.bitmapFormat & (NS16BitLittleEndianBitmapFormat|NS16BitBigEndianBitmapFormat)) != 0) {
            NSLog(@"We do not handle 16-bit formats");
            return nil;
        }
        if ((bitmapRep.bitmapFormat & (NS32BitLittleEndianBitmapFormat|NS32BitBigEndianBitmapFormat)) != 0) {
            NSLog(@"We do not handle 32-bit formats");
            return nil;
        }
        if (bitmapRep.bitsPerSample != 8) {
            NSLog(@"We do not handle %d bits per sample", (int) bitmapRep.bitsPerSample);
            return nil;
        }
        if (/* bitmapRep.bitsPerPixel != 24 && */ bitmapRep.bitsPerPixel != 32) {
            NSLog(@"We do not handle %d bits per pixel formats", (int) bitmapRep.bitsPerPixel);
            return nil;
        }
        if (bitmapRep.planar) {
            NSLog(@"We do not handle planar formats");
            return nil;
        }
        if (bitmapRep.samplesPerPixel != 3 && bitmapRep.samplesPerPixel != 4) {
            NSLog(@"We do not handle %d components per pixel", (int) bitmapRep.samplesPerPixel);
            return nil;
        }
        _stride = (int) bitmapRep.bytesPerRow;
        if (_stride != _width*bitmapRep.bitsPerPixel/8) {
            NSLog(@"We do not handle padded strides (%d != %d*%d/8 = %d)",
                  _stride, _width, (int) bitmapRep.bitsPerPixel,
                  (int) (_width*bitmapRep.bitsPerPixel/8));
            return nil;
        }

        // We should now be RGBA 8-bit format.

        NSLog(@"samplesPerPixel = %d, bitsPerPixel = %d, bitsPerSample = %d, stride = %d, width = %d",
              (int) bitmapRep.samplesPerPixel, (int) bitmapRep.bitsPerPixel, (int) bitmapRep.bitsPerSample,
              _stride, _width);

        // Copy it for safekeeping.
        int byteCount = _stride*_height;
        _data = (uint8_t *) malloc(byteCount);
        memcpy(_data, bitmapRep.bitmapData, byteCount);
    }

    return self;
}

- (BOOL)getRed:(uint8_t *)red green:(uint8_t *)green blue:(uint8_t *)blue alpha:(uint8_t *)alpha atX:(int)x y:(int)y {
    if (x < 0 || y < 0 || x >= _width || y >= _height) {
        return NO;
    }

    uint8_t *pixel = &_data[y*_stride + x*4];

    *red = pixel[0];
    *green = pixel[1];
    *blue = pixel[2];
    *alpha = pixel[3];

    return YES;
}

@end
