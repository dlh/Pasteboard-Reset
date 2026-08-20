// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@class LaunchAtLoginController;
@class SettingsController;

@interface SettingsWindowController : NSWindowController <NSWindowDelegate>
- (instancetype)initWithSettingsController:(SettingsController *)settingsController
                           applicationName:(NSString *)applicationName
                   launchAtLoginController:(LaunchAtLoginController *)launchAtLoginController
               clearAnimationChangeHandler:(void (^)(BOOL enabled))clearAnimationChangeHandler
                     shortcutChangeHandler:
                         (BOOL (^)(NSInteger keyCode, NSEventModifierFlags modifierFlags))shortcutChangeHandler;
@end
