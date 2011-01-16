//
//  ICBBoolToStartStopValueTransformer.m
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ICBBoolToStartStopValueTransformer.h"


@implementation ICBBoolToStartStopValueTransformer

+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    if (![value boolValue]) return @"Start";
	return @"Stop";
}

@end
