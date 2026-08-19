// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@interface LaunchAtLoginController : NSObject
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSControlStateValue state;

- (void)toggle;
@end
