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

@interface AppDelegate () <ViewControllerDelegate> {
    Image *_image;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self getImageVc].delegate = self;

    // Parse command-line parameters.
    NSArray *args = [[NSProcessInfo processInfo] arguments];

    // Skip name of command.
    NSLog(@"Full path: %@", [args objectAtIndex:0]);

    // The rest are filenames.
    for (int i = 1; i < args.count; i++) {
        // Skip "-NSDocumentRevisionsDebugMode YES", supplied by XCode.
        if (i + 1 < args.count &&
            [[args objectAtIndex:i] isEqualToString:@"-NSDocumentRevisionsDebugMode"] &&
            [[args objectAtIndex:i + 1] isEqualToString:@"YES"]) {

            i += 1;
        } else {
            NSString *pathname = [args objectAtIndex:i];
            _image = [[Image alloc] initFromPathname:pathname];
            if (_image == nil) {
                NSLog(@"Cannot convert image to our own type");
                return;
            }
            [self getImageVc].image = _image;

        }
    }
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

- (ViewController *)getImageVc {
    // We might not yet have a key window, so get the first window.
    NSWindow *mainWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:0];
    return (ViewController *) mainWindow.contentViewController;
}

// ViewControllerDelegate
- (void)updateZoom:(float)zoom picker:(uint32_t)color {
    NSWindow *mainWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:0];

    NSString *filename = [_image.pathname lastPathComponent];
    int zoomNumerator;
    int zoomDenominator;
    if (zoom >= 1) {
        zoomNumerator = (int) zoom;
        zoomDenominator = 1;
    } else {
        zoomNumerator = 1;
        zoomDenominator = (int) 1.0/zoom;
    }

    mainWindow.title = [NSString stringWithFormat:@"%@ (zoom %d:%d, color %d, %d, %d, %06X)",
                        filename, zoomNumerator, zoomDenominator,
                        (color >> 16) & 0xFF,
                        (color >> 8) & 0xFF,
                        (color >> 0) & 0xFF,
                        color];
}

@end
