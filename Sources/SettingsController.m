// Copyright (c) 2014 DLH

#import "SettingsController.h"

#import "ShortcutKeyCode.h"

static NSString * const ClearAnimationEnabledDefaultsKey = @"ClickAnimationEnabled";
static NSString * const ClearPasteboardShortcutKeyCodeDefaultsKey = @"ClearPasteboardShortcutKeyCode";
static NSString * const ClearPasteboardShortcutModifierFlagsDefaultsKey = @"ClearPasteboardShortcutModifierFlags";

@implementation SettingsController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [NSUserDefaults.standardUserDefaults registerDefaults:@{
            ClearAnimationEnabledDefaultsKey: @YES,
            ClearPasteboardShortcutKeyCodeDefaultsKey: @(ShortcutKeyCodeNone),
            ClearPasteboardShortcutModifierFlagsDefaultsKey: @0
        }];
    }
    return self;
}

- (BOOL)isClearAnimationEnabled
{
    return [NSUserDefaults.standardUserDefaults boolForKey:ClearAnimationEnabledDefaultsKey];
}

- (void)setClearAnimationEnabled:(BOOL)clearAnimationEnabled
{
    [NSUserDefaults.standardUserDefaults setBool:clearAnimationEnabled
                                          forKey:ClearAnimationEnabledDefaultsKey];
}

- (NSInteger)clearPasteboardShortcutKeyCode
{
    return [NSUserDefaults.standardUserDefaults integerForKey:ClearPasteboardShortcutKeyCodeDefaultsKey];
}

- (void)setClearPasteboardShortcutKeyCode:(NSInteger)clearPasteboardShortcutKeyCode
{
    [NSUserDefaults.standardUserDefaults setInteger:clearPasteboardShortcutKeyCode
                                              forKey:ClearPasteboardShortcutKeyCodeDefaultsKey];
}

- (NSEventModifierFlags)clearPasteboardShortcutModifierFlags
{
    return (NSEventModifierFlags)[NSUserDefaults.standardUserDefaults integerForKey:ClearPasteboardShortcutModifierFlagsDefaultsKey];
}

- (void)setClearPasteboardShortcutModifierFlags:(NSEventModifierFlags)clearPasteboardShortcutModifierFlags
{
    [NSUserDefaults.standardUserDefaults setInteger:(NSInteger)clearPasteboardShortcutModifierFlags
                                              forKey:ClearPasteboardShortcutModifierFlagsDefaultsKey];
}

@end
