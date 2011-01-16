//
//  ICBCalendarPairSynchronizer.h
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CalendarStore/CalendarStore.h>

@interface ICBCalendarPairSynchronizer : NSObject {
	@private
	CalCalendar *_sourceCalendar;
	CalCalendar *_targetCalendar;
	NSTimeInterval _alarmTimeInterval;
	NSString *_alarmNameSuffix;
}

@property (nonatomic, retain, readonly) CalCalendar *sourceCalendar;
@property (nonatomic, retain, readonly) CalCalendar *targetCalendar;
@property (nonatomic, assign) NSTimeInterval alarmTimeInterval;
@property (nonatomic, copy) NSString *alarmNameSuffix;

+ (CalCalendar *)birthdaysCalendar;
+ (CalCalendar *)birthdayAlarmsCalendar;
+ (NSColor *)calendarColorFromSourceCalendar:(CalCalendar *)sCalendar;
- (CalEvent *)generateDefaultEventFromEvent:(CalEvent *)anEvent;
- (id)initWithSourceCalendar:(CalCalendar *)sCal targetCalendar:(CalCalendar *)tCal;
- (BOOL)synchronize:(NSError **)anError;


@end
