// Copyright (c) 2014 DLH

#import "ShortcutRecorderControl.h"

#import "ShortcutKeyCode.h"

#import <Carbon/Carbon.h>

static const NSEventModifierFlags RequiredModifierMask =
    NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagControl;
static const NSEventModifierFlags RecordedModifierMask =
    NSEventModifierFlagCommand | NSEventModifierFlagOption | NSEventModifierFlagControl | NSEventModifierFlagShift;
static const CGFloat CornerRadius = 5.0;
static const CGFloat ClearButtonSize = 14.0;
static const CGFloat ClearButtonMargin = 6.0;
static NSString *const ShortcutRecorderAccessibilityIdentifier = @"ClearPasteboardShortcutRecorder";

// Plain NSButtons are excluded from the Tab order unless Full Keyboard Access is on;
// override to make the clear button reachable regardless, matching ShortcutRecorderControl itself.
@interface ShortcutClearButton : NSButton
@end

@implementation ShortcutClearButton

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)canBecomeKeyView
{
    return !self.hidden;
}

// A borderless, NSBezelStyleInline button doesn't treat Space as "click me" the way a normal
// bordered push button does; an unhandled Space would otherwise bubble up the responder chain
// to our superview (ShortcutRecorderControl) and be misread as "start recording."
- (void)keyDown:(NSEvent *)event
{
    if (event.keyCode == kVK_Space)
    {
        [self performClick:nil];
        return;
    }
    [super keyDown:event];
}

@end

@interface ShortcutRecorderControl ()
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, strong) NSButton *clearButton;
@property (nonatomic, copy) NSString *cachedDisplayString;
@end

@implementation ShortcutRecorderControl

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        _keyCode = ShortcutKeyCodeNone;
        _modifierFlags = 0;
        [self configureClearButton];
        [self configureAccessibility];
    }
    return self;
}

- (void)configureClearButton
{
    NSImage *clearImage = [NSImage imageWithSystemSymbolName:@"xmark.circle.fill"
                                    accessibilityDescription:NSLocalizedString(@"Clear Shortcut", nil)];
    NSButton *button = [ShortcutClearButton buttonWithImage:clearImage target:self action:@selector(clearShortcut:)];
    button.bezelStyle = NSBezelStyleInline;
    button.bordered = NO;
    button.imagePosition = NSImageOnly;
    button.hidden = YES;
    [self addSubview:button];
    _clearButton = button;
    [self layoutClearButton];

    // Explicit, self-contained two-stop loop: Tab from the recorder reaches the clear
    // button and back, independent of the window's auto-computed key view loop.
    self.nextKeyView = button;
    button.nextKeyView = self;
}

- (void)configureAccessibility
{
    self.accessibilityRole = NSAccessibilityButtonRole;
    self.accessibilityLabel = NSLocalizedString(@"Clear Pasteboard Shortcut", nil);
    self.accessibilityIdentifier = ShortcutRecorderAccessibilityIdentifier;
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self layoutClearButton];
}

- (void)layoutClearButton
{
    _clearButton.frame =
        NSMakeRect(self.bounds.size.width - ClearButtonSize - ClearButtonMargin,
                   (self.bounds.size.height - ClearButtonSize) / 2.0, ClearButtonSize, ClearButtonSize);
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)canBecomeKeyView
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)resignFirstResponder
{
    self.recording = NO;
    return YES;
}

- (void)mouseDown:(NSEvent *)event
{
    [self.window makeFirstResponder:self];
    self.recording = YES;
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
    if (self.window.firstResponder == self && self.isRecording)
    {
        return [self handleKeyEvent:event];
    }
    return NO;
}

- (void)keyDown:(NSEvent *)event
{
    if (self.isRecording)
    {
        [self handleKeyEvent:event];
        return;
    }

    if (event.keyCode == kVK_Space)
    {
        self.recording = YES;
        return;
    }

    if ((event.keyCode == kVK_Delete || event.keyCode == kVK_ForwardDelete) && _keyCode != ShortcutKeyCodeNone)
    {
        [self clearShortcut:nil];
        return;
    }

    [super keyDown:event];
}

- (BOOL)handleKeyEvent:(NSEvent *)event
{
    NSEventModifierFlags modifierFlags = event.modifierFlags & RecordedModifierMask;
    unsigned short keyCode = event.keyCode;

    if (keyCode == kVK_Escape && (modifierFlags & RequiredModifierMask) == 0)
    {
        self.recording = NO;
        return YES;
    }

    if ((keyCode == kVK_Delete || keyCode == kVK_ForwardDelete) && (modifierFlags & RequiredModifierMask) == 0)
    {
        self.recording = NO;
        [self clearShortcut:nil];
        return YES;
    }

    if ((modifierFlags & RequiredModifierMask) == 0)
    {
        NSBeep();
        return YES;
    }

    self.recording = NO;
    self.keyCode = keyCode;
    self.modifierFlags = modifierFlags;
    [self sendAction:self.action to:self.target];
    return YES;
}

- (void)clearShortcut:(id)sender
{
    self.keyCode = ShortcutKeyCodeNone;
    self.modifierFlags = 0;
    [self sendAction:self.action to:self.target];
}

- (void)setKeyCode:(NSInteger)keyCode
{
    _keyCode = keyCode;
    _cachedDisplayString = nil;
    [self updateClearButtonVisibility];
    [self setNeedsDisplay:YES];
}

- (void)setModifierFlags:(NSEventModifierFlags)modifierFlags
{
    _modifierFlags = modifierFlags;
    _cachedDisplayString = nil;
    [self setNeedsDisplay:YES];
}

- (void)setRecording:(BOOL)recording
{
    _recording = recording;
    _cachedDisplayString = nil;
    [self updateClearButtonVisibility];
    [self setNeedsDisplay:YES];
}

- (void)updateClearButtonVisibility
{
    _clearButton.hidden = self.isRecording || (_keyCode == ShortcutKeyCodeNone);
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:CornerRadius yRadius:CornerRadius];

    NSColor *backgroundColor = self.isRecording ? NSColor.controlAccentColor : NSColor.controlBackgroundColor;
    [backgroundColor set];
    [path fill];

    NSColor *borderColor = (self.window.firstResponder == self) ? NSColor.controlAccentColor : NSColor.separatorColor;
    [borderColor setStroke];
    path.lineWidth = 1.0;
    [path stroke];

    NSColor *textColor = self.isRecording ? NSColor.alternateSelectedControlTextColor : NSColor.controlTextColor;
    NSDictionary *attributes = @{
        NSFontAttributeName : [NSFont systemFontOfSize:NSFont.systemFontSize],
        NSForegroundColorAttributeName : textColor,
    };
    NSString *string = [self displayString];
    NSSize stringSize = [string sizeWithAttributes:attributes];
    NSRect textRect =
        NSMakeRect((self.bounds.size.width - stringSize.width) / 2.0,
                   (self.bounds.size.height - stringSize.height) / 2.0, stringSize.width, stringSize.height);
    [string drawInRect:textRect withAttributes:attributes];
}

- (NSString *)displayString
{
    if (_cachedDisplayString)
    {
        return _cachedDisplayString;
    }

    if (self.isRecording)
    {
        _cachedDisplayString = NSLocalizedString(@"Type Shortcut", nil);
    }
    else if (_keyCode == ShortcutKeyCodeNone)
    {
        _cachedDisplayString = NSLocalizedString(@"Click to Record Shortcut", nil);
    }
    else
    {
        _cachedDisplayString = [ShortcutRecorderControl stringForKeyCode:_keyCode modifierFlags:_modifierFlags];
    }

    return _cachedDisplayString;
}

+ (NSString *)stringForKeyCode:(NSInteger)keyCode modifierFlags:(NSEventModifierFlags)modifierFlags
{
    return [NSString
        stringWithFormat:@"%@%@", [self stringForModifierFlags:modifierFlags], [self stringForKeyCode:keyCode]];
}

+ (NSString *)stringForModifierFlags:(NSEventModifierFlags)modifierFlags
{
    NSMutableString *string = [NSMutableString string];
    if (modifierFlags & NSEventModifierFlagControl)
        [string appendString:@"⌃"];
    if (modifierFlags & NSEventModifierFlagOption)
        [string appendString:@"⌥"];
    if (modifierFlags & NSEventModifierFlagShift)
        [string appendString:@"⇧"];
    if (modifierFlags & NSEventModifierFlagCommand)
        [string appendString:@"⌘"];
    return string;
}

+ (NSString *)stringForKeyCode:(NSInteger)keyCode
{
    static NSDictionary<NSNumber *, NSString *> *specialKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        specialKeys = @{
            @(kVK_Return) : @"⏎",
            @(kVK_Tab) : @"⇥",
            @(kVK_Space) : NSLocalizedString(@"Space", nil),
            @(kVK_Delete) : @"⌫",
            @(kVK_ForwardDelete) : @"⌦",
            @(kVK_Escape) : @"⎋",
            @(kVK_LeftArrow) : @"←",
            @(kVK_RightArrow) : @"→",
            @(kVK_UpArrow) : @"↑",
            @(kVK_DownArrow) : @"↓",
            @(kVK_Home) : @"↖",
            @(kVK_End) : @"↘",
            @(kVK_PageUp) : @"⇞",
            @(kVK_PageDown) : @"⇟",
            @(kVK_F1) : @"F1",
            @(kVK_F2) : @"F2",
            @(kVK_F3) : @"F3",
            @(kVK_F4) : @"F4",
            @(kVK_F5) : @"F5",
            @(kVK_F6) : @"F6",
            @(kVK_F7) : @"F7",
            @(kVK_F8) : @"F8",
            @(kVK_F9) : @"F9",
            @(kVK_F10) : @"F10",
            @(kVK_F11) : @"F11",
            @(kVK_F12) : @"F12",
        };
    });

    NSString *specialKey = specialKeys[@(keyCode)];
    if (specialKey)
    {
        return specialKey;
    }

    NSString *character = [self characterForKeyCode:(UInt16)keyCode];
    return character.length > 0 ? character.uppercaseString : [NSString stringWithFormat:@"[%ld]", (long)keyCode];
}

+ (NSString *)characterForKeyCode:(UInt16)keyCode
{
    TISInputSourceRef inputSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
    if (!inputSource)
    {
        return nil;
    }

    CFDataRef layoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData);
    if (!layoutData)
    {
        CFRelease(inputSource);
        return nil;
    }

    const UCKeyboardLayout *layout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    UInt32 deadKeyState = 0;
    UniChar characters[4];
    UniCharCount length = 0;
    OSStatus status =
        UCKeyTranslate(layout, keyCode, kUCKeyActionDisplay, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit,
                       &deadKeyState, sizeof(characters) / sizeof(UniChar), &length, characters);
    CFRelease(inputSource);

    if (status != noErr || length == 0)
    {
        return nil;
    }

    return [NSString stringWithCharacters:characters length:length];
}

@end
