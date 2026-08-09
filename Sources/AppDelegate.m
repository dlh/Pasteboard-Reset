// Copyright (c) 2014 DLH

#import "AppDelegate.h"

@interface AppDelegate () <NSMenuDelegate>
@end

@implementation AppDelegate

NSStatusItem *_statusItem;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.action = @selector(handleAction:);
    NSDictionary *attributes = @{NSFontAttributeName: [NSFont fontWithName:@"pasteboard-reset" size:15]};
    _statusItem.button.attributedTitle = [[NSAttributedString alloc] initWithString:@"A" attributes:attributes];
}

- (void)handleAction:(id)sender
{
    if ([self hasInterestingModifierFlags:NSApp.currentEvent.modifierFlags])
    {
        _statusItem.menu = [self createMenu];
        [_statusItem.button performClick:sender];
        return;
    }

    // The general pasteboard only holds one item
    [[NSPasteboard generalPasteboard] clearContents];
}

- (BOOL)hasInterestingModifierFlags:(NSEventModifierFlags)flags
{
    NSEventModifierFlags interestingFlags = NSEventModifierFlagShift |
                                            NSEventModifierFlagControl |
                                            NSEventModifierFlagOption |
                                            NSEventModifierFlagCommand |
                                            NSEventModifierFlagFunction;
    return (flags & interestingFlags) != 0;
}

- (void)quit:(id)sender
{
    [NSApp terminate:self];
}

- (NSMenu *)createMenu
{
    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", nil), self.applicationName]
                    action:@selector(quit:)
             keyEquivalent:@""].target = self;
    return menu;
}

- (void)menuDidClose:(NSMenu *)menu
{
    _statusItem.menu = nil;
}

- (NSString *)applicationName
{
    return [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
}

@end
