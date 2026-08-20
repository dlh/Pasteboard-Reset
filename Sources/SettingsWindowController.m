// Copyright (c) 2014 DLH

#import "SettingsWindowController.h"

#import "LaunchAtLoginController.h"
#import "SettingsController.h"
#import "ShortcutRecorderControl.h"

static const NSRect ContentRect = { { 0, 0 }, { 360, 218 } };
static const CGFloat Margin = 20.0;

static NSToolbarItemIdentifier const SettingsToolbarItemIdentifier = @"Settings";
static NSToolbarItemIdentifier const AboutToolbarItemIdentifier = @"About";

static NSString *const GitHubProjectURLString = @"https://github.com/dlh/Pasteboard-Reset";

@interface SettingsWindowController () <NSToolbarDelegate>
@property (nonatomic, strong) SettingsController *settingsController;
@property (nonatomic, copy) NSString *applicationName;
@property (nonatomic, strong) LaunchAtLoginController *launchAtLoginController;
@property (nonatomic, copy) void (^clearAnimationChangeHandler)(BOOL enabled);
@property (nonatomic, copy) BOOL (^shortcutChangeHandler)(NSInteger keyCode, NSEventModifierFlags modifierFlags);
@property (nonatomic, strong) NSButton *launchAtLoginCheckbox;
@property (nonatomic, strong) NSTabView *tabView;
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
    window.title = applicationName;
    window.releasedWhenClosed = NO;
    [window center];

    self = [super initWithWindow:window];
    if (self)
    {
        _settingsController = settingsController;
        _applicationName = [applicationName copy];
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
    NSTabView *tabView = [[NSTabView alloc] initWithFrame:self.window.contentView.bounds];
    tabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    tabView.tabViewType = NSNoTabsNoBorder;

    NSTabViewItem *settingsItem = [[NSTabViewItem alloc] initWithIdentifier:SettingsToolbarItemIdentifier];
    settingsItem.view = [self buildSettingsPaneWithSize:ContentRect.size];
    [tabView addTabViewItem:settingsItem];

    NSTabViewItem *aboutItem = [[NSTabViewItem alloc] initWithIdentifier:AboutToolbarItemIdentifier];
    aboutItem.view = [self buildAboutPaneWithSize:ContentRect.size];
    [tabView addTabViewItem:aboutItem];

    [self.window.contentView addSubview:tabView];
    _tabView = tabView;

    [self configureToolbar];
}

- (void)configureToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"SettingsToolbar"];
    toolbar.delegate = self;
    toolbar.allowsUserCustomization = NO;
    toolbar.selectedItemIdentifier = SettingsToolbarItemIdentifier;

    self.window.toolbar = toolbar;
    self.window.toolbarStyle = NSWindowToolbarStylePreference;

    // Assigning a toolbar can grow the content view beyond the size we asked for
    // (to make room for the toolbar row); force it back so panes stay the size
    // they were laid out for.
    [self.window setContentSize:ContentRect.size];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[ SettingsToolbarItemIdentifier, AboutToolbarItemIdentifier ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[ SettingsToolbarItemIdentifier, AboutToolbarItemIdentifier ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return @[ SettingsToolbarItemIdentifier, AboutToolbarItemIdentifier ];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
  willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    item.target = self;
    item.action = @selector(selectToolbarItem:);

    if ([itemIdentifier isEqualToString:SettingsToolbarItemIdentifier])
    {
        item.label = NSLocalizedString(@"Settings", nil);
        item.image = [NSImage imageWithSystemSymbolName:@"gearshape" accessibilityDescription:nil];
    }
    else if ([itemIdentifier isEqualToString:AboutToolbarItemIdentifier])
    {
        item.label = NSLocalizedString(@"About", nil);
        item.image = [NSImage imageWithSystemSymbolName:@"info.circle" accessibilityDescription:nil];
    }

    return item;
}

- (void)selectToolbarItem:(NSToolbarItem *)sender
{
    NSToolbarItemIdentifier identifier = sender.itemIdentifier;
    [_tabView selectTabViewItemWithIdentifier:identifier];
    self.window.toolbar.selectedItemIdentifier = identifier;
}

- (NSView *)buildSettingsPaneWithSize:(NSSize)size
{
    NSView *pane = [[NSView alloc] initWithFrame:(NSRect){ NSZeroPoint, size }];
    const CGFloat width = size.width - Margin * 2;

    NSButton *launchAtLoginCheckbox = [NSButton checkboxWithTitle:_launchAtLoginController.title
                                                             target:self
                                                             action:@selector(toggleLaunchAtLogin:)];
    launchAtLoginCheckbox.allowsMixedState = YES;
    launchAtLoginCheckbox.frame = NSMakeRect(Margin, 180, width, 18);
    [pane addSubview:launchAtLoginCheckbox];
    _launchAtLoginCheckbox = launchAtLoginCheckbox;
    [self refreshLaunchAtLoginCheckbox];

    NSTextField *launchAtLoginDescription = [self buildDescriptionLabelWithString:
        NSLocalizedString(@"Automatically start when you log in.", nil)
                                                                              frame:NSMakeRect(Margin, 162, width, 16)];
    [pane addSubview:launchAtLoginDescription];

    NSButton *clearAnimationCheckbox = [NSButton checkboxWithTitle:NSLocalizedString(@"Clear Animation", nil)
                                                              target:self
                                                              action:@selector(toggleClearAnimation:)];
    clearAnimationCheckbox.state = _settingsController.isClearAnimationEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    clearAnimationCheckbox.frame = NSMakeRect(Margin, 132, width, 18);
    [pane addSubview:clearAnimationCheckbox];

    // Two lines at this width; the others fit on one, hence the taller frame.
    NSTextField *clearAnimationDescription = [self buildDescriptionLabelWithString:
        NSLocalizedString(@"Briefly pulse the menu bar icon when the pasteboard is cleared.", nil)
                                                                               frame:NSMakeRect(Margin, 102, width, 28)];
    [pane addSubview:clearAnimationDescription];

    NSTextField *label = [NSTextField labelWithString:NSLocalizedString(@"Clear Pasteboard Shortcut:", nil)];
    label.frame = NSMakeRect(Margin, 72, width, 18);
    [pane addSubview:label];

    ShortcutRecorderControl *recorder = [[ShortcutRecorderControl alloc] initWithFrame:NSMakeRect(Margin, 42, 160, 24)];
    recorder.keyCode = _settingsController.clearPasteboardShortcutKeyCode;
    recorder.modifierFlags = _settingsController.clearPasteboardShortcutModifierFlags;
    recorder.target = self;
    recorder.action = @selector(shortcutDidChange:);
    [pane addSubview:recorder];

    NSTextField *caption = [self buildDescriptionLabelWithString:
        NSLocalizedString(@"Press ⎋ to cancel or ⌫ to clear.", nil)
                                                             frame:NSMakeRect(Margin, 20, width, 16)];
    [pane addSubview:caption];

    return pane;
}

- (NSTextField *)buildDescriptionLabelWithString:(NSString *)string frame:(NSRect)frame
{
    NSTextField *label = [NSTextField wrappingLabelWithString:string];
    label.translatesAutoresizingMaskIntoConstraints = YES;
    label.frame = frame;
    label.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    label.textColor = NSColor.secondaryLabelColor;
    return label;
}

- (NSView *)buildAboutPaneWithSize:(NSSize)size
{
    NSView *pane = [[NSView alloc] initWithFrame:(NSRect){ NSZeroPoint, size }];
    const CGFloat iconSize = 96;
    const CGFloat columnGap = 20;

    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *versionText = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", nil),
                              info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"]];
    NSString *githubLinkText = NSLocalizedString(@"GitHub Project", nil);
    NSString *copyrightText = info[@"NSHumanReadableCopyright"] ?: @"";

    // Size the text column to its widest line rather than stretching it to
    // the pane's margin, so the icon+text group can be centered as a whole.
    NSFont *nameFont = [NSFont boldSystemFontOfSize:15];
    NSFont *smallFont = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    const CGFloat textWidth = ceil(MAX(MAX([_applicationName sizeWithAttributes:@{ NSFontAttributeName: nameFont }].width,
                                            [versionText sizeWithAttributes:@{ NSFontAttributeName: smallFont }].width),
                                        MAX([githubLinkText sizeWithAttributes:@{ NSFontAttributeName: smallFont }].width,
                                            [copyrightText sizeWithAttributes:@{ NSFontAttributeName: smallFont }].width)));

    const CGFloat groupWidth = iconSize + columnGap + textWidth;
    const CGFloat groupX = (size.width - groupWidth) / 2.0;
    const CGFloat iconX = groupX;
    const CGFloat textX = groupX + iconSize + columnGap;

    NSImageView *iconView = [NSImageView imageViewWithImage:NSApp.applicationIconImage];
    iconView.frame = NSMakeRect(iconX, (size.height - iconSize) / 2.0, iconSize, iconSize);
    [pane addSubview:iconView];

    // Name, version, GitHub link, and copyright stack in a left-aligned block
    // to the right of the icon, centered as a group to match the icon's center.
    const CGFloat rowHeight = 16;
    const CGFloat textBlockHeight = 88;
    const CGFloat textBlockBottom = (size.height - textBlockHeight) / 2.0;

    NSTextField *nameLabel = [NSTextField labelWithString:_applicationName];
    nameLabel.font = nameFont;
    nameLabel.frame = NSMakeRect(textX, textBlockBottom + 72, textWidth, rowHeight);
    [pane addSubview:nameLabel];

    NSTextField *versionLabel = [NSTextField labelWithString:versionText];
    versionLabel.font = smallFont;
    versionLabel.textColor = NSColor.secondaryLabelColor;
    versionLabel.frame = NSMakeRect(textX, textBlockBottom + 50, textWidth, rowHeight);
    [pane addSubview:versionLabel];

    NSTextField *githubLink = [self buildGitHubLinkLabel];
    githubLink.frame = NSMakeRect(textX, textBlockBottom + 28, textWidth, rowHeight);
    [pane addSubview:githubLink];

    NSTextField *copyrightLabel = [NSTextField labelWithString:copyrightText];
    copyrightLabel.font = smallFont;
    copyrightLabel.textColor = NSColor.secondaryLabelColor;
    copyrightLabel.frame = NSMakeRect(textX, textBlockBottom, textWidth, rowHeight);
    [pane addSubview:copyrightLabel];

    return pane;
}

- (NSTextField *)buildGitHubLinkLabel
{
    NSMutableAttributedString *linkText = [[NSMutableAttributedString alloc]
        initWithString:NSLocalizedString(@"GitHub Project", nil)];
    NSRange range = NSMakeRange(0, linkText.length);
    [linkText addAttribute:NSLinkAttributeName value:GitHubProjectURLString range:range];
    [linkText addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:NSFont.smallSystemFontSize] range:range];

    NSTextField *linkField = [NSTextField labelWithAttributedString:linkText];
    linkField.selectable = YES;
    linkField.allowsEditingTextAttributes = YES;
    return linkField;
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
