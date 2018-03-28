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
    int _bytesPerPixel;
    BOOL _alphaPremultiplied;
    BOOL _hasAlpha;
    uint8_t *_data;
}

@end

@implementation Image

// For NSDocument:
- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError {

    NSImage *nsImage = [[NSImage alloc] initWithData:data];

    _nsImage = nsImage;

    // First, grab the raw pixels before we draw this image. As soon as an image is
    // drawn, its internal representation is changed to match the display and the
    // original data is lost.
    NSImageRep *rep = [nsImage.representations objectAtIndex:0];
    _width = (int) rep.pixelsWide;
    _height = (int) rep.pixelsHigh;

    if (![rep isKindOfClass:[NSBitmapImageRep class]]) {
        NSLog(@"Representation isn't bitmap: %@", rep);
        if (outError != nil) {
            // See /System/Library/Frameworks/Foundation.framework/Versions/C/Headers/FoundationErrors.h
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }

    NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *) rep;

    // Make sure we handle this format.
    if ((bitmapRep.bitmapFormat & NSAlphaFirstBitmapFormat) != 0) {
        NSLog(@"We do not handle alpha-first formats");
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    if ((bitmapRep.bitmapFormat & NSFloatingPointSamplesBitmapFormat) != 0) {
        NSLog(@"We do not handle floating point formats");
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    if ((bitmapRep.bitmapFormat & (NS16BitLittleEndianBitmapFormat|NS16BitBigEndianBitmapFormat)) != 0) {
        NSLog(@"We do not handle 16-bit formats");
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    if ((bitmapRep.bitmapFormat & (NS32BitLittleEndianBitmapFormat|NS32BitBigEndianBitmapFormat)) != 0) {
        NSLog(@"We do not handle 32-bit formats");
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    if (bitmapRep.bitsPerSample != 8) {
        NSLog(@"We do not handle %d bits per sample", (int) bitmapRep.bitsPerSample);
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    if (bitmapRep.bitsPerPixel != 8 && bitmapRep.bitsPerPixel != 16 &&
        bitmapRep.bitsPerPixel != 24 && bitmapRep.bitsPerPixel != 32) {

        NSLog(@"We do not handle %d bits per pixel formats", (int) bitmapRep.bitsPerPixel);
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    _bytesPerPixel = (int) bitmapRep.bitsPerPixel/8;
    _hasAlpha = _bytesPerPixel == 2 || _bytesPerPixel == 4;
    if (bitmapRep.planar) {
        NSLog(@"We do not handle planar formats");
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    if (bitmapRep.samplesPerPixel != 1 && bitmapRep.samplesPerPixel != 2 &&
        bitmapRep.samplesPerPixel != 3 && bitmapRep.samplesPerPixel != 4) {

        NSLog(@"We do not handle %d components per pixel", (int) bitmapRep.samplesPerPixel);
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    // Sanity check.
    if (_bytesPerPixel != bitmapRep.samplesPerPixel) {
        NSLog(@"Bytes per pixel (%d) don't equal samples per pixel (%d)", _bytesPerPixel, (int) bitmapRep.samplesPerPixel);
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }
    _stride = (int) bitmapRep.bytesPerRow;
    if (_stride != _width*bitmapRep.bitsPerPixel/8) {
        NSLog(@"We do not handle padded strides (%d != %d*%d/8 = %d)",
              _stride, _width, (int) bitmapRep.bitsPerPixel,
              (int) (_width*bitmapRep.bitsPerPixel/8));
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }

    _alphaPremultiplied = (bitmapRep.bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) == 0;
    if (_alphaPremultiplied && bitmapRep.samplesPerPixel == 4) {
        // It's not so much that we don't support them, it's that we've never tried it
        // and don't know how we should act differently.
        NSLog(@"We do not handle alpha premultiplied formats");
        if (outError != nil) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadCorruptFileError
                                        userInfo:nil];
        }
        return NO;
    }

    // We should now be L, LA, RGB, or RGBA 8-bit format.

    NSLog(@"samplesPerPixel = %d, bitsPerPixel = %d, bitsPerSample = %d, stride = %d, width = %d",
          (int) bitmapRep.samplesPerPixel, (int) bitmapRep.bitsPerPixel, (int) bitmapRep.bitsPerSample,
          _stride, _width);

    // Copy it for safekeeping.
    int byteCount = _stride*_height;
    _data = (uint8_t *) malloc(byteCount);
    memcpy(_data, bitmapRep.bitmapData, byteCount);

    // See if we're semi-transparent.
    _isSemiTransparent = NO;
    if (_hasAlpha) {
        int alphaIndex = _bytesPerPixel - 1;
        for (int y = 0; y < _height && !_isSemiTransparent; y++) {
            uint8_t *pixel = &_data[y*_stride];
            for (int x = 0; x < _width; x++) {
                if (pixel[alphaIndex] != 0xFF) {
                    _isSemiTransparent = YES;
                    break;
                }
                pixel += _bytesPerPixel;
            }
        }
    }

    return YES;
}

// For NSDocument:
+ (BOOL)autosavesInPlace {
    // Don't want autosave. We don't save at all.
    return NO;
}

// For NSDocument:
- (void)makeWindowControllers {
    NSWindowController *windowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"Document Window Controller"];
    [self addWindowController:windowController];
}

- (PickedColor *)sampleAtX:(int)x y:(int)y {
    if (x < 0 || y < 0 || x >= _width || y >= _height) {
        return nil;
    }

    uint8_t *pixel = &_data[y*_stride + x*_bytesPerPixel];

    PickedColor *pickedColor = [[PickedColor alloc] init];

    pickedColor.x = x;
    pickedColor.y = y;
    if (_bytesPerPixel >= 3) {
        pickedColor.red = pixel[0];
        pickedColor.green = pixel[1];
        pickedColor.blue = pixel[2];
    } else {
        pickedColor.red = pixel[0];
        pickedColor.green = pixel[0];
        pickedColor.blue = pixel[0];
    }
    pickedColor.alpha = _hasAlpha ? pixel[_bytesPerPixel - 1] : 0xFF;
    pickedColor.hasAlpha = _hasAlpha;

    return pickedColor;
}

@end
