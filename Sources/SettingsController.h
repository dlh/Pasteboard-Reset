// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@interface SettingsController : NSObject
@property (nonatomic, assign, getter=isClearAnimationEnabled) BOOL clearAnimationEnabled;
@property (nonatomic, assign) NSInteger clearPasteboardShortcutKeyCode;
@property (nonatomic, assign) NSEventModifierFlags clearPasteboardShortcutModifierFlags;
@end
