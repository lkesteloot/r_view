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
            Image *image = [[Image alloc] initFromPathname:pathname];
            if (image == nil) {
                NSLog(@"Cannot convert image to our own type");
                return;
            }
            [self getImageVc].image = image;
        }
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

- (ViewController *)getImageVc {
    // We might not yet have a key window, so get the first window.
    NSWindow *mainWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:0];
    return (ViewController *) mainWindow.contentViewController;
}

// ViewControllerDelegate
- (void)updateZoom:(float)zoom pickedColor:(PickedColor *)pickedColor {
    [self updateWindowTitle];
}

- (void)updateWindowTitle {
    NSWindow *mainWindow = [[[NSApplication sharedApplication] windows] objectAtIndex:0];
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
