// Copyright (c) 2014 DLH

#import "AppDelegate.h"

#import <QuartzCore/QuartzCore.h>
#import <ServiceManagement/ServiceManagement.h>

@interface AppDelegate () <NSMenuDelegate>
@property (nonatomic, assign) NSInteger clearFeedbackToken;
@property (nonatomic, strong) NSStatusItem *statusItem;
@end

@implementation AppDelegate

static const NSTimeInterval ClearFeedbackAnimationDuration = 0.14;
static const CGFloat ClearFeedbackScale = 0.45;
static const CGFloat StatusItemGlyphSize = 16.0;
static NSString * const ClearFeedbackAnimationKey = @"clearFeedbackScale";
static NSString * const ClearPasteboardAccessibilityIdentifier = @"ClearPasteboardStatusItem";
static NSString * const StatusItemGlyph = @"A";
static NSString * const StatusItemGlyphFontName = @"pasteboard-reset";

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSString *clearPasteboardLabel = NSLocalizedString(@"Clear Pasteboard", nil);
    NSButton *button = _statusItem.button;
    button.wantsLayer = YES;
    [self centerStatusButtonLayerAnchorPoint];
    button.alignment = NSTextAlignmentCenter;
    button.target = self;
    button.action = @selector(handleAction:);
    [button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];

    button.title = clearPasteboardLabel;
    button.image = [self statusItemImageWithAccessibilityDescription:clearPasteboardLabel];
    button.imagePosition = NSImageOnly;
    button.imageScaling = NSImageScaleNone;
    button.toolTip = clearPasteboardLabel;

    button.accessibilityElement = YES;
    button.accessibilityTitle = clearPasteboardLabel;
    button.accessibilityLabel = clearPasteboardLabel;
    button.accessibilityIdentifier = ClearPasteboardAccessibilityIdentifier;
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
    [self showClearFeedback];
}

- (void)showClearFeedback
{
    _clearFeedbackToken += 1;
    NSInteger feedbackToken = _clearFeedbackToken;
    NSButton *button = _statusItem.button;
    button.alphaValue = 1.0;
    [self centerStatusButtonLayerAnchorPoint];
    button.layer.transform = CATransform3DIdentity;
    [button.layer removeAnimationForKey:ClearFeedbackAnimationKey];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @1.0;
    animation.toValue = @(ClearFeedbackScale);
    animation.duration = ClearFeedbackAnimationDuration;
    animation.autoreverses = YES;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [button.layer addAnimation:animation forKey:ClearFeedbackAnimationKey];

    dispatch_time_t resetTime = dispatch_time(DISPATCH_TIME_NOW,
                                              (int64_t)(ClearFeedbackAnimationDuration * 2.0 * NSEC_PER_SEC));
    dispatch_after(resetTime, dispatch_get_main_queue(), ^{
        if (feedbackToken == _clearFeedbackToken)
        {
            button.layer.transform = CATransform3DIdentity;
        }
    });
}

- (void)centerStatusButtonLayerAnchorPoint
{
    CALayer *layer = _statusItem.button.layer;
    CGRect frame = layer.frame;
    layer.anchorPoint = CGPointMake(0.5, 0.5);
    layer.frame = frame;
}

- (NSImage *)statusItemImageWithAccessibilityDescription:(NSString *)accessibilityDescription
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

- (BOOL)shouldOpenMenuForEvent:(NSEvent *)event
{
    const NSEventModifierFlags interestingFlags = NSEventModifierFlagShift |
                                                  NSEventModifierFlagControl |
                                                  NSEventModifierFlagOption |
                                                  NSEventModifierFlagCommand |
                                                  NSEventModifierFlagFunction;
    return event.type == NSEventTypeRightMouseUp || (event.modifierFlags & interestingFlags) != 0;
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
