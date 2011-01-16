//
//  ICBAppDelegate.m
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ICBAppDelegate.h"
#import "ICBStringConstants.h"
#import "ICBCalendarPairSynchronizer.h"

@interface ICBAppDelegate ()
- (LSSharedFileListItemRef)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(CFURLRef)thePath pathAsString:(NSString **)pathString;
- (BOOL)loginItemsAddWithLoginItemREference:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath;
- (BOOL)loginItemsRemoveItem:(LSSharedFileListItemRef)item inItemsList:(LSSharedFileListRef)theLoginItems;
@end

@implementation ICBAppDelegate

@synthesize calendarPairSynchronizer=_calendarPairSynchronizer;

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:3600*10] forKey:ICBAlarmOffset]];
}

- (void)dealloc {
	[_calendarPairSynchronizer release]; _calendarPairSynchronizer = nil;
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	ICBCalendarPairSynchronizer *calSync = [[ICBCalendarPairSynchronizer alloc] 
											initWithSourceCalendar:[ICBCalendarPairSynchronizer birthdaysCalendar] 
											targetCalendar:[ICBCalendarPairSynchronizer birthdayAlarmsCalendar]];
	[calSync setAlarmTimeInterval:[[[NSUserDefaults standardUserDefaults] valueForKey:ICBAlarmOffset] doubleValue]];
	[self setCalendarPairSynchronizer:calSync];
	if (![self performSynchronization]) return;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externallyChangedCalendar:) name:CalEventsChangedExternallyNotification object:[CalCalendarStore defaultCalendarStore]];
	NSDistributedNotificationCenter *dNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
	[dNotificationCenter postNotificationName:ICBDaemonDidFinishLaunching object:ICBDaemonBundleIdentifier userInfo:nil deliverImmediately:YES];
	[dNotificationCenter addObserver:self selector:@selector(daemonShouldTerminate:) name:ICBDaemonShouldTerminate object:ICBPrefPaneBundleIdentifier suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	[dNotificationCenter addObserver:self selector:@selector(prefPaneWillUnselect:) name:ICBPrefPaneWillUnselect object:ICBPrefPaneBundleIdentifier suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	[self addDaemonToLoginItemsIfNeeded];
}

- (void)prefPaneWillUnselect:(NSNotification *)aNotification {
	NSTimeInterval alarmOffset = [[[aNotification userInfo] valueForKey:ICBAlarmOffset] doubleValue];
	[[NSUserDefaults standardUserDefaults] setValue:[[aNotification userInfo] valueForKey:ICBAlarmOffset] forKey:ICBAlarmOffset];
	[self.calendarPairSynchronizer setAlarmTimeInterval:alarmOffset];
	[self performSynchronization];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	NSDistributedNotificationCenter *dNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
	[dNotificationCenter postNotificationName:ICBDaemonWillTerminate object:ICBDaemonBundleIdentifier userInfo:nil deliverImmediately:YES];
}

- (void)externallyChangedCalendar:(NSNotification *)aNotification {
	[self performSynchronization];
}

- (void)daemonShouldTerminate:(NSNotification *)aNotification {
	[NSApp terminate:self];
}

- (BOOL)performSynchronization {
	NSError *anError;
	if (![self.calendarPairSynchronizer synchronize:&anError]) {
		[NSApp presentError:anError];
		return NO;
	}
	return YES;
}


#pragma mark -
#pragma mark loginItems


- (void)addDaemonToLoginItemsIfNeeded {
	NSString *installedDaemonBundleVersion = [[NSUserDefaults standardUserDefaults] stringForKey:ICBInstalledDaemonBundleVersion];
	NSString *currentBundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	BOOL needsUpdate = (![installedDaemonBundleVersion isEqualToString:currentBundleVersion]);
	BOOL previouslyInstalled = [[NSUserDefaults standardUserDefaults] boolForKey:ICBAddedDaemonToLoginItems];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	CFURLRef url = NULL;
	NSString *pathAsString;
	CFURLRef installationURL = (CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	LSSharedFileListItemRef existingItem = [self loginItemExistsWithLoginItemReference:loginItems ForPath:url pathAsString:&pathAsString];
	BOOL itemExists = (existingItem != NULL);
	if (itemExists && !needsUpdate) {
		if ([pathAsString isEqualToString:[(NSURL*)installationURL absoluteString]])return;
	}
	if (!itemExists && previouslyInstalled)return;
	if (itemExists)[self loginItemsRemoveItem:existingItem inItemsList:loginItems];
	BOOL installed = [self loginItemsAddWithLoginItemREference:loginItems forPath:installationURL];
	if (installed) {
		[[NSUserDefaults standardUserDefaults] setValue:currentBundleVersion forKey:ICBInstalledDaemonBundleVersion];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:ICBAddedDaemonToLoginItems];	
	}
}


- (LSSharedFileListItemRef)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(CFURLRef)thePath pathAsString:(NSString **)pathString {
	UInt32 seedValue;
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = [(NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue) autorelease];
	NSString *bunlePath = [[NSBundle mainBundle] bundlePath];
	NSString *lastComponent = [bunlePath lastPathComponent];
	for (id item in loginItemsArray) {    
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			NSString *pathAsString = [(NSURL*)thePath absoluteString];
			if ([pathAsString rangeOfString:lastComponent].location != NSNotFound) {
				*pathString = pathAsString;
				return itemRef;
			}
		}
	}
	return NULL;
}

- (BOOL)loginItemsAddWithLoginItemREference:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath {
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, thePath, NULL, NULL);
	if (item != NULL) {
		CFRelease(item);
		return YES;
	}	
	return NO;
}

- (BOOL)loginItemsRemoveItem:(LSSharedFileListItemRef)item inItemsList:(LSSharedFileListRef)theLoginItems {
	OSStatus status = LSSharedFileListItemRemove(theLoginItems,item);
	return (status == noErr);
}


@end
