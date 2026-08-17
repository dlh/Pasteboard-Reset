// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSObject
@property (nonatomic, assign, getter=isClickAnimationEnabled) BOOL clickAnimationEnabled;

- (NSMenuItem *)clickAnimationMenuItemWithTarget:(id)target action:(SEL)action;
@end
