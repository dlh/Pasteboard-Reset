// Copyright (c) 2014 DLH

#import "GlobalHotKeyController.h"

#import "ShortcutKeyCode.h"

#import <Carbon/Carbon.h>

static const OSType HotKeySignature = 0x50425253; // 'PBRS'
static const UInt32 HotKeyID = 1;

static OSStatus HotKeyEventHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData);

@interface GlobalHotKeyController ()
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) EventHotKeyRef hotKeyRef;
@property (nonatomic, assign) EventHandlerRef eventHandlerRef;
@end

@implementation GlobalHotKeyController

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super init];
    if (self)
    {
        _target = target;
        _action = action;

        EventTypeSpec eventType = { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed };
        InstallApplicationEventHandler(&HotKeyEventHandler, 1, &eventType, (__bridge void *)self, &_eventHandlerRef);
    }
    return self;
}

- (void)dealloc
{
    [self unregisterHotKey];
    if (_eventHandlerRef)
    {
        RemoveEventHandler(_eventHandlerRef);
        _eventHandlerRef = NULL;
    }
}

- (BOOL)updateWithKeyCode:(NSInteger)keyCode modifierFlags:(NSEventModifierFlags)modifierFlags
{
    [self unregisterHotKey];

    if (keyCode == ShortcutKeyCodeNone)
    {
        return YES;
    }

    EventHotKeyID hotKeyID = { .signature = HotKeySignature, .id = HotKeyID };
    OSStatus status = RegisterEventHotKey((UInt32)keyCode, [self carbonModifiersForCocoaModifiers:modifierFlags], hotKeyID,
                                           GetApplicationEventTarget(), 0, &_hotKeyRef);
    if (status != noErr)
    {
        _hotKeyRef = NULL;
    }
    return status == noErr;
}

- (void)unregisterHotKey
{
    if (_hotKeyRef)
    {
        UnregisterEventHotKey(_hotKeyRef);
        _hotKeyRef = NULL;
    }
}

- (UInt32)carbonModifiersForCocoaModifiers:(NSEventModifierFlags)modifierFlags
{
    UInt32 carbonModifiers = 0;
    if (modifierFlags & NSEventModifierFlagCommand) carbonModifiers |= cmdKey;
    if (modifierFlags & NSEventModifierFlagOption) carbonModifiers |= optionKey;
    if (modifierFlags & NSEventModifierFlagControl) carbonModifiers |= controlKey;
    if (modifierFlags & NSEventModifierFlagShift) carbonModifiers |= shiftKey;
    return carbonModifiers;
}

- (void)invokeAction
{
    [NSApp sendAction:_action to:_target from:self];
}

@end

static OSStatus HotKeyEventHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData)
{
    (void)nextHandler;

    EventHotKeyID hotKeyID;
    OSStatus status = GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL,
                                         sizeof(hotKeyID), NULL, &hotKeyID);
    if (status != noErr || hotKeyID.signature != HotKeySignature || hotKeyID.id != HotKeyID)
    {
        return eventNotHandledErr;
    }

    GlobalHotKeyController *controller = (__bridge GlobalHotKeyController *)userData;
    [controller invokeAction];
    return noErr;
}
