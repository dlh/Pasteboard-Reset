// Copyright (c) 2014 DLH

#import "AppDelegate.h"

@implementation AppDelegate

NSStatusItem *_statusItem;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.action = @selector(handleAction:);
    NSDictionary *attributes = @{NSFontAttributeName: [NSFont fontWithName:@"pasteboard-reset" size:15]};
    _statusItem.button.attributedTitle = [[NSAttributedString alloc] initWithString:@"A" attributes:attributes];
}

- (void)handleAction:(id)sender
{
    if ([self hasInterestingModifierFlags:[NSEvent modifierFlags]])
    {
        [_statusItem popUpStatusItemMenu:[self createMenu]];
        return;
    }

    // The general pasteboard only holds one item
    [[NSPasteboard generalPasteboard] clearContents];
}

- (BOOL)hasInterestingModifierFlags:(NSEventModifierFlags)flags
{
    switch (flags & NSDeviceIndependentModifierFlagsMask)
    {
        case NSShiftKeyMask:
        case NSControlKeyMask:
        case NSAlternateKeyMask:
        case NSCommandKeyMask:
        case NSFunctionKeyMask:
            return YES;
    }
    return NO;
}

- (void)quit:(id)sender
{
    [NSApp terminate:self];
}

- (NSMenu *)createMenu
{
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", nil), self.applicationName]
                    action:@selector(quit:)
             keyEquivalent:@""].target = self;
    return menu;
}

- (NSString *)applicationName
{
    return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
}

@end
