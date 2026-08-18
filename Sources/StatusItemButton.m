// Copyright (c) 2014 DLH

#import "StatusItemButton.h"
#import "StatusItemIcon.h"

#import <QuartzCore/QuartzCore.h>

@implementation StatusItemButton

static const NSTimeInterval ClearFeedbackAnimationDuration = 0.14;
static const CGFloat ClearFeedbackScale = 0.45;
static NSString * const ClearFeedbackAnimationKey = @"clearFeedbackScale";
static NSString * const ClearPasteboardAccessibilityIdentifier = @"ClearPasteboardStatusItem";

+ (void)configureButton:(NSButton *)button target:(id)target action:(SEL)action
{
    NSString *clearPasteboardLabel = NSLocalizedString(@"Clear Pasteboard", nil);

    button.wantsLayer = YES;
    [self centerLayerAnchorPointForButton:button];
    button.alignment = NSTextAlignmentCenter;
    button.target = target;
    button.action = action;
    [button sendActionOn:NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskRightMouseDown];

    button.title = clearPasteboardLabel;
    button.image = [StatusItemIcon imageWithAccessibilityDescription:clearPasteboardLabel];
    button.imagePosition = NSImageOnly;
    button.imageScaling = NSImageScaleNone;
    button.toolTip = clearPasteboardLabel;

    button.accessibilityElement = YES;
    button.accessibilityTitle = clearPasteboardLabel;
    button.accessibilityLabel = clearPasteboardLabel;
    button.accessibilityIdentifier = ClearPasteboardAccessibilityIdentifier;
}

+ (void)showClearFeedbackForButton:(NSButton *)button completion:(void (^)(void))completion
{
    button.alphaValue = 1.0;
    [self centerLayerAnchorPointForButton:button];
    button.layer.transform = CATransform3DIdentity;
    [button.layer removeAnimationForKey:ClearFeedbackAnimationKey];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @1.0;
    animation.toValue = @(ClearFeedbackScale);
    animation.duration = ClearFeedbackAnimationDuration;
    animation.autoreverses = YES;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [button.layer addAnimation:animation forKey:ClearFeedbackAnimationKey];

    dispatch_time_t resetTime = dispatch_time(DISPATCH_TIME_NOW,
                                              (int64_t)(ClearFeedbackAnimationDuration * 2.0 * NSEC_PER_SEC));
    dispatch_after(resetTime, dispatch_get_main_queue(), ^{
        completion();
    });
}

+ (void)resetClearFeedbackForButton:(NSButton *)button
{
    button.layer.transform = CATransform3DIdentity;
}

+ (void)centerLayerAnchorPointForButton:(NSButton *)button
{
    CALayer *layer = button.layer;
    CGRect frame = layer.frame;
    layer.anchorPoint = CGPointMake(0.5, 0.5);
    layer.frame = frame;
}

@end
