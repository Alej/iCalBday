//
//  ICBStringConstants.h
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* User Defaults */
extern NSString *const ICBBirthdayAlarmsCalendarUID;
extern NSString *const ICBBirthdayAlarmsToBirthdayEventsMappingTable;
extern NSString *const ICBAlarmOffset;
extern NSString *const ICBInstalledDaemonBundleVersion;
extern NSString *const ICBAddedDaemonToLoginItems;

/* Bundle Identifiers */
extern NSString *const ICBDaemonBundleIdentifier;
extern NSString *const ICBPrefPaneBundleIdentifier;

/* Notifications */
extern NSString *const ICBDaemonWillTerminate;
extern NSString *const ICBDaemonDidFinishLaunching;
extern NSString *const ICBPrefPaneWillUnselect;
extern NSString *const ICBDaemonShouldTerminate;