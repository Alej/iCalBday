//
//  iCalBdayPref.h
//  iCalBday
//
//  Created by Alejandro Rodr’guez on 1/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface iCalBdayPref : NSPreferencePane {
	@private
	BOOL _daemonRunning;
	NSButton *_startStopDaemonButton;
	NSDate *_defaultAlarmTime;
	NSDatePicker *_textualDatePicker;
}

@property (nonatomic, assign, getter=isDaemonRunning) BOOL daemonRunning;
@property (nonatomic, retain) IBOutlet NSButton *startStopDaemonButton;
@property (nonatomic, retain) NSDate *defaultAlarmTime;
@property (nonatomic, retain) IBOutlet NSDatePicker *textualDatePicker;
- (IBAction)startStopDaemon:(id)sender;

- (void)launchDaemon;
- (void)terminateDaemon;

@end
