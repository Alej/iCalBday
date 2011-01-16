//
//  iCalBdayPref.m
//  iCalBday
//
//  Created by Alejandro Rodr’guez on 1/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "iCalBdayPref.h"
#import "ICBUtilities.h"
#import "ICBStringConstants.h"

@interface iCalBdayPref ()

- (void)daemonDidFinishLaunching:(NSNotification *)aNotification;
- (void)daemonWillTerminate:(NSNotification *)aNotification;

@end


@implementation iCalBdayPref

@synthesize daemonRunning=_daemonRunning;
@synthesize startStopDaemonButton=_startStopDaemonButton;
@synthesize defaultAlarmTime=_defaultAlarmTime;
@synthesize textualDatePicker=_textualDatePicker;

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:3600*10] forKey:ICBAlarmOffset]];
}

- (void)dealloc {
	[_startStopDaemonButton release]; _startStopDaemonButton = nil;
	[_defaultAlarmTime release]; _defaultAlarmTime = nil;
	[_textualDatePicker release]; _textualDatePicker = nil;
	[super dealloc];
}

- (void)willSelect {
	[self.textualDatePicker setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	NSTimeInterval tInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:ICBAlarmOffset];
	[self setDefaultAlarmTime:[NSDate dateWithTimeIntervalSince1970:tInterval]];
	[self setDaemonRunning:[ICBUtilities isRunning:ICBDaemonBundleIdentifier]];
	NSDistributedNotificationCenter *dNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
	[dNotificationCenter addObserver:self selector:@selector(daemonDidFinishLaunching:) name:ICBDaemonDidFinishLaunching object:ICBDaemonBundleIdentifier suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	[dNotificationCenter addObserver:self selector:@selector(daemonWillTerminate:) name:ICBDaemonWillTerminate object:ICBDaemonBundleIdentifier suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];														 
	
}

- (void)willUnselect {
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:[self.defaultAlarmTime timeIntervalSince1970]] forKey:ICBAlarmOffset];
	NSDistributedNotificationCenter *dNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:[self.defaultAlarmTime timeIntervalSince1970]] forKey:ICBAlarmOffset];
	[dNotificationCenter postNotificationName:ICBPrefPaneWillUnselect object:ICBPrefPaneBundleIdentifier userInfo:userInfo deliverImmediately:YES];
	[dNotificationCenter removeObserver:self name:ICBDaemonDidFinishLaunching object:ICBDaemonBundleIdentifier];
	[dNotificationCenter removeObserver:self name:ICBDaemonWillTerminate object:ICBDaemonBundleIdentifier];
}

#pragma mark -
#pragma mark Notifications

- (void)daemonDidFinishLaunching:(NSNotification *)aNotification {
	[self setDaemonRunning:YES];
}

- (void)daemonWillTerminate:(NSNotification *)aNotification {
	[self setDaemonRunning:NO];
}

#pragma mark -
#pragma mark Actions

- (IBAction)startStopDaemon:(id)sender {
	[self.startStopDaemonButton setEnabled:NO];
	[self.startStopDaemonButton performSelector:@selector(setEnabled:) withObject:[NSNumber numberWithBool:YES] afterDelay:1.0f];
	if ([self isDaemonRunning]) {
		[self terminateDaemon];
	} else {
		[self launchDaemon];
	}
}

- (void)launchDaemon {
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:ICBDaemonBundleIdentifier options:NSWorkspaceLaunchWithoutAddingToRecents|NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifier:NULL];
}

- (void)terminateDaemon {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:ICBDaemonShouldTerminate object:ICBPrefPaneBundleIdentifier userInfo:nil deliverImmediately:YES];
}


@end
