//
//  ICBUtilities.m
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ICBUtilities.h"


@implementation ICBUtilities

+ (BOOL)isRunning:(NSString *)theBundleIdentifier {
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };
	
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		if(infoDict) {
			NSString *bundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
			isRunning = bundleID && [bundleID isEqualToString:theBundleIdentifier];
			CFMakeCollectable(infoDict);
			[infoDict release];
		}
		if (isRunning)
			break;
	}
	
	return isRunning;
}

+ (NSDate *)thisYearsFirstInstant {
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
	return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

+ (NSDate *)nextYearsFirstInstant {
	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
	[dateComponents setYear:[dateComponents year] + 1];
	return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

@end
