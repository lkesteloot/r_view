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
- (void)updateZoom:(float)zoom pickedColor:(PickedColor *)pickedColor {
    NSWindow *mainWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:0];

    NSString *filename = [_image.pathname lastPathComponent];

    NSString *zoomString;
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

    NSString *pickedColorString = pickedColor == nil ? nil : [pickedColor toString];

    NSString *title = filename == nil ? @"r_view" : filename;

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

    mainWindow.title = title;
}

@end
