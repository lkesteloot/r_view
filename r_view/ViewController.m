//
//  ViewController.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "ViewController.h"

static float LARGEST_ZOOM = 16;         // 16:1
static float SMALLEST_ZOOM = 0.0625;    // 1:16

@interface ViewController () <ImageViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Always use new-style scrollers that overlay the image.
    _scrollView.scrollerStyle = NSScrollerStyleOverlay;

    _imageView.delegate = self;
}

- (void)viewDidAppear {
    [self update];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (void)setImage:(Image *)image {
    _image = image;
    _imageView.image = image;
    _imageView.frame = CGRectMake(0, 0, image.width, image.height);
}

- (void)findBestZoomForSize:(CGSize)size {
    // Start with largest zoom and work backwards until it fits.
    float zoom = LARGEST_ZOOM;

    while (zoom > SMALLEST_ZOOM) {
        float width = ceil(_image.width*zoom);
        float height = ceil(_image.width*zoom);

        // See if it'll fit at this zoom.
        if (width <= size.width && height <= size.height) {
            break;
        }

        // Won't fit, keep trying.
        zoom /= 2;
    }

    _imageView.zoom = zoom;
    [self update];
}

// Magically called via first responder from menu item.
- (IBAction)zoomImageToFit:(id)sender {
    [self findBestZoomForSize:self.view.window.frame.size];;
}

// Magically called via first responder from menu item.
- (IBAction)zoomImageToActualSize:(id)sender {
    _imageView.zoom = 1;
    [self update];
}

// Magically called via first responder from menu item.
- (IBAction)zoomIn:(id)sender {
    if (_imageView.zoom < LARGEST_ZOOM) {
        _imageView.zoom *= 2;
        [self update];
    }
}

// Magically called via first responder from menu item.
- (IBAction)zoomOut:(id)sender {
    if (_imageView.zoom > SMALLEST_ZOOM) {
        _imageView.zoom /= 2;
        [self update];
    }
}

// Magically called via first responder from menu item.
- (IBAction)backgroundCheckerboard:(id)sender {
    _imageView.background = ImageViewBackgroundCheckerboard;
}

// Magically called via first responder from menu item.
- (IBAction)backgroundBlack:(id)sender {
    _imageView.background = ImageViewBackgroundBlack;
}

// Magically called via first responder from menu item.
- (IBAction)backgroundGray:(id)sender {
    _imageView.background = ImageViewBackgroundGray;
}

// Magically called via first responder from menu item.
- (IBAction)backgroundWhite:(id)sender {
    _imageView.background = ImageViewBackgroundWhite;
}

// Magically called via first responder from menu item.
- (IBAction)copy:(id)sender {
    if (_pickedColor != nil) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];

        [pasteboard clearContents];
        NSArray *objectsToCopy = @[
                                   [_pickedColor toRgbString],
                                   // I don't know how to test this, so I'm not including it.
                                   // [_pickedColor toNsColor]
                                   ];
        BOOL success = [pasteboard writeObjects:objectsToCopy];
        if (!success) {
            NSLog(@"Failed to copy color to pasteboard");
        }
    }
}

// Called by File->New.
- (IBAction)newDocument:(id)sender {
    // Create new image from pasteboard.
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSImage class]];
    NSDictionary *options = [NSDictionary dictionary];
    BOOL pasteboardHasImage = [pasteboard canReadObjectForClasses:classArray options:options];
    if (pasteboardHasImage) {
        // Make a document from the pasteboard.
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSImage *nsImage = [objectsToPaste objectAtIndex:0];
        Image *image = [[Image alloc] initWithImage:nsImage];
        
        // Add it to the list of documents we're managing.
        [[NSDocumentController sharedDocumentController] addDocument:image];
        
        // Show it.
        [image makeWindowControllers];
        [image showWindows];
    }
}

// Magically called via first responder from menu item.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    BOOL enabled;

    SEL action = menuItem.action;
    if (action == @selector(zoomImageToActualSize:)) {
        enabled = _imageView.zoom != 1;
    } else if (action == @selector(zoomIn:)) {
        enabled = _imageView.zoom < LARGEST_ZOOM;
    } else if (action == @selector(zoomOut:)) {
        enabled = _imageView.zoom > SMALLEST_ZOOM;
    } else if (action == @selector(copy:)) {
        enabled = _pickedColor != nil;
    } else if (action == @selector(backgroundCheckerboard:)) {
        enabled = _image.isSemiTransparent;
        menuItem.state = _imageView.background == ImageViewBackgroundCheckerboard
            ? NSControlStateValueOn : NSControlStateValueOff;
    } else if (action == @selector(backgroundBlack:)) {
        enabled = _image.isSemiTransparent;
        menuItem.state = _imageView.background == ImageViewBackgroundBlack
            ? NSControlStateValueOn : NSControlStateValueOff;
    } else if (action == @selector(backgroundGray:)) {
        enabled = _image.isSemiTransparent;
        menuItem.state = _imageView.background == ImageViewBackgroundGray
            ? NSControlStateValueOn : NSControlStateValueOff;
    } else if (action == @selector(backgroundWhite:)) {
        enabled = _image.isSemiTransparent;
        menuItem.state = _imageView.background == ImageViewBackgroundWhite
            ? NSControlStateValueOn : NSControlStateValueOff;
    } else if (action == @selector(newDocument:)) {
        // See if the pasteboard has an image.
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        NSArray *classArray = [NSArray arrayWithObject:[NSImage class]];
        NSDictionary *options = [NSDictionary dictionary];
        enabled = [pasteboard canReadObjectForClasses:classArray options:options];
    } else {
        // We can't bubble up (super doesn't implement this method),
        // so return YES as per instructions ("Enabling Menu Items").
        enabled = YES;
    }

    return enabled;
}

// ImageViewDelegate
- (void)userSelectedPointX:(int)x y:(int)y {
    [self userSelectedPointX:x y:y propagate:YES];
}

- (void)userSelectedPointX:(int)x y:(int)y propagate:(BOOL)propagate {
    PickedColor *pickedColor = [_image sampleAtX:x y:y];
    if (pickedColor != nil) {
        _pickedColor = pickedColor;
        [self update];
    }

    if (propagate) {
        // Send this pick to all other window tabs in this window.
        for (NSWindow *window in self.view.window.tabbedWindows) {
            if (window != self.view.window) {
                NSViewController *vc = window.contentViewController;
                if ([vc isKindOfClass:[ViewController class]]) {
                    ViewController *other = (ViewController *) vc;
                    [other userSelectedPointX:x y:y propagate:NO];
                }
            }
        }
    }
}

// XXX Maybe rename.
- (void)update {
    // Cause the title to refresh.
    [self.view.window.windowController synchronizeWindowTitleWithDocumentName];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    NSString *title = displayName;

    if (_image != nil) {
        NSString *zoomString;
        float zoom = _imageView.zoom;
        if (zoom == 1) {
            zoomString = nil;
        } else {
            int zoomNumerator;
            int zoomDenominator;
            if (zoom >= 1) {
                zoomNumerator = (int) zoom;
                zoomDenominator = 1;
            } else {
                zoomNumerator = 1;
                zoomDenominator = (int) 1.0/zoom;
            }
            zoomString = [NSString stringWithFormat:@"zoom %d:%d", zoomNumerator, zoomDenominator];
        }

        NSString *pickedColorString = _pickedColor == nil ? nil : [_pickedColor toString];

        if (zoomString != nil || pickedColorString != nil) {
            title = [title stringByAppendingString:@" – "];
            if (zoomString != nil) {
                title = [title stringByAppendingString:zoomString];
                if (pickedColorString != nil) {
                    title = [title stringByAppendingString:@" – "];
                }
            }

            if (pickedColorString != nil) {
                title = [title stringByAppendingString:pickedColorString];
            }
        }
    }

    return title;
}

@end
