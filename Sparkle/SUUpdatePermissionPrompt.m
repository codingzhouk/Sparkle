//
//  SUUpdatePermissionPrompt.m
//  Sparkle
//
//  Created by Andy Matuschak on 1/24/08.
//  Copyright 2008 Andy Matuschak. All rights reserved.
//

#import "SUUpdatePermissionPrompt.h"
#import "SUUpdatePermissionPromptResult.h"
#import "SULocalizations.h"

#import "SUHost.h"
#import "SUConstants.h"
#import "SUApplicationInfo.h"

@interface SUUpdatePermissionPrompt ()

@property (assign) BOOL isShowingMoreInfo;
@property (assign) BOOL shouldSendProfile;

@property (strong) SUHost *host;
@property (strong) NSArray *systemProfileInformationArray;
@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (weak) IBOutlet NSView *moreInfoView;
@property (weak) IBOutlet NSButton *moreInfoButton;
@property (weak) IBOutlet NSTableView *profileTableView;

@property (nonatomic, readonly) void (^reply)(SUUpdatePermissionPromptResult *);

@end

@implementation SUUpdatePermissionPrompt

@synthesize reply = _reply;
@synthesize isShowingMoreInfo = _isShowingMoreInfo;
@synthesize shouldSendProfile = _shouldSendProfile;
@synthesize host;
@synthesize systemProfileInformationArray;
@synthesize descriptionTextField;
@synthesize moreInfoView;
@synthesize moreInfoButton;
@synthesize profileTableView;

- (instancetype)initPromptWithHost:(SUHost *)theHost systemProfile:(NSArray *)systemProfile reply:(void (^)(SUUpdatePermissionPromptResult *))reply
{
    self = [super initWithWindowNibName:@"SUUpdatePermissionPrompt"];
    if (self)
    {
        _reply = reply;
        self.host = theHost;
        self.isShowingMoreInfo = NO;
        self.shouldSendProfile = [self shouldAskAboutProfile];
        self.systemProfileInformationArray = systemProfile;
        [self setShouldCascadeWindows:NO];
    }
    return self;
}

+ (void)promptWithHost:(SUHost *)host systemProfile:(NSArray *)systemProfile reply:(void (^)(SUUpdatePermissionPromptResult *))reply
{
    // If this is a background application we need to focus it in order to bring the prompt
    // to the user's attention. Otherwise the prompt would be hidden behind other applications and
    // the user would not know why the application was paused.
    if ([SUApplicationInfo isBackgroundApplication:NSApp]) {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }
    
    if (![NSApp modalWindow]) { // do not prompt if there is is another modal window on screen
        SUUpdatePermissionPrompt *prompt = [[[self class] alloc] initPromptWithHost:host systemProfile:systemProfile reply:reply];
        NSWindow *window = [prompt window];
        if (window) {
            [NSApp runModalForWindow:window];
        }
    }
}

- (BOOL)shouldAskAboutProfile
{
    return [[self.host objectForInfoDictionaryKey:SUEnableSystemProfilingKey] boolValue];
}

- (NSString *)description { return [NSString stringWithFormat:@"%@ <%@>", [self class], [self.host bundlePath]]; }

- (void)windowDidLoad
{
	if (![self shouldAskAboutProfile])
	{
        NSRect frame = [[self window] frame];
        frame.size.height -= [self.moreInfoButton frame].size.height;
        [[self window] setFrame:frame display:YES];
    } else {
        // Set the table view's delegate so we can disable row selection.
        [self.profileTableView setDelegate:(id)self];
    }
}

- (BOOL)tableView:(NSTableView *) __unused tableView shouldSelectRow:(NSInteger) __unused row { return NO; }


- (NSImage *)icon
{
    return [SUApplicationInfo bestIconForBundle:self.host.bundle];
}

- (NSString *)promptDescription
{
    return [NSString stringWithFormat:SULocalizedString(@"Should %1$@ automatically check for updates? You can always check for updates manually from the %1$@ menu.", nil), [self.host name]];
}

- (IBAction)toggleMoreInfo:(id)__unused sender
{
    self.isShowingMoreInfo = !self.isShowingMoreInfo;

    NSView *contentView = [[self window] contentView];
    NSRect contentViewFrame = [contentView frame];
    NSRect windowFrame = [[self window] frame];

    NSRect profileMoreInfoViewFrame = [self.moreInfoView frame];
    NSRect profileMoreInfoButtonFrame = [self.moreInfoButton frame];
    NSRect descriptionFrame = [self.descriptionTextField frame];

	if (self.isShowingMoreInfo)
	{
        // Add the subview
        contentViewFrame.size.height += profileMoreInfoViewFrame.size.height;
        profileMoreInfoViewFrame.origin.y = profileMoreInfoButtonFrame.origin.y - profileMoreInfoViewFrame.size.height;
        profileMoreInfoViewFrame.origin.x = descriptionFrame.origin.x;
        profileMoreInfoViewFrame.size.width = descriptionFrame.size.width;

        windowFrame.size.height += profileMoreInfoViewFrame.size.height;
        windowFrame.origin.y -= profileMoreInfoViewFrame.size.height;

        [self.moreInfoView setFrame:profileMoreInfoViewFrame];
        [self.moreInfoView setHidden:YES];
        [contentView addSubview:self.moreInfoView
                     positioned:NSWindowBelow
                     relativeTo:self.moreInfoButton];
    } else {
        // Remove the subview
        [self.moreInfoView setHidden:NO];
        [self.moreInfoView removeFromSuperview];
        contentViewFrame.size.height -= profileMoreInfoViewFrame.size.height;

        windowFrame.size.height -= profileMoreInfoViewFrame.size.height;
        windowFrame.origin.y += profileMoreInfoViewFrame.size.height;
    }
    [[self window] setFrame:windowFrame display:YES animate:YES];
    [contentView setFrame:contentViewFrame];
    [contentView setNeedsDisplay:YES];
    [self.moreInfoView setHidden:!self.isShowingMoreInfo];
}

- (IBAction)finishPrompt:(id)sender
{
    self.reply([SUUpdatePermissionPromptResult updatePermissionPromptResultWithChoice:([sender tag] == 1 ? SUAutomaticallyCheck : SUDoNotAutomaticallyCheck) shouldSendProfile:self.shouldSendProfile]);
    
    [[self window] close];
    [NSApp stopModal];
}

@end
