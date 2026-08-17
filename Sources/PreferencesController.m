// Copyright (c) 2014 DLH

#import "PreferencesController.h"

static NSString * const ClickAnimationEnabledDefaultsKey = @"ClickAnimationEnabled";

@implementation PreferencesController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [NSUserDefaults.standardUserDefaults registerDefaults:@{
            ClickAnimationEnabledDefaultsKey: @YES
        }];
    }
    return self;
}

- (BOOL)isClickAnimationEnabled
{
    return [NSUserDefaults.standardUserDefaults boolForKey:ClickAnimationEnabledDefaultsKey];
}

- (void)setClickAnimationEnabled:(BOOL)clickAnimationEnabled
{
    [NSUserDefaults.standardUserDefaults setBool:clickAnimationEnabled
                                          forKey:ClickAnimationEnabledDefaultsKey];
}

- (NSMenuItem *)clickAnimationMenuItemWithTarget:(id)target action:(SEL)action
{
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Click Animation", nil)
                                                  action:action
                                           keyEquivalent:@""];
    item.target = target;
    item.state = self.clickAnimationEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    return item;
}

@end
