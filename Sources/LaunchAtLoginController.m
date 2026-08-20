// Copyright (c) 2014 DLH

#import "LaunchAtLoginController.h"

#import <ServiceManagement/ServiceManagement.h>

@implementation LaunchAtLoginController

- (void)toggle
{
    NSError *error = nil;
    SMAppService *service = SMAppService.mainAppService;
    BOOL shouldLaunchAtLogin = ![self isRegistered];
    BOOL success =
        shouldLaunchAtLogin ? [service registerAndReturnError:&error] : [service unregisterAndReturnError:&error];

    if (!success)
    {
        [self showError:error];
    }
}

- (NSString *)title
{
    if (SMAppService.mainAppService.status == SMAppServiceStatusRequiresApproval)
    {
        return NSLocalizedString(@"Launch at Login (Requires Approval)", nil);
    }

    return NSLocalizedString(@"Launch at Login", nil);
}

- (NSControlStateValue)state
{
    switch (SMAppService.mainAppService.status)
    {
    case SMAppServiceStatusEnabled:
        return NSControlStateValueOn;
    case SMAppServiceStatusRequiresApproval:
        return NSControlStateValueMixed;
    case SMAppServiceStatusNotRegistered:
    case SMAppServiceStatusNotFound:
        return NSControlStateValueOff;
    }

    return NSControlStateValueOff;
}

- (BOOL)isRegistered
{
    SMAppServiceStatus status = SMAppService.mainAppService.status;
    return status == SMAppServiceStatusEnabled || status == SMAppServiceStatusRequiresApproval;
}

- (void)showError:(NSError *)error
{
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Could Not Update Launch at Login", nil);
    alert.informativeText =
        error.localizedDescription ?: NSLocalizedString(@"The login item setting could not be changed.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

@end
