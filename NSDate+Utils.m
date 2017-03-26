//
//  NSDate+Utils.m
//  MyTripDiary
//
//  Created by PINCHAO LIU on 3/25/17.
//
//

#import "NSDate+Utils.h"

@implementation NSDate_Utils

-(NSDate *) dateWithoutTime
{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
	return [calendar dateFromComponents:components];
}

@end
