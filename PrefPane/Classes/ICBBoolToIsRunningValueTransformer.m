//
//  ICBBoolToIsRunningValueTransformer.m
//  iCalBday
//
//  Created by Alejandro Rodríguez on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ICBBoolToIsRunningValueTransformer.h"


@implementation ICBBoolToIsRunningValueTransformer

+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    if (![value boolValue]) return @"is not running";
	return @"is running";
}

@end
