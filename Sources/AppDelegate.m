// Copyright (c) 2014 DLH

#import "AppDelegate.h"
#import "ClickableStatusItemView.h"

@implementation AppDelegate

NSStatusItem *_statusItem;
ClickableStatusItemView *_statusItemView;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    _statusItemView = [[ClickableStatusItemView alloc] initWithStatusItem:_statusItem
                                                                    image:[NSImage imageNamed:@"status-item"]
                                                           alternateImage:[NSImage imageNamed:@"status-item-alternate"]
                                                                   target:self
                                                                   action:@selector(handleClick:)
                                                                     menu:[self createMenu]];
    _statusItem.view = _statusItemView;
}

- (void)handleClick:(id)sender
{
    // The general pasteboard only holds one item
    [[NSPasteboard generalPasteboard] clearContents];
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
