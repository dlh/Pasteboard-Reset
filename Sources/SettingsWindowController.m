// Copyright (c) 2014 DLH

#import "SettingsWindowController.h"

#import "LaunchAtLoginController.h"
#import "SettingsController.h"
#import "ShortcutRecorderControl.h"

static const NSRect ContentRect = { { 0, 0 }, { 360, 174 } };
static const CGFloat Margin = 20.0;

@interface SettingsWindowController ()
@property (nonatomic, strong) SettingsController *settingsController;
@property (nonatomic, strong) LaunchAtLoginController *launchAtLoginController;
@property (nonatomic, copy) void (^clearAnimationChangeHandler)(BOOL enabled);
@property (nonatomic, copy) BOOL (^shortcutChangeHandler)(NSInteger keyCode, NSEventModifierFlags modifierFlags);
@property (nonatomic, strong) NSButton *launchAtLoginCheckbox;
@end

@implementation SettingsWindowController

- (instancetype)initWithSettingsController:(SettingsController *)settingsController
                           applicationName:(NSString *)applicationName
                   launchAtLoginController:(LaunchAtLoginController *)launchAtLoginController
               clearAnimationChangeHandler:(void (^)(BOOL))clearAnimationChangeHandler
                     shortcutChangeHandler:(BOOL (^)(NSInteger, NSEventModifierFlags))shortcutChangeHandler
{
    NSWindow *window = [[NSWindow alloc] initWithContentRect:ContentRect
                                                    styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    window.title = [NSString stringWithFormat:NSLocalizedString(@"%@ Settings", nil), applicationName];
    window.releasedWhenClosed = NO;
    [window center];

    self = [super initWithWindow:window];
    if (self)
    {
        _settingsController = settingsController;
        _launchAtLoginController = launchAtLoginController;
        _clearAnimationChangeHandler = [clearAnimationChangeHandler copy];
        _shortcutChangeHandler = [shortcutChangeHandler copy];
        window.delegate = self;
        [self configureContentView];
    }
    return self;
}

- (void)configureContentView
{
    NSView *contentView = self.window.contentView;
    const CGFloat width = ContentRect.size.width - Margin * 2;

    NSButton *launchAtLoginCheckbox = [NSButton checkboxWithTitle:_launchAtLoginController.title
                                                             target:self
                                                             action:@selector(toggleLaunchAtLogin:)];
    launchAtLoginCheckbox.allowsMixedState = YES;
    launchAtLoginCheckbox.frame = NSMakeRect(Margin, 136, width, 18);
    [contentView addSubview:launchAtLoginCheckbox];
    _launchAtLoginCheckbox = launchAtLoginCheckbox;
    [self refreshLaunchAtLoginCheckbox];

    NSButton *clearAnimationCheckbox = [NSButton checkboxWithTitle:NSLocalizedString(@"Clear Animation", nil)
                                                              target:self
                                                              action:@selector(toggleClearAnimation:)];
    clearAnimationCheckbox.state = _settingsController.isClearAnimationEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    clearAnimationCheckbox.frame = NSMakeRect(Margin, 108, width, 18);
    [contentView addSubview:clearAnimationCheckbox];

    NSTextField *label = [NSTextField labelWithString:NSLocalizedString(@"Clear Pasteboard Shortcut:", nil)];
    label.frame = NSMakeRect(Margin, 74, width, 18);
    [contentView addSubview:label];

    ShortcutRecorderControl *recorder = [[ShortcutRecorderControl alloc] initWithFrame:NSMakeRect(Margin, 44, 160, 24)];
    recorder.keyCode = _settingsController.clearPasteboardShortcutKeyCode;
    recorder.modifierFlags = _settingsController.clearPasteboardShortcutModifierFlags;
    recorder.target = self;
    recorder.action = @selector(shortcutDidChange:);
    [contentView addSubview:recorder];

    NSTextField *caption = [NSTextField wrappingLabelWithString:NSLocalizedString(@"Press ⎋ to cancel or ⌫ to clear.", nil)];
    caption.frame = NSMakeRect(Margin, 16, width, 16);
    caption.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    caption.textColor = NSColor.secondaryLabelColor;
    [contentView addSubview:caption];
}

- (void)toggleLaunchAtLogin:(id)sender
{
    [_launchAtLoginController toggle];
    [self refreshLaunchAtLoginCheckbox];
}

- (void)refreshLaunchAtLoginCheckbox
{
    _launchAtLoginCheckbox.state = _launchAtLoginController.state;
    _launchAtLoginCheckbox.title = _launchAtLoginController.title;
}

- (void)toggleClearAnimation:(NSButton *)sender
{
    BOOL enabled = (sender.state == NSControlStateValueOn);
    _settingsController.clearAnimationEnabled = enabled;

    if (_clearAnimationChangeHandler)
    {
        _clearAnimationChangeHandler(enabled);
    }
}

- (void)shortcutDidChange:(ShortcutRecorderControl *)sender
{
    NSInteger previousKeyCode = _settingsController.clearPasteboardShortcutKeyCode;
    NSEventModifierFlags previousModifierFlags = _settingsController.clearPasteboardShortcutModifierFlags;

    _settingsController.clearPasteboardShortcutKeyCode = sender.keyCode;
    _settingsController.clearPasteboardShortcutModifierFlags = sender.modifierFlags;

    BOOL success = _shortcutChangeHandler ? _shortcutChangeHandler(sender.keyCode, sender.modifierFlags) : YES;
    if (!success)
    {
        _settingsController.clearPasteboardShortcutKeyCode = previousKeyCode;
        _settingsController.clearPasteboardShortcutModifierFlags = previousModifierFlags;
        sender.keyCode = previousKeyCode;
        sender.modifierFlags = previousModifierFlags;
        [self showShortcutRegistrationError];
    }
}

- (void)showShortcutRegistrationError
{
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Could Not Set Shortcut", nil);
    alert.informativeText = NSLocalizedString(@"That key combination is already in use by the system or another app.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

- (void)showWindow:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];

    // Don't leave a control auto-focused when the window opens.
    [self.window makeFirstResponder:nil];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    // Refresh here so an out-of-band change, i.e. directly editing the Login
    // Items in System Settings, doesn't leave the checkbox stale.
    [self refreshLaunchAtLoginCheckbox];
}

@end
