// Copyright (c) 2014 DLH

#import "StatusItemIcon.h"

@implementation StatusItemIcon

static const CGFloat StatusItemGlyphSize = 16.0;
static NSString * const StatusItemGlyph = @"A";
static NSString * const StatusItemGlyphFontName = @"pasteboard-reset";

+ (NSImage *)imageWithAccessibilityDescription:(NSString *)accessibilityDescription
{
    NSFont *font = [NSFont fontWithName:StatusItemGlyphFontName size:StatusItemGlyphSize] ?: [NSFont systemFontOfSize:StatusItemGlyphSize];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: NSColor.blackColor
    };
    NSSize glyphSize = [StatusItemGlyph sizeWithAttributes:attributes];
    NSImage *image = [[NSImage alloc] initWithSize:glyphSize];
    image.template = YES;
    image.accessibilityDescription = accessibilityDescription;

    [image lockFocus];
    [StatusItemGlyph drawInRect:NSMakeRect(0.0, 0.0, glyphSize.width, glyphSize.height)
                 withAttributes:attributes];
    [image unlockFocus];

    return image;
}

@end
