// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@interface StatusItemButton : NSObject
+ (void)configureButton:(NSButton *)button target:(id)target action:(SEL)action;
+ (void)showClearFeedbackForButton:(NSButton *)button completion:(void (^)(void))completion;
+ (void)resetClearFeedbackForButton:(NSButton *)button;
@end
