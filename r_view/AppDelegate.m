//
//  AppDelegate.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Lawrence Kesteloot. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "Image.h"

@interface AppDelegate () <ViewControllerDelegate>

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    ViewController *vc = [self getImageVc];
    vc.delegate = self;

    // Parse command-line parameters.
    NSArray *args = [[NSProcessInfo processInfo] arguments];

    // Skip name of command.
    NSLog(@"Full path: %@", [args objectAtIndex:0]);

    // The rest are filenames.
    Image *mainImage = nil;
    for (int i = 1; i < args.count; i++) {
        // Skip "-NSDocumentRevisionsDebugMode YES", supplied by XCode.
        if (i + 1 < args.count &&
            [[args objectAtIndex:i] isEqualToString:@"-NSDocumentRevisionsDebugMode"] &&
            [[args objectAtIndex:i + 1] isEqualToString:@"YES"]) {

            i += 1;
        } else {
            NSString *pathname = [args objectAtIndex:i];
            Image *image = [[Image alloc] initFromPathname:pathname];
            if (image == nil) {
                NSLog(@"Cannot convert image to our own type");
                return;
            }
            [self getImageVc].image = image;
            mainImage = image;
        }
    }

    // Find the best size for our window.
    if (mainImage != nil) {
        // Get the window we'll be displaying.
        NSWindow *window = [self getMainWindow];

        // Get the screen that we plan to display on.
        // XXX not always correct. If Xcode is on one screen and the last position of the
        // window (last time it ran) was on another, here we'll get the other and position
        // ourselves based on that, but the window will actually show on Xcode's screen.
        NSScreen * screen = window.screen;

        // Find the visible frame of the screen.
        NSRect screenVisibleRect = screen.visibleFrame;

        // We don't care about the position of the screen.
        screenVisibleRect.origin.x = 0;
        screenVisibleRect.origin.y = 0;

        // Convert that from a window frame size to a window content size.
        CGRect windowContentRect = [window contentRectForFrameRect:screenVisibleRect];

        // Find the best zoom for this rect. This is the largest zoom that still fits.
        // I wonder if we should max the zoom out at 1:1 here, so that it's never
        // zoomed in by default.
        [vc findBestZoomForSize:windowContentRect.size];

        // Find the content frame for this zoom.
        windowContentRect = [vc.imageView getZoomedImageRect];

        // Convert that back to a window frame rect.
        CGRect windowFrameRect = [window frameRectForContentRect:windowContentRect];

        // Center the window in the screen.
        windowFrameRect.origin.x = (screenVisibleRect.size.width - windowFrameRect.size.width)/2;
        windowFrameRect.origin.y = (screenVisibleRect.size.height - windowFrameRect.size.height)/2;

        // Move the window there.
        [window setFrame:windowFrameRect display:YES animate:NO];
    }

    [self updateWindowTitle];
}

- (IBAction)onActualSize:(id)sender {
}

- (IBAction)onZoomToFit:(id)sender {
}

- (IBAction)onZoomIn:(id)sender {
    [[self getImageVc] zoomIn];
}

- (IBAction)onZoomOut:(id)sender {
    [[self getImageVc] zoomOut];
}

- (NSWindow *)getMainWindow {
    // We might not yet have a key window, so get the first window.
    return [[[NSApplication sharedApplication] windows] objectAtIndex:0];
}

- (ViewController *)getImageVc {
    return (ViewController *) [self getMainWindow].contentViewController;
}

// ViewControllerDelegate
- (void)updateZoom:(float)zoom pickedColor:(PickedColor *)pickedColor {
    [self updateWindowTitle];
}

- (void)updateWindowTitle {
    NSWindow *mainWindow = [self getMainWindow];
    ViewController *vc = [self getImageVc];
    Image *image = vc.image;

    NSString *title = @"r_view";

    if (image != nil) {
        NSString *filename = [image.pathname lastPathComponent];
        if (filename != nil) {
            title = filename;
        }

        NSString *zoomString;
        float zoom = vc.imageView.zoom;
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

        PickedColor *pickedColor = vc.pickedColor;
        NSString *pickedColorString = pickedColor == nil ? nil : [pickedColor toString];

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

    mainWindow.title = title;
}

@end
