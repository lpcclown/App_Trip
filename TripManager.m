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
//  TripManager.m
//	CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/22/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>


#import "CJSONSerializer.h"
#import "constants.h"
#import "SaveRequest.h"
#import "Trip.h"
#import "TripManager.h"
#import "User.h"
#import "SavedTripsViewController.h"
#import "OneTimeQuestionsViewController.h"
#import "CoordLocal.h"
#import "RecordTripViewController.h"
#import "ServerInteract.h"
#import "FloridaTripTrackerAppDelegate.h"

// use this epsilon for both real-time and post-processing distance calculations
#define kEpsilonAccuracy		100.0

// use these epsilons for real-time distance calculation only
#define kEpsilonTimeInterval	10.0
#define kEpsilonSpeed			30.0	// meters per sec = 67 mph

#define kSaveProtocolVersion_1	1
#define kSaveProtocolVersion_2	2

//#define kSaveProtocolVersion	kSaveProtocolVersion_1
#define kSaveProtocolVersion	kSaveProtocolVersion_2

@implementation TripManager

@synthesize activityDelegate, activityIndicator, alertDelegate, saving, tripNotes, tripNotesText;
@synthesize coords, dirty, trip, managedObjectContext, receivedData, counter;


- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
    if ( self = [super init] )
	{
		self.activityDelegate		= self;
		self.coords					= [[NSMutableArray alloc] initWithCapacity:1000];
		distance					= 0.0;
		self.managedObjectContext	= context;
		self.trip					= nil;
		purposeIndex				= -1;
    }
    return self;
}


- (BOOL)loadTrip:(Trip*)_trip
{
    if ( _trip )
	{
		self.trip					= _trip;
		distance					= [_trip.distance doubleValue];
		self.managedObjectContext	= [_trip managedObjectContext];
		
		// NOTE: loading coords can be expensive for a large trip
		NSLog(@"loading %fm trip started at %@...", distance, _trip.startTime);

		// sort coords by recorded date ASCENDING so that the coord at index=0 is the first
		
		NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recorded" ascending:YES];
		NSArray *sortDescriptors	= [NSArray arrayWithObjects:dateDescriptor, nil];
		self.coords					= [[[_trip.coords allObjects] sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
		
		NSLog(@"loading %d coords completed.", [self.coords count]);

		// save updated duration to CoreData
		// [LIU] below four lines do not work, commented out
		//		NSError *error;
		//		if (![self.managedObjectContext save:&error]) {
		//			// Handle the error.
		//			NSLog(@"loadTrip error %@, %@", error, [error localizedDescription]);
		//		}
		
		/*
		// recalculate trip distance
		CLLocationDistance newDist	= [self calculateTripDistance:_trip];
		
		NSLog(@"newDist: %f", newDist);
		NSLog(@"oldDist: %f", distance);
		*/
		
		// TODO: initialize purposeIndex from trip.purpose
		purposeIndex				= -1;
    }
    return YES;
}

- (void)unloadTrip
{
    [self.coords removeAllObjects];
    distance					= 0.0;
    self.trip					= nil;
    purposeIndex				= -1;

}


- (id)initWithTrip:(Trip*)_trip
{
    if ( self = [super init] )
	{
		self.activityDelegate = self;
		[self loadTrip:_trip];
    }
    return self;
}


- (UIActivityIndicatorView *)createActivityIndicator
{
	if ( activityIndicator == nil )
	{
		CGRect frame = CGRectMake( 130.0, 88.0, kActivityIndicatorSize, kActivityIndicatorSize );
		activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:frame];
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		[activityIndicator sizeToFit];
	}
	return activityIndicator;
}


- (void)createTripNotesText
{
	tripNotesText = [[UITextView alloc] initWithFrame:CGRectMake( 12.0, 50.0, 260.0, 65.0 )];
	tripNotesText.delegate = self;
	tripNotesText.enablesReturnKeyAutomatically = NO;
	tripNotesText.font = [UIFont fontWithName:@"Arial" size:16];
	tripNotesText.keyboardAppearance = UIKeyboardAppearanceAlert;
	tripNotesText.keyboardType = UIKeyboardTypeDefault;
	tripNotesText.returnKeyType = UIReturnKeyDone;
	tripNotesText.text = kTripNotesPlaceholder;
	tripNotesText.textColor = [UIColor grayColor];
}


#pragma mark UITextViewDelegate


- (void)textViewDidBeginEditing:(UITextView *)textView
{
	NSLog(@"textViewDidBeginEditing");
	
	if ( [textView.text compare:kTripNotesPlaceholder] == NSOrderedSame )
	{
		textView.text = @"";
		textView.textColor = [UIColor blackColor];
	}
}


- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	NSLog(@"textViewShouldEndEditing: \"%@\"", textView.text);
	
	if ( [textView.text compare:@""] == NSOrderedSame )
	{
		textView.text = kTripNotesPlaceholder;
		textView.textColor = [UIColor grayColor];
	}
	
	return YES;
}


// this code makes the keyboard dismiss upon typing done / enter / return
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if ([text isEqualToString:@"\n"])
	{
		[textView resignFirstResponder];
		return NO;
	}
	
	return YES;
}


- (CLLocationDistance)distanceFrom:(CoordLocal*)prev to:(CoordLocal*)next realTime:(BOOL)realTime
{
	CLLocation *prevLoc = [[CLLocation alloc] initWithLatitude:[prev.latitude doubleValue] 
													 longitude:[prev.longitude doubleValue]];
	CLLocation *nextLoc = [[CLLocation alloc] initWithLatitude:[next.latitude doubleValue] 
													 longitude:[next.longitude doubleValue]];
	
	CLLocationDistance	deltaDist	= [nextLoc distanceFromLocation:prevLoc];
	NSTimeInterval		deltaTime	= [next.recorded timeIntervalSinceDate:prev.recorded];
	CLLocationDistance	newDist		= 0.;
	
	// sanity check accuracy
	if ( [prev.hAccuracy doubleValue] < kEpsilonAccuracy && 
		 [next.hAccuracy doubleValue] < kEpsilonAccuracy )
	{
		// sanity check time interval
		if ( !realTime || deltaTime < kEpsilonTimeInterval )
		{
			newDist += deltaDist;
		}
		else
			NSLog(@"WARNING deltaTime exceeds epsilon: %f => throw out deltaDist: %f", deltaTime, deltaDist);
	}
	else
		NSLog(@"WARNING accuracy exceeds epsilon: %f => throw out deltaDist: %f", 
			  MAX([prev.hAccuracy doubleValue], [next.hAccuracy doubleValue]) , deltaDist);
	
	return newDist;
}


- (CLLocationDistance)addCoord:(CLLocation *)location
{
	// Create and configure a new instance of the Coord entity
	// [LIU] Record the coord info to new table CoordLocal, which doesn't have relationship with Trip table
	counter ++;
	if (counter%5 ==0 ){
		CoordLocal *coordLocal = [NSEntityDescription insertNewObjectForEntityForName:@"CoordLocal" inManagedObjectContext:managedObjectContext];
		
		[coordLocal setAltitude:[NSNumber numberWithInt:location.altitude]];
		[coordLocal setLatitude:[NSNumber numberWithDouble:location.coordinate.latitude]];
		[coordLocal setLongitude:[NSNumber numberWithDouble:location.coordinate.longitude]];
		
		// NOTE: location.timestamp is a constant value on Simulator
		//[coord setRecorded:[NSDate date]];
		[coordLocal setRecorded:location.timestamp];
		
		[coordLocal setSpeed:[NSNumber numberWithDouble:location.speed]];
		[coordLocal setHAccuracy:[NSNumber numberWithDouble:location.horizontalAccuracy]];
		[coordLocal setVAccuracy:[NSNumber numberWithDouble:location.verticalAccuracy]];
		[coordLocal setSendFlag:@0];
		NSError *error;
		
		if (![managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"TripManager addCoord to DB error %@, %@", error, [error localizedDescription]);
		}
		
		
		[coords insertObject:coordLocal atIndex:0];
		NSLog(@"# coords = %lu", (unsigned long)[coords count]);
		if (counter != 5){
			CoordLocal *prev  = [coords objectAtIndex:1];
			distance	+= [self distanceFrom:prev to:coordLocal realTime:YES];}
	}
	if (counter%10000 == 0){
	
		NSArray *coordsArray = [RecordTripViewController obtainTripsArray:0];
		
		//[LIU] send array directly
		NSData *responseData = [ServerInteract sendRequest:coordsArray toURLAddress:kUpdateCoorFull];
		
		NSDictionary *serverFeedback = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
		NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
		if ([serverFeedbackString hasSuffix:@"successfully."]){
			
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			request.predicate = [NSPredicate predicateWithFormat:@"sendFlag == %@", @0];
			FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
			NSManagedObjectContext *managedContext = [delegate managedObjectContext];
			NSEntityDescription *coordLocal = [NSEntityDescription entityForName:@"CoordLocal" inManagedObjectContext:managedContext];
			[request setEntity:coordLocal];
			NSArray *sentTrip = [managedContext executeFetchRequest:request error:nil];
			
			NSEnumerator *e = [sentTrip objectEnumerator];
			NSManagedObject* object;
			while (object = [e nextObject]) {
				[object setValue:@1 forKey:@"sendFlag"];
			}
			
			[managedContext save:nil];
		}
		
	
	}
	return distance;
}


- (CLLocationDistance)getDistanceEstimate
{
	return distance;
}

- (NSMutableDictionary *)userDictionary {
	NSMutableDictionary *userDict = [[NSMutableDictionary alloc] init];
	
	NSFetchRequest		*request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSError *error;
	NSInteger count = [managedObjectContext countForFetchRequest:request error:&error];
	//NSLog(@"saved user count  = %d", count);
	
	if ( count )
	{
		NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
		if (mutableFetchResults == nil) {
			// Handle the error.
			NSLog(@"no saved user");
			if ( error != nil )
				NSLog(@"TripManager fetch saved user data error %@, %@", error, [error localizedDescription]);
		}
		
		User *user = [mutableFetchResults objectAtIndex:0];
		if ( user != nil )
		{
			// initialize text fields to saved personal info
			[userDict setValue:user.age			forKey:@"age"];
			[userDict setValue:user.gender		forKey:@"gender"];
			[userDict setValue:user.empFullTime forKey:@"fulltime"];
			[userDict setValue:user.empHomemaker forKey:@"homemaker"];
			[userDict setValue:user.empLess5Months forKey:@"empLess5Months"];
			[userDict setValue:user.empPartTime forKey:@"parttime"];
			[userDict setValue:user.empRetired forKey:@"retired"];
			[userDict setValue:user.empSelfEmployed forKey:@"selfemployed"];
			[userDict setValue:user.empUnemployed forKey:@"unemployed"];
			[userDict setValue:user.empWorkAtHome forKey:@"workAtHome"];
			[userDict setValue:user.studentStatus forKey:@"studentlevel"];
			[userDict setValue:user.hasADisabledParkingPass forKey:@"disableparkpass"];
			[userDict setValue:user.hasADriversLicense forKey:@"driverLicense"];
			[userDict setValue:user.hasATransitPass forKey:@"transitpass"];
			[userDict setValue:user.isAStudent forKey:@"student"];
			[userDict setValue:user.numWorkTrips forKey:@"workdays"];
		}
		
		else {
			NSLog(@"TripManager fetch user FAIL");
			userDict= nil;
		}
		
	}
	else {
		NSLog(@"TripManager WARNING no saved user data to encode");
		userDict= nil;
	}
	
	return userDict;
}


- (NSString*)jsonEncodeUserData
{
	NSLog(@"jsonEncodeUserData");
	NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithCapacity:7];
	
	NSFetchRequest		*request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSError *error;
	NSInteger count = [managedObjectContext countForFetchRequest:request error:&error];
	//NSLog(@"saved user count  = %d", count);
	
	if ( count )
	{
		NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
		if (mutableFetchResults == nil) {
			// Handle the error.
			NSLog(@"no saved user");
			if ( error != nil )
				NSLog(@"TripManager fetch saved user data error %@, %@", error, [error localizedDescription]);
		}
		
		User *user = [mutableFetchResults objectAtIndex:0];
		if ( user != nil )
		{
			// initialize text fields to saved personal info
			[userDict setValue:user.age			forKey:@"age"];
			[userDict setValue:user.gender		forKey:@"gender"];
			[userDict setValue:user.empFullTime forKey:@"fulltime"];
			[userDict setValue:user.empHomemaker forKey:@"homemaker"];
			[userDict setValue:user.empLess5Months forKey:@"empLess5Months"];
			[userDict setValue:user.empPartTime forKey:@"parttime"];
			[userDict setValue:user.empRetired forKey:@"retired"];
			[userDict setValue:user.empSelfEmployed forKey:@"selfemployed"];
			[userDict setValue:user.empUnemployed forKey:@"unemployed"];
			[userDict setValue:user.empWorkAtHome forKey:@"workAtHome"];
			[userDict setValue:user.studentStatus forKey:@"studentlevel"];
			[userDict setValue:user.hasADisabledParkingPass forKey:@"disableparkpass"];
			[userDict setValue:user.hasADriversLicense forKey:@"driverLicense"];
			[userDict setValue:user.hasATransitPass forKey:@"transitpass"];
			[userDict setValue:user.isAStudent forKey:@"student"];
			[userDict setValue:user.numWorkTrips forKey:@"workdays"];
		}
		else
			NSLog(@"TripManager fetch user FAIL");
		
	}
	else
		NSLog(@"TripManager WARNING no saved user data to encode");
	
	NSLog(@"serializing user data to JSON...");
	NSString *jsonUserData = [[CJSONSerializer serializer] serializeObject:userDict];
	NSLog(@"%@", jsonUserData );
	
	return jsonUserData;
}


- (void)saveNotes:(NSString*)notes
{
	// not using this TODO: Delete all references
}
- (void)saveTrip
{
	NSLog(@"%@", trip);
	
	//		[trip setDuration:[NSNumber numberWithDouble:duration]];
	//		[trip setStopTime:[last recorded]];
	[trip setSaved:[NSDate date]];
	NSError *error;
	if (![managedObjectContext save:&error])
	{
		// Handle the error.
		NSLog(@"TripManager setSaved error %@, %@", error, [error localizedDescription]);

	}
}
//- (void)saveTrip
//{
//	// present UIAlertView "Saving..."
//	saving = [[UIAlertView alloc] initWithTitle:kSavingTitle
//										message:kConnecting
//									   delegate:nil
//							  cancelButtonTitle:nil
//							  otherButtonTitles:nil];
//	
//	NSLog(@"created saving dialog: %@", saving);
//	
//
//	
//	[self createActivityIndicator];
//	[activityIndicator startAnimating];
//	[saving addSubview:activityIndicator];
//	[saving show];
//	
//	//NSLog(@"about to save trip with %d coords...", [coords count]);
//	[activityDelegate updateSavingMessage:kPreparingData];
//	NSLog(@"%@", trip);
//
//	// close out Trip record
//	// NOTE: this code assumes we're saving the current recording in progress
//	
//	/* TODO: revise to work with following edge cases:
//	 o coords unsorted
//	 o break in recording => can't calc duration by comparing first & last timestamp,
//	   incrementally tally delta time if < epsilon instead
//	 o recalculate distance
//	 */
//	if ( trip && [coords count] )
//	{
//		CLLocationDistance newDist = [self calculateTripDistance:trip];
//		NSLog(@"real-time distance = %.0fm", distance);
//		NSLog(@"post-processing    = %.0fm", newDist);
//		
//		distance = newDist;
//		[trip setDistance:[NSNumber numberWithDouble:distance]];
//		
//		CoordLocal *last		= [coords objectAtIndex:0];
//		CoordLocal *first	= [coords lastObject];
//		NSTimeInterval duration = [last.recorded timeIntervalSinceDate:first.recorded];
//		NSLog(@"duration = %.0fs", duration);
//		[trip setDuration:[NSNumber numberWithDouble:duration]];
//		[trip setStopTime:[last recorded]];
//	}
//	
//	[trip setSaved:[NSDate date]];
//	
//	NSError *error;
//	if (![managedObjectContext save:&error])
//	{
//		// Handle the error.
//		NSLog(@"TripManager setSaved error %@, %@", error, [error localizedDescription]);
//	}
//	else
//		NSLog(@"Saved trip: %@ (%@m, %@s)", trip.purpose, trip.distance, trip.duration );
//
//	dirty = YES;
//	
//	// get array of coords
//	NSMutableDictionary *tripDict = [NSMutableDictionary dictionaryWithCapacity:[coords count]];
//	NSEnumerator *enumerator = [coords objectEnumerator];
//	Coord *coord;
//	
//	// format date as a string
//	NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];		
//	[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//
//	// TODO: test more campact float representations with NSString, NSNumberFormatter
//
//#if kSaveProtocolVersion == kSaveProtocolVersion_2
//	NSLog(@"saving using protocol version 2");
//	NSMutableArray *trips= [[NSMutableArray alloc] init];
//	
//	// create a tripDict entry for each coord
//	while (coord = [enumerator nextObject])
//	{
//		NSMutableDictionary *coordsDict = [NSMutableDictionary dictionaryWithCapacity:7];
//		NSMutableDictionary *coordsKeyDict = [NSMutableDictionary dictionaryWithCapacity:1];
//		[coordsDict setValue:coord.altitude  forKey:@"alt"];
//		[coordsDict setValue:coord.latitude  forKey:@"lat"];
//		[coordsDict setValue:coord.longitude forKey:@"lon"];
//		[coordsDict setValue:coord.speed     forKey:@"spd"];
//		[coordsDict setValue:coord.hAccuracy forKey:@"hac"];
//		[coordsDict setValue:coord.vAccuracy forKey:@"vac"];
//		
//		NSString *newDateString = [outputFormatter stringFromDate:coord.recorded];
//		[coordsDict setValue:newDateString forKey:@"rec"];
//		[tripDict setValue:coordsDict forKey:newDateString];
//		[coordsKeyDict setValue:coordsDict forKey:@"coord"];
//		[trips addObject:coordsKeyDict];
//		//[tripDict setValue:coordsDict forKey:@"coord"];
//	}
//#else
//	NSLog(@"saving using protocol version 1");
//	
//	// create a tripDict entry for each coord
//	while (coord = [enumerator nextObject])
//	{
//		NSMutableDictionary *coordsDict = [NSMutableDictionary dictionaryWithCapacity:7];
//		[coordsDict setValue:coord.altitude  forKey:@"altitude"];
//		[coordsDict setValue:coord.latitude  forKey:@"latitude"];
//		[coordsDict setValue:coord.longitude forKey:@"longitude"];
//		[coordsDict setValue:coord.speed     forKey:@"speed"];
//		[coordsDict setValue:coord.hAccuracy forKey:@"hAccuracy"];
//		[coordsDict setValue:coord.vAccuracy forKey:@"vAccuracy"];
//		
//		NSString *newDateString = [outputFormatter stringFromDate:coord.recorded];
//		[coordsDict setValue:newDateString forKey:@"recorded"];
//		[trips addObject:coordsDict];
//		[tripDict setValue:coordsDict forKey:newDateString];
//	}
//#endif
//
//	NSLog(@"serializing trip data to JSON...");
//	//NSString *jsonTripData = [[CJSONSerializer serializer] serializeObject:tripDict];
//	
//	//NSData *jsonTripData= [NSJSONSerialization dataWithJSONObject:allCords options:nil error:nil];
//	//NSLog(@"NSJSON DATA: %@", [[NSString alloc] initWithData:jsonTripData encoding:NSUTF8StringEncoding]);
//	
//	// get trip purpose
//	NSString *purpose;
//	if ( trip.purpose )
//		purpose = trip.purpose;
//	else
//		purpose = @"unknown";
//	
//	// get start date
//	NSString *start = [outputFormatter stringFromDate:trip.startTime];
//	NSLog(@"start: %@", start);
//	
//
//	// encode user data
//	//  NSString *jsonUserData = [self jsonEncodeUserData];
//
//	// NOTE: device hash added by SaveRequest initWithPostVars
//	NSMutableDictionary *postVars = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//							  trips, @"coords",
//							  purpose, @"purpose", nil];
//	
//	NSArray *tripQKeys = [[[trip entity] attributesByName] allKeys];
//	NSDictionary *tripQDict = [trip dictionaryWithValuesForKeys:tripQKeys];
//	[postVars setValuesForKeysWithDictionary:tripQDict];
//	
//	// change all dates to strings
//	[postVars setValue:start forKey:@"startTime"];
//	[postVars setValue:[outputFormatter stringFromDate:trip.stopTime] forKey:@"stopTime"];
//	// we don't send "saved", "uploaded", distance, or duration
//	[postVars removeObjectForKey:@"saved"];
//	[postVars removeObjectForKey:@"uploaded"];
//	[postVars removeObjectForKey:@"duration"];
//	[postVars removeObjectForKey:@"distance"];
//	// temporarily hiding fare; do not send this removal to production
//	//[postVars removeObjectForKey:@"fare"];
//	
//	[postVars setValue:[self userDictionary] forKey:@"user"];
//	NSString *versionString= [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
//	[postVars setValue:[NSNumber numberWithInt:[versionString intValue]] forKey:@"version"];
//							 
//	// create save request
//	SaveRequest *saveRequest = [[SaveRequest alloc] initWithPostVars:postVars];
//	
//	// create the connection with the request and start loading the data
//	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:[saveRequest request]
//																   delegate:self];
//	
//	if ( theConnection )
//	{
//		receivedData=[NSMutableData data];		
//	}
//	else
//	{
//		// inform the user that the download could not be made
//	}
	
//}


#pragma mark NSURLConnection delegate methods


- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	//NSLog(@"%d bytesWritten, %d totalBytesWritten, %d totalBytesExpectedToWrite", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite );
	
	[activityDelegate updateBytesWritten:totalBytesWritten
			   totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	//NSLog(@"didReceiveResponse: %@", response);
	
	NSHTTPURLResponse *httpResponse = nil;
	if ( [response isKindOfClass:[NSHTTPURLResponse class]] &&
		( httpResponse = (NSHTTPURLResponse*)response ) )
	{
		BOOL success = NO;
		NSString *title   = nil;
		NSString *message = nil;
		switch ( [httpResponse statusCode] )
		{
			case 200:
			case 201:
				success = YES;
				title	= kSuccessTitle;
				message = kSaveSuccess;
				break;
			case 202:
				success = YES;
				title	= kSuccessTitle;
				message = kSaveAccepted;
				break;
			case 500:
			default:
				title = @"Internal Server Error";
				message = [NSString stringWithFormat:@"%ld", (long)[httpResponse statusCode]];
				//message = kServerError;
		}
		
		NSLog(@"%@: %@", title, message);
		
		// update trip.uploaded 
		if ( success )
		{
			[trip setUploaded:[NSDate date]];
			
			NSError *error;
			if (![managedObjectContext save:&error]) {
				// Handle the error.
				NSLog(@"TripManager setUploaded error %@, %@", error, [error localizedDescription]);
			}
		}
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
		
		//[LIU]Remove the uploading alert message   ====alertDelegate
		[saving performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:[NSNumber numberWithInt:0] afterDelay:1];
		
		[alert show];
		


		[activityDelegate dismissSaving];
		[activityDelegate stopAnimating];

		//SavedTripsViewController *valueView = [[SavedTripsViewController alloc] initWithNibName:@"SavedTripsViewController"bundle:[NSBundle mainBundle]];
		//[[self navigationController] pushViewController:valueView animated:YES];
		//SavedTripsViewController *valueView = [[SavedTripsViewController alloc] init];
		//[[self navigationController] pushViewController:valueView animated:YES];
		// select [LIU] trips tab at launch
		//tabBarController.selectedIndex = 2;
		//[self.tabBarController setSelectedIndex:1];
		
		//UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"显示的标题" message:@"标题的提示信息" //preferredStyle:UIAlertControllerStyleAlert];
		//[self presentViewController:alertController animated:YES completion:nil];
		
//		
//		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Title" message:@"message" preferredStyle:UIAlertControllerStyleAlert];
//		//...
//		id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
//		if([rootViewController isKindOfClass:[UINavigationController class]])
//		{
//			rootViewController = ((UINavigationController *)rootViewController).viewControllers.firstObject;
//		}
//		if([rootViewController isKindOfClass:[UITabBarController class]])
//		{
//			rootViewController = ((UITabBarController *)rootViewController).selectedViewController;
//		}
//		[rootViewController presentViewController:alertController animated:YES completion:nil];
//		
//		UIAlertController * alert=   [UIAlertController
//									  alertControllerWithTitle:title
//									  message:message
//									  preferredStyle:UIAlertControllerStyleAlert];
//		
//		UIAlertAction* ok = [UIAlertAction
//							 actionWithTitle:@"OK"
//							 style:UIAlertActionStyleDefault
//							 handler:^(UIAlertAction * action)
//							 {
//								 //put your navigation code here
//								 // *** THIS IS WHERE YOU NAVIGATE TO LOGIN
//								 //[self presentViewController:alert animated:YES completion:nil];
//								 SavedTripsViewController *valueView = [[SavedTripsViewController alloc] initWithNibName:@"SavedTripsViewController"bundle:[NSBundle mainBundle]];
//								 [[self navigationController] pushViewController:valueView animated:YES];
//							 }];
//		
//		
//		UIAlertAction* cancel = [UIAlertAction
//								 actionWithTitle:@"Cancel"
//								 style:UIAlertActionStyleDefault
//								 handler:^(UIAlertAction * action)
//								 {
//									 //Put code for cancel here
//									 
//								 }];
//		
//		[alert addAction:ok];
//		[alert addAction:cancel];
	}
	
    // it can be called multiple times, for example in the case of a
	// redirect, so each time we reset the data.
	
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == [alertView cancelButtonIndex]){
		UITabBarController *tab=self.navigationController.tabBarController;
		
		if (tab){
   NSLog(@"I have a tab bar");
   [self.tabBarController setSelectedIndex:1];
		}
		else{
   NSLog(@"I don't have");
		}
		//super.tabBarController.selectedIndex = 2;
	}else{
		NSLog(@"test  click");
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
	[receivedData appendData:data];	
	[activityDelegate startAnimating];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object	
	
    // receivedData is declared as a method instance elsewhere
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	
	[activityDelegate dismissSaving];
	[activityDelegate stopAnimating];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kConnectionError
													message:[error localizedDescription]
												   delegate:alertDelegate
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// do something with the data
   // NSLog(@"Connection did finish! Received %lu bytes of data", (unsigned long)[receivedData length]);
	//NSLog(@"%@", [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] );

	[activityDelegate dismissSaving];
	[activityDelegate stopAnimating];

    // release the connection, and the data object
}


- (NSInteger)getPurposeIndex
{
	//NSLog(@"%d", purposeIndex);
	return purposeIndex;
}


#pragma mark TripPurposeDelegate methods


- (NSString *)getPurposeString:(unsigned int)index
{
	//[LIU]return [TripPurpose getPurposeString:index];
	return [TripPurpose getPurposeString:index];
}


- (NSString *)setPurpose:(unsigned int)index
{
	NSString *purpose = [self getPurposeString:index];
	NSLog(@"setPurpose: %@", purpose);
	purposeIndex = index;
	
	if ( trip )
	{
		[trip setPurpose:purpose];
		
		NSError *error;
		if (![managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"setPurpose error %@, %@", error, [error localizedDescription]);
		}
	}
	else
		//[self createTrip:index];

	dirty = YES;
	return purpose;
}

- (void)promptForTripNotes
{
	tripNotes = [[UIAlertView alloc] initWithTitle:kTripNotesTitle
										   message:@"\n\n\n"
										  delegate:self
								 cancelButtonTitle:@"Skip"
								 otherButtonTitles:@"OK", nil];

	[self createTripNotesText];
	[tripNotes addSubview:tripNotesText];
	[tripNotes show];
}


#pragma mark UIAlertViewDelegate methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// determine if we're processing tripNotes or saving alert
	if ( alertView == tripNotes )
	{
		//NSLog(@"tripNotes didDismissWithButtonIndex%ld%d"(long), buttonIndex);
		
		// save trip notes
		if ( buttonIndex == 1 )
		{
			if ( [tripNotesText.text compare:kTripNotesPlaceholder] != NSOrderedSame )
			{
				NSLog(@"saving trip notes: %@", tripNotesText.text);
				[self saveNotes:tripNotesText.text];
			}
		}
		
		// present UIAlertView "Saving..."
		saving = [[UIAlertView alloc] initWithTitle:kSavingTitle
											message:kConnecting
										   delegate:nil
								  cancelButtonTitle:nil
								  otherButtonTitles:nil];
		
		NSLog(@"created saving dialog: %@", saving);
		
		[self createActivityIndicator];
		[activityIndicator startAnimating];
		[saving addSubview:activityIndicator];
		[saving show];
		
		// save / upload trip
		
		//[LIU]
		//[self saveTrip];
	}
}


#pragma mark ActivityIndicatorDelegate methods


- (void)dismissSaving
{
	if ( saving )
		[saving dismissWithClickedButtonIndex:0 animated:YES];
}


- (void)startAnimating {
	[activityIndicator startAnimating];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)stopAnimating {
	//[activityIndicator stopAnimating];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)updateBytesWritten:(NSInteger)totalBytesWritten
 totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	if ( saving )
		saving.message = [NSString stringWithFormat:@"Sent %ld of %ld bytes", (long)totalBytesWritten, (long)totalBytesExpectedToWrite];
}


- (void)updateSavingMessage:(NSString *)message
{
	if ( saving )
		saving.message = message;
}


#pragma mark methods to allow continuing a previously interrupted recording

// filter and sort all trip coords before calculating distance in post-processing
- (CLLocationDistance)calculateTripDistance:(Trip*)_trip
{
	NSLog(@"calculateTripDistance for trip started %@ having %lu coords", _trip.startTime, (unsigned long)[_trip.coords count]);
	
	CLLocationDistance newDist = 0.;

	if ( _trip != trip )
		[self loadTrip:_trip];
	
	// filter coords by hAccuracy
	NSPredicate *filterByAccuracy	= [NSPredicate predicateWithFormat:@"hAccuracy < 100.0"];
	NSArray		*filteredCoords		= [[_trip.coords allObjects] filteredArrayUsingPredicate:filterByAccuracy];
	//NSLog(@"count of filtered coords = %d", [filteredCoords count]);
	
	if ( [filteredCoords count] )
	{
		// sort filtered coords by recorded date
		NSSortDescriptor *sortByDate	= [[NSSortDescriptor alloc] initWithKey:@"recorded" ascending:YES];
		NSArray		*sortDescriptors	= [NSArray arrayWithObjects:sortByDate, nil];
		NSArray		*sortedCoords		= [filteredCoords sortedArrayUsingDescriptors:sortDescriptors];
		
		// step through each pair of neighboring coors and tally running distance estimate
		
		// NOTE: assumes ascending sort order by coord.recorded
		// TODO: rewrite to work with DESC order to avoid re-sorting to recalc
		for (int i=1; i < [sortedCoords count]; i++)
		{
			CoordLocal *prev	 = [sortedCoords objectAtIndex:(i - 1)];
			CoordLocal *next	 = [sortedCoords objectAtIndex:i];
			newDist	+= [self distanceFrom:prev to:next realTime:NO];
		}
	}
	
	NSLog(@"oldDist: %f => newDist: %f", distance, newDist);	
	return newDist;
}


@end


@implementation TripPurpose

+ (unsigned int)getPurposeIndex:(NSString*)string
{
	
	 /*
	  #define kTripPurposeHome				0
	  #define kTripPurposeWork				1
	  #define kTripPurposeWorkRelated		2
	  #define kTripPurposeRecreation		3
	  #define kTripPurposeShopping			4
	  #define kTripPurposeSocial			5
	  #define kTripPurposeMeal				6
	  #define kTripPurposeSchool			7
	  #define kTripPurposeCollege			8
	  #define kTripPurposePersonalBiz		9
	  #define kTripPurposeEntertainment		10
	  #define kTripPurposePickUp			11
	  #define kTripPurposeOther				12
	  */
	
	if ( [string isEqualToString:kTripPurposeHomeString] )
		return kTripPurposeHome;
	else if ( [string isEqualToString:kTripPurposeWorkString] )
		return kTripPurposeWork;
	else if ( [string isEqualToString:kTripPurposeRecreationString] )
		return kTripPurposeRecreation;
	else if ( [string isEqualToString:kTripPurposeShoppingString] )
		return kTripPurposeShopping;
	else if ( [string isEqualToString:kTripPurposeSocialString] )
		return kTripPurposeSocial;
	else if ( [string isEqualToString:kTripPurposeMealString] )
		return kTripPurposeMeal;
	else if ( [string isEqualToString:kTripPurposeSchoolString] )
		return kTripPurposeSchool;
	else if ( [string isEqualToString:kTripPurposeCollegeString] )
		return kTripPurposeCollege;
	else if ( [string isEqualToString:kTripPurposePersonalBizString] )
		return kTripPurposePersonalBiz;
	else if ( [string isEqualToString:kTripPurposeEntertainmentString] )
		return kTripPurposeEntertainment;
	else if ( [string isEqualToString:kTripPurposePickUpString] )
		return kTripPurposePickUp;
	//	else if ( [string isEqualToString:kTripPurposeOtherString] )
	else
		return kTripPurposeOther;
}

+ (NSString *)getPurposeString:(unsigned int)index
{
	switch (index) {
			//[LIU] wondering if this original function works, when input a number to expect return string
		case kTripPurposeHome:
			return kTripPurposeHomeString;
			break;
		case kTripPurposeWork:
			return kTripPurposeWorkString;
			break;
		case kTripPurposeRecreation:
			return kTripPurposeRecreationString;
			break;
		case kTripPurposeShopping:
			return kTripPurposeShoppingString;
			break;
		case kTripPurposeSocial:
			return kTripPurposeSocialString;
			break;
		case kTripPurposeMeal:
			return kTripPurposeMealString;
			break;
		case kTripPurposeSchool:
			return kTripPurposeSchoolString;
			break;
		case kTripPurposeCollege:
			return kTripPurposeCollegeString;
			break;
		case kTripPurposePersonalBiz:
			return kTripPurposePersonalBizString;
			break;
		case kTripPurposeEntertainment:
			return kTripPurposeEntertainmentString;
			break;
		case kTripPurposePickUp:
			return kTripPurposePickUpString;
			break;
		case kTripPurposeOther:
		default:
			return kTripPurposeOtherString;
			break;
	}
}

@end

