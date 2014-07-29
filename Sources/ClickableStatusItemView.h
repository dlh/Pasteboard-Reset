// Copyright (c) 2014 DLH

#import <Cocoa/Cocoa.h>

@interface ClickableStatusItemView : NSView

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSImage *image;
@property (strong, nonatomic) NSImage *alternateImage;
@property (strong, nonatomic) id target;
@property (assign, nonatomic) SEL action;
@property (strong, nonatomic) NSMenu *menu;

- initWithStatusItem:(NSStatusItem *)statusItem
               image:(NSImage *)image
      alternateImage:(NSImage *)alternateImage
              target:(id)target
              action:(SEL)action
                menu:(NSMenu *)menu;

@end
