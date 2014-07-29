// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char *argv[])
{
    @autoreleasepool
    {
        id delegate = [[AppDelegate alloc] init];
        [NSApplication sharedApplication].delegate = delegate;
        return NSApplicationMain(argc, argv);
    }
}
