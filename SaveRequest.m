/**  CycleTracks, Copyright 2009-2013 San Francisco County Transportation Authority
 *                                    San Francisco, CA, USA
 *
 *   @author Matt Paul <mattpaul@mopimp.com>
 *
 *   This file is part of CycleTracks.
 *
 *   CycleTracks is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   CycleTracks is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with CycleTracks.  If not, see <http://www.gnu.org/licenses/>.
 */

//
//  SaveRequest.m
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 8/25/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>

#import "constants.h"
#import "FloridaTripTrackerAppDelegate.h"
#import "SaveRequest.h"


@implementation SaveRequest

@synthesize request, deviceUniqueIdHash, postVars;

#pragma mark init

- initWithPostVars:(NSDictionary *)inPostVars
{
	if (self = [super init])
	{
		// [LIU] this kind general info should be set as a public static standalone info
		// Nab the unique device id hash from our delegate.
		FloridaTripTrackerAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		self.deviceUniqueIdHash = delegate.uniqueIDHash;
		
		// create request.
		self.request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kSaveURL]]; // prop set retains

		// setup POST vars
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
		
		self.postVars = [NSMutableDictionary dictionaryWithDictionary:inPostVars];
		
		// get the user dictionary
		NSMutableDictionary *user= [postVars objectForKey:@"user"];
		// add hash of device id
		[user setObject:deviceUniqueIdHash forKey:@"device"];
		// add updated user dictionary to postVars
		[postVars setObject:user forKey:@"user"];
		
		NSData *data= [NSJSONSerialization dataWithJSONObject:postVars options:nil error:nil];
		NSData *pretty= [NSJSONSerialization dataWithJSONObject:postVars options:NSJSONWritingPrettyPrinted error:nil];

		NSLog(@"NSJSON DATA: %@", [[NSString alloc] initWithData:pretty encoding:NSUTF8StringEncoding]);

		//NSLog(@"initializing HTTP POST request to %@ with %d bytes", kSaveURL, [data length]);
		//NSLog(@"request sent: %@",data);
		[request setHTTPBody:data];

	}
	
	return self;
}


#pragma mark instance methods

// add POST vars to request
- (NSURLConnection *)getConnectionWithDelegate:(id)delegate
{
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:delegate];
	return conn;
}

@end
