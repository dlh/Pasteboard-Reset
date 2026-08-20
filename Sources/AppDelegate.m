// Copyright (c) 2014 DLH

#import "AppDelegate.h"
#import "GlobalHotKeyController.h"
#import "LaunchAtLoginController.h"
#import "SettingsController.h"
#import "SettingsWindowController.h"
#import "StatusItemButton.h"

@interface AppDelegate () <NSMenuDelegate>
@property (nonatomic, assign) NSInteger clearFeedbackToken;
@property (nonatomic, strong) GlobalHotKeyController *globalHotKeyController;
@property (nonatomic, strong) LaunchAtLoginController *launchAtLoginController;
@property (nonatomic, strong) SettingsController *settingsController;
@property (nonatomic, strong) SettingsWindowController *settingsWindowController;
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self configureMainMenu];

    self.launchAtLoginController = [[LaunchAtLoginController alloc] init];
    self.settingsController = [[SettingsController alloc] init];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [StatusItemButton configureButton:_statusItem.button target:self action:@selector(handleAction:)];

    self.globalHotKeyController = [[GlobalHotKeyController alloc] initWithTarget:self action:@selector(clearPasteboard:)];
    [_globalHotKeyController updateWithKeyCode:_settingsController.clearPasteboardShortcutKeyCode
                                  modifierFlags:_settingsController.clearPasteboardShortcutModifierFlags];

    __weak typeof(self) weakSelf = self;
    self.settingsWindowController = [[SettingsWindowController alloc]
        initWithSettingsController:_settingsController
                   applicationName:self.applicationName
           launchAtLoginController:_launchAtLoginController
       clearAnimationChangeHandler:^(BOOL enabled) {
           [weakSelf handleClearAnimationChange:enabled];
       }
             shortcutChangeHandler:^BOOL(NSInteger keyCode, NSEventModifierFlags modifierFlags) {
                 return [weakSelf.globalHotKeyController updateWithKeyCode:keyCode modifierFlags:modifierFlags];
             }];
}

- (void)handleAction:(id)sender
{
    NSEvent *event = NSApp.currentEvent;
    if ([self shouldOpenMenuForEvent:event])
    {
        _statusItem.menu = [self createMenu];
        [_statusItem.button performClick:sender];
        return;
    }

    if (event.type == NSEventTypeLeftMouseDown || event.type == NSEventTypeRightMouseDown)
    {
        return;
    }

    [self clearPasteboard:sender];
}

- (void)clearPasteboard:(id)sender
{
    [[NSPasteboard generalPasteboard] clearContents];
    if (_settingsController.clearAnimationEnabled)
    {
        [self showClearFeedback];
    }
}

- (void)showSettings:(id)sender
{
    [_settingsWindowController showWindow:sender];
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
    return event.type == NSEventTypeRightMouseDown || (event.modifierFlags & interestingFlags) != 0;
}

- (void)handleClearAnimationChange:(BOOL)enabled
{
    if (!enabled)
    {
        _clearFeedbackToken += 1;
        [StatusItemButton resetClearFeedbackForButton:_statusItem.button];
    }
}

- (void)configureMainMenu
{
    // LSUIElement apps have no visible menu bar, but a main menu still supplies key
    // equivalents (e.g. Cmd-W to close whichever window is key, like the About panel).
    // Top-level main menu items don't carry actions/key equivalents themselves; the
    // item needs a submenu to hold the actionable entry.
    NSMenu *mainMenu = [[NSMenu alloc] init];
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:fileMenuItem];

    NSMenu *fileMenu = [[NSMenu alloc] init];
    [fileMenu addItemWithTitle:NSLocalizedString(@"Close", nil) action:@selector(performClose:) keyEquivalent:@"w"];
    fileMenuItem.submenu = fileMenu;

    NSApp.mainMenu = mainMenu;
}

- (NSMenu *)createMenu
{
    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;
    [menu addItemWithTitle:NSLocalizedString(@"Settings…", nil)
                    action:@selector(showSettings:)
             keyEquivalent:@","].target = self;
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Quit %@", nil), self.applicationName]
                    action:@selector(terminate:)
             keyEquivalent:@"q"].target = NSApp;
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
