// Copyright (c) 2014 DLH

#import "AppDelegate.h"
#import "LaunchAtLoginController.h"
#import "PreferencesController.h"
#import "StatusItemButton.h"

@interface AppDelegate () <NSMenuDelegate>
@property (nonatomic, assign) NSInteger clearFeedbackToken;
@property (nonatomic, strong) LaunchAtLoginController *launchAtLoginController;
@property (nonatomic, strong) PreferencesController *preferencesController;
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.launchAtLoginController = [[LaunchAtLoginController alloc] init];
    self.preferencesController = [[PreferencesController alloc] init];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [StatusItemButton configureButton:_statusItem.button target:self action:@selector(handleAction:)];
}

- (void)handleAction:(id)sender
{
    if ([self shouldOpenMenuForEvent:NSApp.currentEvent])
    {
        _statusItem.menu = [self createMenu];
        [_statusItem.button performClick:sender];
        return;
    }

    [[NSPasteboard generalPasteboard] clearContents];
    if (_preferencesController.clickAnimationEnabled)
    {
        [self showClearFeedback];
    }
}

- (void)showClearFeedback
{
    _clearFeedbackToken += 1;
    NSInteger feedbackToken = _clearFeedbackToken;
    NSButton *button = _statusItem.button;

    [StatusItemButton showClearFeedbackForButton:button completion:^{
        if (feedbackToken == _clearFeedbackToken)
        {
            [StatusItemButton resetClearFeedbackForButton:button];
        }
    }];
}

- (BOOL)shouldOpenMenuForEvent:(NSEvent *)event
{
    const NSEventModifierFlags interestingFlags = NSEventModifierFlagShift |
                                                  NSEventModifierFlagControl |
                                                  NSEventModifierFlagOption |
                                                  NSEventModifierFlagCommand |
                                                  NSEventModifierFlagFunction;
    return event.type == NSEventTypeRightMouseUp || (event.modifierFlags & interestingFlags) != 0;
}

- (void)showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

- (void)toggleClickAnimation:(id)sender
{
    BOOL enabled = !_preferencesController.clickAnimationEnabled;
    _preferencesController.clickAnimationEnabled = enabled;

    if (!enabled)
    {
        _clearFeedbackToken += 1;
        [StatusItemButton resetClearFeedbackForButton:_statusItem.button];
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
    [menu addItem:[_launchAtLoginController menuItem]];
    [menu addItem:[_preferencesController clickAnimationMenuItemWithTarget:self
                                                                    action:@selector(toggleClickAnimation:)]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", nil), self.applicationName]
                    action:@selector(terminate:)
             keyEquivalent:@""].target = NSApp;
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
