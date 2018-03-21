//
//  WindowController.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/20/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "WindowController.h"
#import "ViewController.h"

@implementation WindowController

// For NSWindowController:
- (void)setDocument:(NSDocument *)document {
    [super setDocument:document];

    [self updateDocument];
}

// For NSWindowController:
- (void)windowDidLoad {
    [super windowDidLoad];

    [self updateDocument];
}

// For NSWindowController:
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    ViewController *viewController = (ViewController *) self.contentViewController;
    return [viewController windowTitleForDocumentDisplayName:displayName];
}

- (void)updateDocument {
    ViewController *viewController = (ViewController *) self.contentViewController;
    if (viewController != nil && self.document != nil) {
        viewController.image = (Image *) self.document;
    }
}

@end
