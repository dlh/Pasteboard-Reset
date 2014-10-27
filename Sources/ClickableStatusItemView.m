// Copyright (c) 2014 DLH

#import "ClickableStatusItemView.h"

@interface ClickableStatusItemView ()
- (void)setUseAlternateImage:(BOOL)newValue;
@end


@interface MenuDelegate : NSObject<NSMenuDelegate>
@property (strong, nonatomic) ClickableStatusItemView *view;
- initWithViewController:(ClickableStatusItemView *)view;
@end


@implementation ClickableStatusItemView

BOOL _useAlternateImage = NO;
MenuDelegate *_menuDelegate;

- initWithStatusItem:(NSStatusItem *)statusItem
               image:(NSImage *)image
      alternateImage:(NSImage *)alternateImage
              target:(id)target
              action:(SEL)action
                menu:(NSMenu *)menu;
{
    if (self = [super initWithFrame:NSZeroRect])
    {
        self.statusItem = statusItem;
        self.image = image;
        self.alternateImage = alternateImage;
        self.target = target;
        self.action = action;
        self.menu = menu;
        self.menu.delegate = _menuDelegate = [[MenuDelegate alloc] initWithViewController:self];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSImage *image = self.image;
    if (_useAlternateImage)
    {
        image = self.alternateImage;
        [self.statusItem drawStatusBarBackgroundInRect:rect withHighlight:YES];
    }
    [image drawInRect:NSMakeRect(0, 0, image.size.width, image.size.height)
             fromRect:NSZeroRect
            operation:NSCompositeSourceOver
             fraction:1];
    // NSLog(@"Drawing in rect %@", CGRectCreateDictionaryRepresentation(rect));
}

- (void)mouseDown:(NSEvent *)event
{
    [self setUseAlternateImage:YES];
    if ([event modifierFlags] & NSCommandKeyMask)
        [self rightMouseDown:event];
    else
        [NSApp sendAction:self.action to:self.target from:self];
}

- (void)mouseUp:(NSEvent *)event
{
    [self setUseAlternateImage:NO];
}

- (void)rightMouseDown:(NSEvent *)event
{
    [self setUseAlternateImage:YES];
    [self.statusItem popUpStatusItemMenu:self.menu];
}

- (void)rightMouseUp:(NSEvent *)event
{
    [self setUseAlternateImage:NO];
}

- (void)setUseAlternateImage:(BOOL)newValue
{
    if (newValue != _useAlternateImage)
    {
        _useAlternateImage = newValue;
        self.needsDisplay = YES;
    }
}

@end


@implementation MenuDelegate

- initWithViewController:(ClickableStatusItemView *)view
{
    if (self = [super init])
    {
        self.view = view;
    }
    return self;
}

- (void)menuDidClose:(NSMenu *)menu
{
    [self.view setUseAlternateImage:NO];
}

@end
