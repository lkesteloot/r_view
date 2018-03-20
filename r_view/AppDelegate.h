//
//  AppDelegate.h
//  r_view
//
//  Created by Lawrence Kesteloot on 3/3/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)onActualSize:(id)sender;
- (IBAction)onZoomToFit:(id)sender;
- (IBAction)onZoomIn:(id)sender;
- (IBAction)onZoomOut:(id)sender;
- (IBAction)onColorCopy:(id)sender;

@end

