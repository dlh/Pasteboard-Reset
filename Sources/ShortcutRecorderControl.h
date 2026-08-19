// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@interface ShortcutRecorderControl : NSControl
@property (nonatomic, assign) NSInteger keyCode;
@property (nonatomic, assign) NSEventModifierFlags modifierFlags;
@end
