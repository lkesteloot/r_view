//
//  Image.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/4/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "Image.h"

@interface Image () {
    int _rowStride;
    int _pixelStride;
    int _redIndex;
    int _greenIndex;
    int _blueIndex;
    int _alphaIndex; // -1 if no alpha.
    uint8_t *_data;
}

@end

@implementation Image

- (instancetype)initWithImage:(NSImage *)image {
    self = [super init];
    // We don't handle errors from this function. Not sure what we'd do.
    // We're not permitted to return nil. Maybe store the error and have
    // a separate getting to figure it out.
    [self configureFromImage:image error:nil];
    return self;
}

// For NSDocument:
- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError {

    NSImage *nsImage = [[NSImage alloc] initWithData:data];
    return [self configureFromImage:nsImage error:outError];
}

- (BOOL)configureFromImage:(NSImage *)nsImage error:(NSError **)outError {
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
    _rowStride = (int) bitmapRep.bytesPerRow;

    NSLog(@"samplesPerPixel = %d, bitsPerPixel = %d, bitsPerSample = %d, stride = %d, width = %d",
          (int) bitmapRep.samplesPerPixel, (int) bitmapRep.bitsPerPixel, (int) bitmapRep.bitsPerSample,
          _rowStride, _width);

    // Make sure we handle this format.
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
    if (bitmapRep.planar) {
        NSLog(@"We do not handle planar formats");
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
    _pixelStride = (int) bitmapRep.bitsPerPixel/8;

    // Figure out where RGB are.
    switch (bitmapRep.samplesPerPixel) {
        case 1:
        case 2:
            // Luminance image.
            _redIndex = 0;
            _greenIndex = 0;
            _blueIndex = 0;
            break;

        case 3:
        case 4:
            // RGB image.
            _redIndex = 0;
            _greenIndex = 1;
            _blueIndex = 2;
            break;

        default:
            NSLog(@"We do not handle %d samples per pixel", (int) bitmapRep.samplesPerPixel);
            if (outError != nil) {
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:NSFileReadCorruptFileError
                                            userInfo:nil];
            }
            return NO;
    }

    // Figure out where alpha is.
    BOOL alphaFirst = (bitmapRep.bitmapFormat & NSAlphaFirstBitmapFormat) != 0;
    if (bitmapRep.samplesPerPixel == 2 || bitmapRep.samplesPerPixel == 4) {
        if (alphaFirst) {
            NSLog(@"Warning: Alpha-first formats are not tested.");
            _alphaIndex = 0;
            _redIndex += 1;
            _greenIndex += 1;
            _blueIndex += 1;
        } else {
            // Alpha last.
            _alphaIndex = (int) bitmapRep.samplesPerPixel - 1;
        }
    } else {
        // No alpha.
        _alphaIndex = -1;
    }
    if (_rowStride != _width*_pixelStride) {
        NSLog(@"Warning: Padded row strides are untested (%d != %d*%d = %d)",
              _rowStride, _width, _pixelStride, _width*_pixelStride);
    }

    BOOL alphaPremultiplied = (bitmapRep.bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) == 0;
    if (alphaPremultiplied && _alphaIndex >= 0) {
        // It's not so much that we don't support them, it's that we've never tried it
        // and don't know how we should act differently.
        NSLog(@"Warning: Alpha premultiplied formats are not tested");
    }

    // Copy image for safekeeping.
    int byteCount = _rowStride*_height;
    _data = (uint8_t *) malloc(byteCount);
    memcpy(_data, bitmapRep.bitmapData, byteCount);

    // See if we're semi-transparent.
    _isSemiTransparent = NO;
    if (_alphaIndex >= 0) {
        for (int y = 0; y < _height && !_isSemiTransparent; y++) {
            uint8_t *alpha = &_data[y*_rowStride] + _alphaIndex;
            for (int x = 0; x < _width; x++) {
                if (*alpha != 0xFF) {
                    _isSemiTransparent = YES;
                    break;
                }
                alpha += _pixelStride;
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
    NSLog(@"windowController: %@, window: %@", windowController, windowController.window);
    windowController.window.minSize = NSMakeSize(self.width, self.height);
    [self addWindowController:windowController];
}

- (PickedColor *)sampleAtX:(int)x y:(int)y {
    if (x < 0 || y < 0 || x >= _width || y >= _height) {
        return nil;
    }

    uint8_t *pixel = &_data[y*_rowStride + x*_pixelStride];

    PickedColor *pickedColor = [[PickedColor alloc] init];

    pickedColor.x = x;
    pickedColor.y = y;
    pickedColor.red = pixel[_redIndex];
    pickedColor.green = pixel[_greenIndex];
    pickedColor.blue = pixel[_blueIndex];
    pickedColor.alpha = _alphaIndex >= 0 ? pixel[_alphaIndex] : 0xFF;
    pickedColor.hasAlpha = _alphaIndex;

    return pickedColor;
}

@end
