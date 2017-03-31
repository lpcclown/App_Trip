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
//  RecordTripViewController.m
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 8/10/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>


#import "constants.h"
#import "MapViewController.h"
#import "PersonalInfoViewController.h"
#import "TripQuestionsViewController.h"
#import "RecordTripViewController.h"
#import "ReminderManager.h"
#import "TripManager.h"
#import "Trip.h"
#import "User.h"
#import "OneTimeQuestionsViewController.h"
#import "MapCoord.h"
#import "Coord.h"
#import "LoadingView.h"
#import "MapCoord.h"
#import "MapViewController.h"
#import "Trip.h"
#import "Annotation.h"
#import "FloridaTripTrackerAppDelegate.h"
#import "CoordLocal.h"
#import "ServerInteract.h"

#define kBatteryLevelThreshold	0.020//2% battery level

#define kResumeInterruptedRecording 101
#define kBatteryLowStopRecording    201
#define kBatteryLowNotRecording     202

@implementation RecordTripViewController

@synthesize locationManager, tripManager, reminderManager;
@synthesize startButton, cancelButton;
@synthesize timer, timeCounter, distCounter;
@synthesize recording, shouldUpdateCounter, userInfoSaved;


#pragma mark CLLocationManagerDelegate methods


- (CLLocationManager *)getLocationManager {
	
    if (locationManager != nil) {
        return locationManager;
    }
	
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"CLLocationManager locationServicesEnabled == false!!");
        //handle this?
    }
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    locationManager.delegate = self;
	//[LIU0327]add filter for 1 meter.
	[self.locationManager setDistanceFilter:1.0];
	
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
		[locationManager requestAlwaysAuthorization];
	}
	
	if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
		[self.locationManager setAllowsBackgroundLocationUpdates:YES];
	}
	
	locationManager.pausesLocationUpdatesAutomatically = NO;
	
	//[self.locationManager allowDeferredLocationUpdatesUntilTraveled:0 timeout:0];
    return locationManager;
}

//-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
//{
//		//[self.locationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:CLTimeIntervalMax];
//	[self.locationManager allowDeferredLocationUpdatesUntilTraveled:0 timeout:0];
//}

/**
 * Returns True if the battery level is too low
 */
- (BOOL)batteryLevelLowStartPressed:(BOOL)startPressed {
	
    // check battery level
    UIDevice *device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = YES;
    switch (device.batteryState)
    {
        case UIDeviceBatteryStateUnknown:
            //NSLog(@"battery state = UIDeviceBatteryStateUnknown");
            break;
        case UIDeviceBatteryStateUnplugged:
            //NSLog(@"d = UIDeviceBatteryStateUnplugged");
            break;
        case UIDeviceBatteryStateCharging:
            //NSLog(@"battery state = UIDeviceBatteryStateCharging");
            break;
        case UIDeviceBatteryStateFull:
            //NSLog(@"battery state = UIDeviceBatteryStateFull");
            break;
    }
		
    //NSLog(@"battery level = %f%%", device.batteryLevel * 100.0 );
    if ( (device.batteryState == UIDeviceBatteryStateUnknown) ||
         (device.batteryLevel >= kBatteryLevelThreshold) )
    {
        return FALSE;
    }
    
    int alert_tag = kBatteryLowNotRecording;
    if (recording) {
        alert_tag = kBatteryLowStopRecording;
        
        // stop recording cleanly
        [self doneRecordingDidCancel:FALSE];
    }

    // make sure we halt location updates
	//[LIU0314]
    //[[self getLocationManager] stopUpdatingLocation];
    
    // if this is happening not in response to a GUI event,
    // only notify if we didn't just notify -- no need to be annoying and sometimes it takes a while
    // for the location manager to stop
    if (startPressed || ([[NSDate date] timeIntervalSince1970] - lastBatteryWarning > 120)) {
        
        // notify user -- alert if foreground, otherwise send a notification
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kBatteryTitle
                                                            message:kBatteryMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            alert.tag = alert_tag;
            [alert show];
        }
        else {
            UILocalNotification *localNotif = [[UILocalNotification alloc] init];
            localNotif.alertBody = kBatteryMessage;
            //localNotif.soundName = @"bicycle-bell-normalized.aiff";
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
        }
        
        lastBatteryWarning = [[NSDate date] timeIntervalSince1970];
    }
    // battery was low - return TRUE
	// [LIU0314] Disable this check function, alway return FALSE
    //return TRUE;
	return FALSE;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	//NSLog(@"location update: %@", [newLocation description]);
	CLLocationDistance deltaDistance = [newLocation distanceFromLocation:oldLocation];
	//NSLog(@"deltaDistance = %f", deltaDistance);
	
	if ( !didUpdateUserLocation )
	{
		NSLog(@"zooming to current user location");
		//MKCoordinateRegion region = { mapView.userLocation.location.coordinate, { 0.0078, 0.0068 } };
		MKCoordinateRegion region = { newLocation.coordinate, { 0.0058, 0.0048 } };
		[mapView setRegion:region animated:YES];

		didUpdateUserLocation = YES;
	}
	
	// only update map if deltaDistance is at least some epsilon 
	else if ( deltaDistance > 1.0 )
	{
		//NSLog(@"center map to current user location");
		[mapView setCenterCoordinate:newLocation.coordinate animated:YES];
	}

	if ( recording )
	{
		// add to CoreData store
		// [LIU]
		CLLocationDistance distance = [tripManager addCoord:newLocation];
		//self.distCounter.text = [NSString stringWithFormat:@"%.1f mi", distance];
		self.distCounter.text = [NSString stringWithFormat:@"%.1f mi", distance / 1609.344];
		
		NSMutableArray * locations = [[NSMutableArray alloc]init];
		CLLocationCoordinate2D location;
		// [LIU] Track the location as annotations on the map.
		Annotation * myAnn;
		location.latitude = newLocation.coordinate.latitude;
		location.longitude = newLocation.coordinate.longitude;
		myAnn = [[Annotation alloc] init];
		myAnn.coordinate = location;
		[locations addObject:myAnn];
		[mapView addAnnotations:locations];
		
		
	} else {
        // save the location for when we do start
        lastLocation = newLocation;
		// remove track from map when the app is not recording
		for (id <MKAnnotation>  myAnnot in [mapView annotations])
		{
			if (![myAnnot isKindOfClass:[MKUserLocation class]])
			{
				[mapView removeAnnotation:myAnnot];
			}
		}
	}
	
	// 	double mph = ( [trip.distance doubleValue] / 1609.344 ) / ( [trip.duration doubleValue] / 3600. );
	if ( newLocation.speed >= 0. )
		speedCounter.text = [NSString stringWithFormat:@"%.1f mph", newLocation.speed * 3600 / 1609.344];
	else
		speedCounter.text = @"0.0 mph";
    
    // check the battery level and stop recording if low
    [self batteryLevelLowStartPressed:FALSE];
}



//[LIU] customize the pin annotation's icon.
#pragma mark -
#pragma mark MKMapView delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapview viewForAnnotation:(id <MKAnnotation>)annotation
{
	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
	static NSString* AnnotationIdentifier = @"location";
	MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
	if(annotationView)
		return annotationView;
	else
	{
		MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
		annotationView.canShowCallout = YES;
		annotationView.image = [UIImage imageNamed:@"MapCoord.png"];
		UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[rightButton addTarget:self action:@selector(writeSomething:) forControlEvents:UIControlEventTouchUpInside];
		[rightButton setTitle:annotation.title forState:UIControlStateNormal];
		annotationView.rightCalloutAccessoryView = rightButton;
		annotationView.canShowCallout = YES;
		annotationView.draggable = YES;
		return annotationView;
	}
	return nil;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
	NSLog(@"locationManager didFailWithError: %@", error );
}


#pragma mark MKMapViewDelegate methods

/*
- (void)mapViewDidFinishLoadingMap:(MKMapView *)theMapView
{
	NSLog(@"mapViewDidFinishLoadingMap");
	if ( didUpdateUserLocation )
	{
		MKCoordinateRegion region = { theMapView.userLocation.location.coordinate, { 0.0078, 0.0068 } };
		[theMapView setRegion:region animated:YES];
	}
}


- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated:(BOOL)animated
{
	NSLog(@"mapView changed region");
	if ( didUpdateUserLocation )
	{
		MKCoordinateRegion region = { theMapView.userLocation.location.coordinate, { 0.0078, 0.0068 } };
		[theMapView setRegion:region animated:YES];
	}
}
*/

- (void)initTripManager:(TripManager*)manager
{
	//manager.activityDelegate = self;
	manager.alertDelegate	= self;
	manager.dirty			= YES;
	self.tripManager		= manager;
}

- (BOOL)hasUserInfoBeenSaved
{
	BOOL					response = NO;
	NSManagedObjectContext	*context = tripManager.managedObjectContext;
	NSFetchRequest			*request = [[NSFetchRequest alloc] init];
	NSEntityDescription		*entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
	[request setEntity:entity];
	
	NSError *error;
	NSInteger count = [context countForFetchRequest:request error:&error];
	//NSLog(@"saved user count  = %d", count);
	if ( count )
	{	
		NSArray *fetchResults = [context executeFetchRequest:request error:&error];
		if ( fetchResults != nil )
		{
			User *user = (User*)[fetchResults objectAtIndex:0];
			if (user			!= nil &&
				(user.age		!= nil ||
				 user.gender	!= nil/* ||
				 user.email		!= nil ||
				 user.homeZIP	!= nil ||
				 user.workZIP	!= nil ||
				 user.schoolZIP	!= nil ||
				 ([user.cyclingFreq intValue] < 4 )*/))
			{
				NSLog(@"found saved user info");
				self.userInfoSaved = YES;
				response = YES;
			}
			else
				NSLog(@"no saved user info");
		}
		else
		{
			// Handle the error.
			NSLog(@"no saved user");
			if ( error != nil )
				NSLog(@"PersonalInfo viewDidLoad fetch error %@, %@", error, [error localizedDescription]);
		}
	}
	else
		NSLog(@"no saved user");
	
	return response;
}

- (void)infoAction:(id)sender
{
	if ( !recording )
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: kInfoURL]];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	

		[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
		self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;

		[startButton setBackgroundImage:[[UIImage imageNamed:@"start_button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(48,20,48,20) resizingMode: UIImageResizingModeStretch] forState:UIControlStateNormal];
	//[LIU]no need cancel button anymore, dummy coords will be filtered out by server's model
	//[cancelButton setBackgroundImage:[[UIImage imageNamed:@"cancel_button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(48,20,48,20) resizingMode: UIImageResizingModeStretch] forState:UIControlStateNormal];
		
		// init map region to San Francisco
		MKCoordinateRegion region = { { 37.7620, -122.4350 }, { 0.10825, 0.10825 } };
		[mapView setRegion:region animated:NO];
		
		self.recording = NO;
		self.shouldUpdateCounter = NO;
		
		// Start the location manager.
	
		// [LIU0314]
		[locationManager setDelegate:self];
		[[self getLocationManager] startUpdatingLocation];
		
		// Start receiving updates as to battery level
		UIDevice *device = [UIDevice currentDevice];
		device.batteryMonitoringEnabled = YES;
		switch (device.batteryState)
		{
			case UIDeviceBatteryStateUnknown:
				//NSLog(@"battery state = UIDeviceBatteryStateUnknown");
				break;
			case UIDeviceBatteryStateUnplugged:
				//NSLog(@"battery state = UIDeviceBatteryStateUnplugged");
				break;
			case UIDeviceBatteryStateCharging:
				//NSLog(@"battery state = UIDeviceBatteryStateCharging");
				break;
			case UIDeviceBatteryStateFull:
				//NSLog(@"battery state = UIDeviceBatteryStateFull");
				break;
		}

		//NSLog(@"battery level = %f%%", device.batteryLevel * 100.0 );

		// check if any user data has already been saved and pre-select personal info cell accordingly
		if ( [self hasUserInfoBeenSaved] )
			[self setSaved:YES];
}


- (void)resetTimer
{	
	// invalidate timer
	if ( timer )
	{
		[timer invalidate];
		//[timer release];
		timer = nil;
	}
}


- (void)resetRecordingInProgress
{
	// reset button states
	recording = NO;
	startButton.enabled = YES;
	
	// reset trip, reminder managers
	NSManagedObjectContext *context = tripManager.managedObjectContext;
	[self initTripManager:[[TripManager alloc] initWithManagedObjectContext:context]];
	tripManager.dirty = YES;
	
	if ( reminderManager )
	{
		reminderManager = nil;
	}
	
	[self resetCounter];
	[self resetTimer];
}

#pragma mark UIAlertViewDelegate methods


/**
 * This method is called upon closing the following alert boxes.
 * - battery low
 * - do you want to continue a previous, interrupted recording? (tag=kResumeInterruptedRecording)
 * - upload attempt is complete (TripManager connection:didReceiveResponse:)
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kResumeInterruptedRecording) {
        //NSLog(@"recording interrupted didDismissWithButtonIndex: %d", buttonIndex);
        if (buttonIndex == 0) {
            // new trip => do nothing
        }
        else {
					
            // update UI to reflect trip once loading has completed
            [self setCounterTimeSince:tripManager.trip.startTime distance:[tripManager getDistanceEstimate]];

            startButton.enabled = YES;
        }
        return;
    }
    
    // go to the map view of the trip
    // not relevant if we weren't recording
    if (alertView.tag != kBatteryLowNotRecording) {
        //NSLog(@"saving didDismissWithButtonIndex: %d", buttonIndex);
			
        // keep a pointer to our trip to pass to map view below
        Trip *trip = tripManager.trip;
        [self resetRecordingInProgress];
			
        // load map view of saved trip
		//[LIU0313]
		//MapViewController *mvc = [[MapViewController alloc] initWithTrip:trip];
        //[[self navigationController] pushViewController:mvc animated:YES];
	}
}

+ (NSArray *) obtainTripsArray:(NSInteger*) sendFlag{
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.predicate = [NSPredicate predicateWithFormat:@"sendFlag == %@", @0];
	FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *managedContext = [delegate managedObjectContext];
	
	//[LIU] Obtain coords info
	NSEntityDescription *coordLocal = [NSEntityDescription entityForName:@"CoordLocal" inManagedObjectContext:managedContext];
	[request setEntity:coordLocal];
	NSInteger count = [managedContext countForFetchRequest:request error:nil];
	NSLog(@"Saved coords count and going to send:  = %ld", count);
	NSArray *coordInCoordLocal = [managedContext executeFetchRequest:request error:nil];
	
	//[LIU] Obtain user's device number in user table
	NSEntityDescription *user = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedContext];
	request.predicate = nil;
	[request setEntity:user];
	NSArray *userInUserTable = [managedContext executeFetchRequest:request error:nil];
	User *person= [userInUserTable objectAtIndex:0];
	NSString *deviceNum =person.deviceNum;
	NSString *userID = person.userid;
	
	NSLog(@"Device number for sending coords: %@", deviceNum);
	
	NSDictionary *coordJson = nil;
	NSMutableArray *coordsArray = [NSMutableArray array];
	
	//[LIU] Used to convert date format to string format to put in json
	
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"MM/dd/yyyy HH:mm:ss aaa"];
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[dateFormat setLocale:locale];
	
	for(CoordLocal *coordLocal in coordInCoordLocal){
		
		NSString *recorded = [dateFormat stringFromDate: coordLocal.recorded];
		coordJson = [NSDictionary dictionaryWithObjectsAndKeys:recorded ,@"recorded",coordLocal.latitude,@"lat",coordLocal.longitude,@"lon",coordLocal.altitude,@"alt",coordLocal.speed,@"speed",coordLocal.hAccuracy,@"hAccuracy",coordLocal.vAccuracy,@"vAccuracy",deviceNum,@"device_id", userID, @"user_id", nil];
		[coordsArray addObject:coordJson];
	}

	return coordsArray;
}

//[LIU] Handle finish button action
- (IBAction)save:(UIButton *)sender
{
	[self.tabBarController setSelectedIndex:1];
	//[LIU] call service "updateCoorFull" to upload latest data to server to let server's model generate trips
	// Steps:
	// 1. obtains all coords from local table;
	// 2. post to server;
	// 3. obtain feedback;
	// 4. empty local tabel
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *managedContext = [delegate managedObjectContext];
	
	//[LIU] Obtain coords info
	NSEntityDescription *coordLocal = [NSEntityDescription entityForName:@"CoordLocal" inManagedObjectContext:managedContext];
	[request setEntity:coordLocal];
	NSInteger count = [managedContext countForFetchRequest:request error:nil];
	NSLog(@"Total trips amount to be deleted  = %ld", count);
	NSArray *coordInCoordLocal = [managedContext executeFetchRequest:request error:nil];
	
	NSArray *coordsArray = [RecordTripViewController obtainTripsArray:0];
	
	//[LIU] send array directly
	NSData *responseData = [ServerInteract sendRequest:coordsArray toURLAddress:KFinishRecording];
	if(responseData != nil){
		
		NSInteger tripsCount = [self requestFinishedTrips:responseData];
		
		NSArray *serverFeedback = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
		//NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation"
														message:[NSString stringWithFormat:@"%ld trips generated from server model.", (long)tripsCount]
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		
		
		//[LIU] According to server's feedback to decide if empty table
		if (serverFeedback.count != 0) {
			
			for(CoordLocal *coordLocal in coordInCoordLocal){
				[managedContext deleteObject:coordLocal];
			}
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation"
															message:[NSString stringWithFormat:@"%ld coordinates information loaded to server.", (long)count]
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			//[LIU0329]
			//[alert show];
		}else{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation"
															message:[NSString stringWithFormat:@"Coordinates information failed to load to server. Please try again later."]
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			//[LIU0327]
			[alert show];
			
		}
		


	}else{
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation"
														message:[NSString stringWithFormat:@"Internet is not available, Coordinates information failed to load to server."]
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		
	}
	
	//[LIU] Clear the time recording, need to check detail any impact
	[self resetTimer];
	[self resetCounter];
	self.recording = NO;
}

//[LIU0326] Request finished trip after click finish button
- (NSInteger) requestFinishedTrips:(NSData *)responseData{
	
	NSInteger *countNewTrips = 0;
	NSDictionary *readableJsonText = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
	//NSLog(@"Received Readable Json%@", readableJsonText);
	NSError *errorJson=nil;
	//NSInteger *countNewTrips = 0;
	if (readableJsonText != nil){
		NSArray *tripArray = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&errorJson];
		
		
		countNewTrips = tripArray.count;
		
		//[LIU] Iterate trips in the feedback info
		NSEnumerator *e = [tripArray objectEnumerator];
		id object;
		while (object = [e nextObject]) {
			//[LIU] Create new managed objects for coord and trip
			NSDictionary *singleTripInfo = object;
			NSString *messageFeedback = [singleTripInfo objectForKey:@"Message"];
			
			if (messageFeedback != Nil && (NSNull *)messageFeedback != [NSNull null] && [messageFeedback rangeOfString:@"error"].length == 0 && [messageFeedback rangeOfString:@"No"].length == 0 && [messageFeedback rangeOfString:@"least" ].length == 0){
				FloridaTripTrackerAppDelegate *appDelegate = (FloridaTripTrackerAppDelegate *)[[UIApplication sharedApplication]delegate];
				NSManagedObjectContext *context = [appDelegate managedObjectContext];
				
				NSManagedObject *newTrip = [NSEntityDescription insertNewObjectForEntityForName:@"Trip" inManagedObjectContext:context];
				NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
				[dateFormat setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
				NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
				[dateFormat setLocale:locale];
				
				
				//[LIU] TODO: in original there is no column about "member details", might to add
				[newTrip setValue:[singleTripInfo objectForKey:@"tripid"] forKey:@"sysTripID"];
				//[newTrip setValue:[singleTripInfo objectForKey:@"tripid"] forKey:@"distance"];
				//[newTrip setValue:[singleTripInfo objectForKey:@"tripid"] forKey:@"duration"];
				[newTrip setValue:[singleTripInfo objectForKey:@"purpose"] forKey:@"purpose"];
				[newTrip setValue:[dateFormat dateFromString:[singleTripInfo objectForKey:@"startTime"]] forKey:@"startTime"];
				//[LIU] Based on the new logic, all trips are loaded from server, so we can set these tow columns as system date by default.
				[newTrip setValue:[NSDate date] forKey:@"saved"];
				[newTrip setValue:[NSDate date] forKey:@"uploaded"];
				[newTrip setValue:[singleTripInfo objectForKey:@"fare"] forKey:@"fare"];
				[newTrip setValue:[singleTripInfo objectForKey:@"delays"] forKey:@"delays"];
				[newTrip setValue:[singleTripInfo objectForKey:@"members"] forKey:@"members"];
				[newTrip setValue:[singleTripInfo objectForKey:@"nonmembers"] forKey:@"nonMembers"];
				[newTrip setValue:[singleTripInfo objectForKey:@"payForParking"] forKey:@"payForParking"];
				[newTrip setValue:[singleTripInfo objectForKey:@"toll"] forKey:@"toll"];
				[newTrip setValue:[singleTripInfo objectForKey:@"payForParkingAmt"] forKey:@"payForParkingAmt"];
				[newTrip setValue:[singleTripInfo objectForKey:@"tollAmt"] forKey:@"tollAmt"];
				[newTrip setValue:[singleTripInfo objectForKey:@"travelBy"] forKey:@"travelBy"];
				[newTrip setValue:[dateFormat dateFromString:[singleTripInfo objectForKey:@"stopTime"]] forKey:@"stopTime"];
				
				NSArray *coords =[singleTripInfo objectForKey:@"coords"];
				//NSLog(@"Coords is ............................................%@",coords);
				//[LIU] Iterate coord in coords item
				NSEnumerator *e = [coords objectEnumerator];
				id object;
				while (object = [e nextObject]) {
					NSManagedObject *newCoord = [NSEntityDescription insertNewObjectForEntityForName:@"Coord" inManagedObjectContext:context];
					//NSLog(@"Coord is ............................................%@",object);
					NSDictionary *coord =object;
					NSDictionary *coordDetails = [coord objectForKey:@"coord"];
					
					[newCoord setValue:[coordDetails objectForKey:@"alt"] forKey:@"altitude"];
					[newCoord setValue:[coordDetails objectForKey:@"hac"] forKey:@"hAccuracy"];
					[newCoord setValue:[coordDetails objectForKey:@"lat"] forKey:@"latitude"];
					[newCoord setValue:[coordDetails objectForKey:@"lon"] forKey:@"longitude"];
					[newCoord setValue:[dateFormat dateFromString:[coordDetails objectForKey:@"rec"]] forKey:@"recorded"];
					[newCoord setValue:[coordDetails objectForKey:@"vac"] forKey:@"vAccuracy"];
					[newCoord setValue:[coordDetails objectForKey:@"spd"] forKey:@"speed"];
					
					[newCoord setValue:newTrip forKey:@"trip"];
					
					NSError *error = nil;
					// Save the object to persistent store
					if (![context save:&error]) {
						NSLog(@"Save trip info FAILED! %@ %@", error, [error localizedDescription]);
					}
				}
			}
			else{
				return 0;
			}
			//[LIU] DONT DELELE: below codes are used to check the records count in tables
			//			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:tripManager.managedObjectContext];
			//			//NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:managedContext1];
			//
			//			NSFetchRequest *request1 = [[NSFetchRequest alloc] init];
			//			[request1 setEntity:entity];
			//
			//			NSError *error;
			//			NSInteger count = [tripManager.managedObjectContext countForFetchRequest:request1 error:&error];
			//			NSLog(@"count trip firstly save .........records.....= %ld", count);
			//			NSEntityDescription *entity1 = [NSEntityDescription entityForName:@"Coord" inManagedObjectContext:tripManager.managedObjectContext];
			//			[request1 setEntity:entity1];
			//			count = [tripManager.managedObjectContext countForFetchRequest:request1 error:&error];
			//			NSLog(@"count coord firstly save .........records.....= %ld", count);
			
		}
	}
	
	
	return countNewTrips;
	
}

//[LIU]this cancel button can be removed
- (IBAction)cancel:(UIButton *)sender
{
    NSLog(@"Canceltest");
    [self doneRecordingDidCancel:TRUE];
}

/**
 * Call when we are done recording.
 */
- (void)doneRecordingDidCancel:(BOOL)didCancel {
	// [LIU] no need only one finish button in this view
}

// handle start button action
- (IBAction)start:(UIButton *)sender
{
	NSLog(@"start - recording=%d", recording);
    
    // just one button - we really want to save
    if (recording) {
		//[LIU0314] Disable previous running reminder
		if ( reminderManager )
			[reminderManager disableReminders];
        [self save:sender];
        return;
    }
	
    // if the battery level is low then NM
    if ([self batteryLevelLowStartPressed:TRUE])
        return;
        
	// start the timer if needed
	if ( timer == nil )
	{
        NSDictionary* counterUserDict;
		// check if we're continuing a trip - then start the trip from there
		if ( tripManager.trip && tripManager.trip.startTime && [tripManager.trip.coords count] )
		{
            counterUserDict = [NSDictionary dictionaryWithObjectsAndKeys:tripManager.trip.startTime, @"StartDate",
                                                                         tripManager, @"TripManager", nil ];
        }
        // or starting a new recording
        else {
			[self resetCounter];
            counterUserDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"StartDate",
                                                                         tripManager, @"TripManager", nil ];
        }
        timer = [NSTimer scheduledTimerWithTimeInterval:kCounterTimeInterval
                                                 target:self selector:@selector(updateCounter:)
                                                userInfo:counterUserDict
                                                repeats:YES];
	}

	// init reminder manager
	reminderManager = [[ReminderManager alloc] init];
	
    // transform start button into save button
    [startButton setTitle:@"END RECORDING" forState:UIControlStateNormal];
    [startButton setBackgroundImage:[[UIImage imageNamed:@"save_button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(48,20,48,20) resizingMode: UIImageResizingModeStretch] forState:UIControlStateNormal];
	//[LIU] adjust finish button width	
	//startButton.frame = CGRectMake( 18.0, 159.0, 386, kCustomButtonHeight );
	
	//[LIU0330] start button grey out until 18 hours.
	startButton.enabled = NO;
	
	
    // Start the location manager.
	// [LIU0314]
	[locationManager setDelegate:self];
	
	[[self getLocationManager] startUpdatingLocation];

    // set recording flag so future location updates will be added as coords
	recording = YES;
	
    // add the last location we know about to start
    if (lastLocation) {
        NSLog(@"tripManager = %@", tripManager);
        CLLocationDistance distance = [tripManager addCoord:lastLocation];
        self.distCounter.text = [NSString stringWithFormat:@"%.1f mi", distance / 1609.344];
        lastLocation = nil;
    }
	
	// set flag to update counter
	shouldUpdateCounter = YES;
}


- (void)resetCounter
{
	if ( timeCounter != nil )
		timeCounter.text = @"00:00:00";
	
	if ( distCounter != nil )
		distCounter.text = @"0 mi";
}


- (void)setCounterTimeSince:(NSDate *)startDate distance:(CLLocationDistance)distance
{
	if ( timeCounter != nil )
	{
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];
		
		static NSDateFormatter *inputFormatter = nil;
		if ( inputFormatter == nil )
			inputFormatter = [[NSDateFormatter alloc] init];
		
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *fauxDate = [inputFormatter dateFromString:@"00:00:00"];
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *outputDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:fauxDate];
		
		timeCounter.text = [inputFormatter stringFromDate:outputDate];
	}
	
	if ( distCounter != nil )
		distCounter.text = [NSString stringWithFormat:@"%.1f mi", distance / 1609.344];
}


// Updates the elapsed-time counter in the GUI.
- (void)updateCounter:(NSTimer *)theTimer
{
	// NSLog(@"updateCounter");
	if ( shouldUpdateCounter )
	{
		NSDate *startDate = [[theTimer userInfo] objectForKey:@"StartDate"];
		NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:startDate];

		static NSDateFormatter *inputFormatter = nil;
		if ( inputFormatter == nil )
			inputFormatter = [[NSDateFormatter alloc] init];
		
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *fauxDate = [inputFormatter dateFromString:@"00:00:00"];
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *outputDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:fauxDate];
		
		//NSLog(@"Timer started on %@", startDate);
		//NSLog(@"Timer started %f seconds ago", interval);
		//NSLog(@"elapsed time: %@", [inputFormatter stringFromDate:outputDate] );
		
		//self.timeCounter.text = [NSString stringWithFormat:@"%.1f sec", interval];
		self.timeCounter.text = [inputFormatter stringFromDate:outputDate];
	}
}

/** 
 * Handle the fact that we're going to be backgrounded
 * If we're not recording,
 * - No need to run the timer
 * - No need to get locations
 * - No need to run the reminder clock
 */
- (void)handleBackgrounding
{
    if (!recording) {
		//[LIU0314]no need to stop, keep tracking
        //[[self getLocationManager] stopUpdatingLocation];
    }
    // the timer is for visuals - no need for that but it doesn't seem to hurt
    // [self resetTimer];
	
	//[LIU0327]when service in backend change it to significant location change.
	//[[self getLocationManager] stopUpdatingLocation];
	//[[self getLocationManager] startMonitoringSignificantLocationChanges];
}

- (void)handleForegrounding
{
    NSLog(@"handleForegrounding : recording=%d", recording);
    // Start the location manager.
	// [LIU0314]
	[locationManager setDelegate:self];
	[[self getLocationManager] startUpdatingLocation];
}

- (void)handleTermination
{
    if ( reminderManager )
        [reminderManager disableReminders];
}

#pragma mark UIViewController overrides

- (void)viewWillAppear:(BOOL)animated
{
    // listen for keyboard hide/show notifications so we can properly adjust the table's height
	[super viewWillAppear:animated];
	// [LIU] Added the function to auto run the start when page load trigger from SavedTrip page
	if(recording == NO){
		[self start:startButton];
	}
	// [LIU] disable the cancel button
	cancelButton.hidden = TRUE;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FDOT"]]];
	self.navigationItem.rightBarButtonItem = item;
	
}

- (void)viewDidDisappear:(BOOL)animated 
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)aNotification 
{
	NSLog(@"keyboardWillShow");
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
	NSLog(@"keyboardWillHide");
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    //self.coords = nil;
    self.locationManager = nil;
    self.startButton = nil;
}


- (NSString *)updatePurposeWithString:(NSString *)purpose
{
	// only enable start button if we don't already have a pending trip
	if ( timer == nil )
		startButton.enabled = YES;
	
	startButton.hidden = NO;
	
	return purpose;
}


- (NSString *)updatePurposeWithIndex:(unsigned int)index
{
	return [self updatePurposeWithString:[tripManager getPurposeString:index]];
}




#pragma mark UINavigationController

- (void)navigationController:(UINavigationController *)navigationController 
	   willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated
{
    NSLog(@"navigationController willShowViewController animated");
	if ( viewController == self )
	{
		//NSLog(@"willShowViewController:self");
		self.title = @"Record New Trip";
	}
	else
	{
		//NSLog(@"willShowViewController:else");
		self.title = @"Back";
		self.tabBarItem.title = @"Record New Trip"; // important to maintain the same tab item title
	}
}

#pragma mark PersonalInfoDelegate methods


- (void)setSaved:(BOOL)value
{
	NSLog(@"setSaved");
}


#pragma mark TripPurposeDelegate methods


- (NSString *)setPurpose:(unsigned int)index
{
	NSString *purpose = [tripManager setPurpose:index];
	NSLog(@"setPurpose: %@", purpose);
	
	return [self updatePurposeWithString:purpose];
}


- (NSString *)getPurposeString:(unsigned int)index
{
	return [tripManager getPurposeString:index];
}


- (void)didCancelPurpose
{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	recording = YES;
	shouldUpdateCounter = YES;
}


- (void)didPickPurpose:(NSMutableDictionary *)tripAnswers
{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	[self doneRecordingDidCancel:FALSE];
	
	[[tripManager trip] setTravelBy:[tripAnswers objectForKey:@"travelBy"]];
	[[tripManager trip] setPurpose:[tripAnswers objectForKey:@"purpose"]];
	[[tripManager trip] setFare:[tripAnswers objectForKey:@"fare"]];
	[[tripManager trip] setDelays:[tripAnswers objectForKey:@"delays"]];
	[[tripManager trip] setMembers:[tripAnswers objectForKey:@"members"]];
	[[tripManager trip] setNonMembers:[tripAnswers objectForKey:@"nonmembers"]];
	[[tripManager trip] setPayForParking:[tripAnswers objectForKey:@"payForParking"]];
	[[tripManager trip] setToll:[tripAnswers objectForKey:@"toll"]];
	[[tripManager trip] setPayForParkingAmt:[tripAnswers objectForKey:@"payForParkingAmt"]];
	[[tripManager trip] setTollAmt:[tripAnswers objectForKey:@"tollAmt"]];
	//lx
	[[tripManager trip] setIsMembers:[tripAnswers objectForKey:@"isMembers"]];
	[[tripManager trip] setFamilyMembers:[tripAnswers objectForKey:@"familyMembers"]];
	[[tripManager trip] setIsnonMembers:[tripAnswers objectForKey:@"isnonMembers"]];
	[[tripManager trip] setDriverType:[tripAnswers objectForKey:@"driverType"]];
	//*lx
	//[LIU]
	//[tripManager saveTrip];
}


#pragma mark RecordingInProgressDelegate method


- (Trip*)getRecordingInProgress
{
	if ( recording )
		return tripManager.trip;
	else
		return nil;
}


@end

