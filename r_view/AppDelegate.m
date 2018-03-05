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

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
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
            NSLog(@"Image to show: %@", pathname);
            NSImage *nsImage = [[NSImage alloc] initWithContentsOfFile:pathname];
            NSLog(@"Image: %@", nsImage);
            Image *image = [[Image alloc] initFromNsImage:nsImage];
            if (image == nil) {
                NSLog(@"Cannot convert image to our own type");
                return;
            }
            [self getImageVc].image = image;

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

@end
