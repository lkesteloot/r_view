//
//  AppDelegate.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "AppDelegate.h"

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
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:pathname];
            NSLog(@"Image: %@", image);
        }
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
