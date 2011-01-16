//
//  ICBCalendarPairSynchronizer.m
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ICBCalendarPairSynchronizer.h"
#import "ICBStringConstants.h"
#import "ICBUtilities.h"

@interface CalAlarm (ICBAdditions)

+ (NSString *)icb_defaultAlarmSound;
+ (CalAlarm *)icb_defaultAlarmWithRelativeTrigger:(NSTimeInterval)defaultTrigger;

@end


@implementation ICBCalendarPairSynchronizer

@synthesize sourceCalendar=_sourceCalendar;
@synthesize targetCalendar=_targetCalendar;
@synthesize alarmTimeInterval=_alarmTimeInterval;
@synthesize alarmNameSuffix=_alarmNameSuffix;


+ (CalCalendar *)birthdaysCalendar {
	NSPredicate *birthdayCalendarPrediate = [NSPredicate predicateWithBlock:^(id object, NSDictionary *bindings){return [[object type] isEqualToString:CalCalendarTypeBirthday];}];
	return [[[[CalCalendarStore defaultCalendarStore] calendars] filteredArrayUsingPredicate:birthdayCalendarPrediate] lastObject];
}

+ (CalCalendar *)birthdayAlarmsCalendar {
	NSString *calendarUID = [[NSUserDefaults standardUserDefaults] stringForKey:ICBBirthdayAlarmsCalendarUID];
	CalCalendar *bAlarmsCalendar = (!calendarUID)?nil:[[CalCalendarStore defaultCalendarStore] calendarWithUID:calendarUID];
	if (!bAlarmsCalendar) {
		CalCalendar *bCalendar = [[self class] birthdaysCalendar];
		if (!bCalendar) {
			NSError *noBCalendar = [NSError errorWithDomain:CalCalendarStoreErrorDomain code:-1000 userInfo:[NSDictionary dictionaryWithObject:@"There is no birthday calendar" forKey:NSLocalizedDescriptionKey]];
			[NSApp presentError:noBCalendar];
			[[NSUserDefaults standardUserDefaults] setValue:nil forKey:ICBBirthdayAlarmsCalendarUID];
			return nil;
		}
		bAlarmsCalendar = [CalCalendar calendar];
		[bAlarmsCalendar setTitle:@"Birthday Alarms"];
		[bAlarmsCalendar setColor:[[self class] calendarColorFromSourceCalendar:bCalendar]];

		NSError *error;
		if (![[CalCalendarStore defaultCalendarStore] saveCalendar:bAlarmsCalendar error:&error]) {
			[NSApp presentError:error];
			return nil;
		}
		[[NSUserDefaults standardUserDefaults] setValue:[bAlarmsCalendar uid] forKey:ICBBirthdayAlarmsCalendarUID];
		[[NSUserDefaults standardUserDefaults] setValue:nil forKey:ICBBirthdayAlarmsToBirthdayEventsMappingTable];
	}
	return bAlarmsCalendar;
}

+ (NSColor *)calendarColorFromSourceCalendar:(CalCalendar *)sCalendar {
	NSColor *sCalendarColor = [sCalendar color];
	CGFloat *components = malloc([sCalendarColor numberOfComponents] * sizeof(CGFloat));
	assert(components != NULL);
	[sCalendarColor getComponents:components];
	for (NSUInteger i = 0; i < [sCalendarColor numberOfComponents]; i++) {
		components[i] *= 0.8;
	}
	sCalendarColor = [NSColor colorWithColorSpace:[sCalendarColor colorSpace] components:components count:[sCalendarColor numberOfComponents]];
	free(components);
	return [sCalendarColor colorWithAlphaComponent:1.0f];
}

- (id)initWithSourceCalendar:(CalCalendar *)sCal targetCalendar:(CalCalendar *)tCal {
	const NSTimeInterval kDefaultInterval = 10;
	if (!(self = [super init])) return self;
	_sourceCalendar = [sCal retain];
	_targetCalendar = [tCal retain];
	_alarmNameSuffix = @" alarm";
	_alarmTimeInterval = 3600 * kDefaultInterval;
	return self;
}

- (void)dealloc {
	[_sourceCalendar release]; _sourceCalendar = nil;
	[_targetCalendar release]; _targetCalendar = nil;
	[_alarmNameSuffix release]; _alarmNameSuffix = nil;
	[super dealloc];
}


- (CalEvent *)generateDefaultEventFromEvent:(CalEvent *)anEvent {
	CalEvent *newEvent = [CalEvent event];
	[newEvent setStartDate:anEvent.startDate];
	[newEvent setEndDate:anEvent.endDate];
	[newEvent setIsAllDay:YES];
	[newEvent setRecurrenceRule:[anEvent recurrenceRule]];
	[newEvent setTitle:[anEvent.title stringByAppendingString:self.alarmNameSuffix]];
	[newEvent setUrl:anEvent.url];
	[newEvent setAlarms:[NSArray arrayWithObject:[CalAlarm icb_defaultAlarmWithRelativeTrigger:self.alarmTimeInterval]]];
	return newEvent;	
}

#pragma mark -
#pragma mark Actions

- (BOOL)synchronize:(NSError **)anError {
	CalCalendarStore *calStore = [CalCalendarStore defaultCalendarStore];
	CalCalendar *sCalendar = self.sourceCalendar;
	CalCalendar *tCalendar = self.targetCalendar;
	NSMutableDictionary *mappingTable = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:ICBBirthdayAlarmsToBirthdayEventsMappingTable]];
	NSDictionary *reverseMappingTable = [NSDictionary dictionaryWithObjects:[mappingTable allKeys] forKeys:[mappingTable allValues]];
	
	
	NSPredicate *sourcePredicate = [CalCalendarStore eventPredicateWithStartDate:[ICBUtilities thisYearsFirstInstant] endDate:[ICBUtilities nextYearsFirstInstant] calendars:[NSArray arrayWithObject:sCalendar]];
	NSPredicate *targetPredicate = [CalCalendarStore eventPredicateWithStartDate:[ICBUtilities thisYearsFirstInstant] endDate:[ICBUtilities nextYearsFirstInstant] calendars:[NSArray arrayWithObject:tCalendar]];
	NSArray *sources = [calStore eventsWithPredicate:sourcePredicate];
	NSArray *targets = [calStore eventsWithPredicate:targetPredicate];
	NSDictionary *sourceMappingTable = [NSDictionary dictionaryWithObjects:sources forKeys:[sources valueForKey:@"uid"]];
	NSDictionary *targetsMappingTable = [NSDictionary dictionaryWithObjects:targets forKeys:[targets valueForKey:@"uid"]];
	
	for (CalEvent *source in sources) {
		if ([mappingTable valueForKey:[source uid]]) {
			CalEvent *targetAlarmEvent = [targetsMappingTable valueForKey:[mappingTable valueForKey:[source uid]]];
			if (targetAlarmEvent) {
				if (![targetAlarmEvent.startDate isEqualToDate:source.startDate]) {
					[targetAlarmEvent setStartDate:source.startDate];
					[targetAlarmEvent setEndDate:source.endDate];
					if (![calStore saveEvent:targetAlarmEvent span:CalSpanAllEvents error:anError]) return NO;
				}
				NSTimeInterval targetRelativeTrigger = [(CalAlarm *)[[targetAlarmEvent alarms] lastObject] relativeTrigger];
				if (targetRelativeTrigger != self.alarmTimeInterval) {
					[targetAlarmEvent setAlarms:[NSArray arrayWithObject:[CalAlarm icb_defaultAlarmWithRelativeTrigger:self.alarmTimeInterval]]];
					if (![calStore saveEvent:targetAlarmEvent span:CalSpanAllEvents error:anError]) return NO;
				}
				continue;
			}
		}
		CalEvent *targetAlarmEvent = [self generateDefaultEventFromEvent:source];
		[targetAlarmEvent setCalendar:tCalendar];
		if (![calStore saveEvent:targetAlarmEvent span:CalSpanAllEvents error:anError]) return NO;
		[mappingTable setValue:targetAlarmEvent.uid forKey:source.uid];
	}
	
	for (CalEvent *birthdayAlarm in targets) {
		if ([sourceMappingTable valueForKey:[reverseMappingTable valueForKey:birthdayAlarm.uid]]) continue;
		if (![calStore removeEvent:birthdayAlarm span:CalSpanAllEvents error:anError]) return NO;
	}
	
	[[NSUserDefaults standardUserDefaults] setValue:mappingTable forKey:ICBBirthdayAlarmsToBirthdayEventsMappingTable];
	return YES;
}

@end

@implementation CalAlarm (ICBAdditions)

+ (NSString *)icb_defaultAlarmSound {
	return @"Basso";
}

+ (CalAlarm *)icb_defaultAlarmWithRelativeTrigger:(NSTimeInterval)defaultTrigger {
	CalAlarm *defaultAlarm = [CalAlarm alarm];
	[defaultAlarm setRelativeTrigger:defaultTrigger];
	[defaultAlarm setSound:[[self class] icb_defaultAlarmSound]];
	return defaultAlarm;
}

@end

