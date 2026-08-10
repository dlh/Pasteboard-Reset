// Copyright (c) 2014 DLH

#import "AppDelegate.h"

#import <ServiceManagement/ServiceManagement.h>

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

- (void)showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

- (void)toggleLaunchAtLogin:(id)sender
{
    NSError *error = nil;
    SMAppService *service = SMAppService.mainAppService;
    BOOL shouldLaunchAtLogin = ![self isLaunchAtLoginRegistered];
    BOOL success = shouldLaunchAtLogin ? [service registerAndReturnError:&error] : [service unregisterAndReturnError:&error];

    if (!success)
    {
        [self showLaunchAtLoginError:error];
    }
}

- (NSMenu *)createMenu
{
    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"About %@", nil), self.applicationName]
                    action:@selector(showAbout:)
             keyEquivalent:@""].target = self;
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self launchAtLoginMenuItem]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", nil), self.applicationName]
                    action:@selector(quit:)
             keyEquivalent:@""].target = self;
    return menu;
}

- (NSMenuItem *)launchAtLoginMenuItem
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[self launchAtLoginMenuTitle]
                                                  action:@selector(toggleLaunchAtLogin:)
                                           keyEquivalent:@""];
    item.target = self;
    item.state = [self launchAtLoginMenuState];
    return item;
}

- (NSString *)launchAtLoginMenuTitle
{
    if (SMAppService.mainAppService.status == SMAppServiceStatusRequiresApproval)
    {
        return NSLocalizedString(@"Launch at Login (Requires Approval)", nil);
    }

    return NSLocalizedString(@"Launch at Login", nil);
}

- (NSControlStateValue)launchAtLoginMenuState
{
    switch (SMAppService.mainAppService.status)
    {
        case SMAppServiceStatusEnabled:
            return NSControlStateValueOn;
        case SMAppServiceStatusRequiresApproval:
            return NSControlStateValueMixed;
        case SMAppServiceStatusNotRegistered:
        case SMAppServiceStatusNotFound:
            return NSControlStateValueOff;
    }

    return NSControlStateValueOff;
}

- (BOOL)isLaunchAtLoginRegistered
{
    SMAppServiceStatus status = SMAppService.mainAppService.status;
    return status == SMAppServiceStatusEnabled || status == SMAppServiceStatusRequiresApproval;
}

- (void)showLaunchAtLoginError:(NSError *)error
{
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Could Not Update Launch at Login", nil);
    alert.informativeText = error.localizedDescription ?: NSLocalizedString(@"The login item setting could not be changed.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
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
