// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@interface GlobalHotKeyController : NSObject
- (instancetype)initWithTarget:(id)target action:(SEL)action;
- (BOOL)updateWithKeyCode:(NSInteger)keyCode modifierFlags:(NSEventModifierFlags)modifierFlags;
@end
