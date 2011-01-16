//
//  ICBMain.m
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ICBAppDelegate.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool *appAutoreleasePool = [[NSAutoreleasePool alloc] init];
	ICBAppDelegate *appDelegate = [[ICBAppDelegate alloc] init];
	[[NSApplication sharedApplication] setDelegate:appDelegate];
	[[NSApplication sharedApplication] run];
	[appDelegate release];
	[appAutoreleasePool drain];
	return 0;
}