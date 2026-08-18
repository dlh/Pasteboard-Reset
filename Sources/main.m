// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(void)
{
    @autoreleasepool
    {
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }

    return EXIT_SUCCESS;
}
