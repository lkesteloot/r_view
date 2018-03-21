//
//  AppDelegate.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Lawrence Kesteloot. All rights reserved.
//

#import "AppDelegate.h"
#import "Image.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    /*
    // Find the best size for our window.
    if (mainImage == nil) {
        [NSApp terminate:self];
    } else {
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

     */
}

/*
- (IBAction)onColorCopy:(id)sender {
    ViewController *vc = [self getImageVc];
    PickedColor *pickedColor = vc.pickedColor;

    if (pickedColor != nil) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];

        [pasteboard clearContents];
        NSArray *objectsToCopy = @[
                                   [pickedColor toRgbString],
                                   [pickedColor toNsColor]   // Untested.
                                   ];
        BOOL success = [pasteboard writeObjects:objectsToCopy];
        if (!success) {
            NSLog(@"Failed to copy color to pasteboard");
        }
    }
}
*/
@end
