// Copyright (c) 2014 DLH

#import "StatusItemIcon.h"

@implementation StatusItemIcon

static const CGFloat StatusItemGlyphSize = 16.0;
static NSString *const StatusItemGlyph = @"A";
static NSString *const StatusItemGlyphFontName = @"pasteboard-reset";

+ (NSImage *)imageWithAccessibilityDescription:(NSString *)accessibilityDescription
{
    NSFont *font = [NSFont fontWithName:StatusItemGlyphFontName size:StatusItemGlyphSize]
                       ?: [NSFont systemFontOfSize:StatusItemGlyphSize];
    NSDictionary *attributes = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : NSColor.blackColor };
    NSSize glyphSize = [StatusItemGlyph sizeWithAttributes:attributes];
    NSImage *image = [NSImage imageWithSize:glyphSize
                                    flipped:NO
                             drawingHandler:^BOOL(NSRect dstRect) {
                                 [StatusItemGlyph drawInRect:dstRect withAttributes:attributes];
                                 return YES;
                             }];
    image.template = YES;
    image.accessibilityDescription = accessibilityDescription;

    return image;
}

@end
