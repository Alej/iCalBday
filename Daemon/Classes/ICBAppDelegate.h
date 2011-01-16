//
//  ICBAppDelegate.h
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ICBCalendarPairSynchronizer;

@interface ICBAppDelegate : NSObject <NSApplicationDelegate> {
	@private
	ICBCalendarPairSynchronizer *_calendarPairSynchronizer;
}

@property (nonatomic, retain) ICBCalendarPairSynchronizer *calendarPairSynchronizer;

- (BOOL)performSynchronization;
- (void)addDaemonToLoginItemsIfNeeded;

@end
