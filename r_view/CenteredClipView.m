//
//  CenteredClipView.m
//  r_view
//
//  Created by Lawrence Kesteloot on 3/7/18.
//  Copyright © 2018 Team Ten. All rights reserved.
//

#import "CenteredClipView.h"

@implementation CenteredClipView

- (NSRect)constrainBoundsRect:(NSRect)rect {
    rect = [super constrainBoundsRect:rect];

    NSRect documentRect = [self.documentView frame];

    if (documentRect.size.width < rect.size.width) {
        rect.origin.x = (documentRect.size.width - rect.size.width)/2;
    }
    if (documentRect.size.height < rect.size.height) {
        rect.origin.y = (documentRect.size.height - rect.size.height)/2;
    }

    return rect;
}

@end
