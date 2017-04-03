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
//  MapViewController.m
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/28/09.
//	For more information on the project,
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>


#import "Coord.h"
#import "LoadingView.h"
#import "MapCoord.h"
#import "MapViewController.h"
#import "Trip.h"
#import "TripQuestionsViewController.h"
#import "TripPurposeDelegate.h"
#import "SavedTripsViewController.h"
#import "FloridaTripTrackerAppDelegate.h"
#import "constants.h"

#define kFudgeFactor	1.5
#define kInfoViewAlpha	0.8
#define kMinLatDelta	0.0039
#define kMinLonDelta	0.0034


@implementation MapViewController

@synthesize doneButton, flipButton, infoView, trip;
@synthesize viewTrips,addDetailInfo,removeTrip;//lx 0401


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

- (id)initWithTrip:(Trip *)_trip
{
	//if (self = [super init]) {
	if (self = [super initWithNibName:@"MapViewController" bundle:nil]) {
		NSLog(@"MapViewController initWithTrip");
		self.trip = _trip;
		mapView.delegate = self;
	}
	return self;
}
//[LIU] new added button for link to detailed info
- (IBAction)addDetailInfo:(id)sender {
	//TripQuestionsViewController *pickerViewController = [[TripQuestionsViewController alloc]
	//												 initWithNibName:@"TripPurposePicker" bundle:nil];
	TripQuestionsViewController *pickerViewController = [[TripQuestionsViewController alloc] initWithTrip:self.trip];
	SavedTripsViewController *savedTripsViewController = [[SavedTripsViewController alloc]init];
	TripManager *manager = [[TripManager alloc] init];
	[savedTripsViewController initTripManager:manager];
	[pickerViewController setDelegate:savedTripsViewController];
	[self.navigationController presentViewController:pickerViewController animated:YES completion:nil];
	
	
	
	/*TripQuestionsViewController *pickerViewController = [[TripQuestionsViewController alloc]
	 initWithNibName:@"TripPurposePicker" bundle:nil];
	 [pickerViewController setDelegate:self];
	 
	 [self.navigationController presentViewController:pickerViewController animated:YES completion:nil];*/
}
//[LIU]
- (NSString *)updatePurposeWithString:(NSString *)purpose
{
	// update UI
	/*
	 if ( tripPurposeCell != nil )
	 {
	 tripPurposeCell.accessoryType = UITableViewCellAccessoryCheckmark;
	 tripPurposeCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GreenCheckMark3.png"]];
	 tripPurposeCell.detailTextLabel.text = purpose;
	 tripPurposeCell.detailTextLabel.enabled = YES;
	 tripPurposeCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
	 tripPurposeCell.detailTextLabel.minimumFontSize = kMinimumFontSize;
	 }
	 */
	
	// only enable start button if we don't already have a pending trip
	
	return purpose;
}

- (void)initTripManager:(TripManager*)manager
{
	//manager.activityDelegate = self;
	//manager.alertDelegate	= self;
	//manager.dirty			= YES;
	//self.tripManager		= manager;
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == [alertView firstOtherButtonIndex]){
		[self deleteTrip];
	}else{
		
	}
}

- (void) deleteTrip{

		NSNumber *tripID = self.trip.sysTripID;
		NSData *postData = [tripID.description dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:KRemoveTripById]];
	
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
	
		NSURLResponse *response;
		NSError *err;
	
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		NSDictionary *serverFeedback = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
		NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
	
		if ([serverFeedbackString hasSuffix:@"successfully."]) {
			FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
			NSManagedObjectContext *managedContext= [delegate managedObjectContext];
			[managedContext deleteObject:self.trip];
			// Commit the change.
			NSError *error;
			if (![managedContext save:&error]) {
				// Handle the error.
				NSLog(@"Delete Trip FAILED.................%@", [error localizedDescription]);
			}
		}
	
		[self.navigationController popViewControllerAnimated:YES];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation"
													message:@"The trip has been deleted on server and removed from local database."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];

}
//lx 0401
- (IBAction)viewtrips:(id)sender {
 
 FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
 NSManagedObjectContext *managedContext= [delegate managedObjectContext];
 [managedContext deleteObject:self.trip];
 // Commit the change.
 [self.navigationController popViewControllerAnimated:YES];
}

//[LIU]Remove trip
- (IBAction)removeTrip:(id)sender
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Trip"
													message:@"Do you confirm this is an incorrect trip generated by model?"
												   delegate:self
										  cancelButtonTitle:nil
										  otherButtonTitles:@"Yes", @"Cancel", nil];
	[alert show];
//	NSNumber *tripID = self.trip.sysTripID;
//	NSData *postData = [tripID.description dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//	NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
//	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//	[request setURL:[NSURL URLWithString:KRemoveTripById]];
//	
//	[request setHTTPMethod:@"POST"];
//	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//	[request setHTTPBody:postData];
//	
//	NSURLResponse *response;
//	NSError *err;
//	
//	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
//	NSDictionary *serverFeedback = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
//	NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
//	
//	if ([serverFeedbackString hasSuffix:@"successfully."]) {
//		FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
//		NSManagedObjectContext *managedContext= [delegate managedObjectContext];
//		[managedContext deleteObject:self.trip];
//		// Commit the change.
//		NSError *error;
//		if (![managedContext save:&error]) {
//			// Handle the error.
//			NSLog(@"Delete Trip FAILED.................%@", [error localizedDescription]);
//		}
//	}
//	
//	[self.navigationController popViewControllerAnimated:YES];
}


- (void)infoAction:(UIButton*)sender
{
	NSLog(@"infoAction");
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:animationIDfinished:finished:context:)];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.75];
	
	[UIView setAnimationTransition:([infoView superview] ?
									UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.view cache:YES];
	
	if ([infoView superview])
		[infoView removeFromSuperview];
	else
		[self.view addSubview:infoView];
	
	[UIView commitAnimations];
	
	// adjust our done/info buttons accordingly
	if ([infoView superview] == self.view)
		self.navigationItem.rightBarButtonItem = doneButton;
	else
		self.navigationItem.rightBarButtonItem = flipButton;
}


- (void)initInfoView
{
	infoView					= [[UIView alloc] initWithFrame:CGRectMake(0,0,320,460)];
	infoView.alpha				= kInfoViewAlpha;
	infoView.backgroundColor	= [UIColor blackColor];
	
	UILabel *notesHeader		= [[UILabel alloc] initWithFrame:CGRectMake(9,85,160,25)];
	notesHeader.backgroundColor = [UIColor clearColor];
	notesHeader.font			= [UIFont boldSystemFontOfSize:18.0];
	notesHeader.opaque			= NO;
	notesHeader.text			= @"Trip Notes";
	notesHeader.textColor		= [UIColor whiteColor];
	[infoView addSubview:notesHeader];
	
	UITextView *notesText		= [[UITextView alloc] initWithFrame:CGRectMake(0,110,320,200)];
	notesText.backgroundColor	= [UIColor clearColor];
	notesText.editable			= NO;
	notesText.font				= [UIFont systemFontOfSize:16.0];
	notesText.text				= @"";
	notesText.textColor			= [UIColor whiteColor];
	[infoView addSubview:notesText];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	
	UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FDOT"]]];
	self.navigationItem.rightBarButtonItem = item;
	
	if ( trip )
	{
		// format date as a string
		static NSDateFormatter *dateFormatter = nil;
		if (dateFormatter == nil) {
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
			[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		}
		
		// display duration, distance as navbar prompt
		static NSDateFormatter *inputFormatter = nil;
		if ( inputFormatter == nil )
			inputFormatter = [[NSDateFormatter alloc] init];
		
		[inputFormatter setDateFormat:@"HH:mm:ss"];
		NSDate *fauxDate = [inputFormatter dateFromString:@"00:00:00"];
		[inputFormatter setDateFormat:@"HH:mm:ss"];
	
		
		//self.title = trip.purpose;
		
		// filter coords by hAccuracy
		NSPredicate *filterByAccuracy	= [NSPredicate predicateWithFormat:@"hAccuracy < 100.0"];
		NSArray		*filteredCoords		= [[trip.coords allObjects] filteredArrayUsingPredicate:filterByAccuracy];
		
		//[LIU]how many records in the selected trip
		NSArray *coordsAmount = [trip.coords allObjects];
		int a = [coordsAmount count];
		//NSLog(@"%d...................how many coords for one trip...................", a);
		if(a>0)
		{
		// sort filtered coords by recorded date
		NSSortDescriptor *sortByDate	= [[NSSortDescriptor alloc] initWithKey:@"recorded" ascending:YES];
		NSArray		*sortDescriptors	= [NSArray arrayWithObjects:sortByDate, nil];
		NSArray		*sortedCoords		= [filteredCoords sortedArrayUsingDescriptors:sortDescriptors];
		
		// add coords as annotations to map
		BOOL first = YES;
		Coord *last = nil;
		MapCoord *pin = nil;
		int count = 0;
		
		// calculate min/max values for lat, lon
		NSNumber *minLat = [NSNumber numberWithDouble:0.0];
		NSNumber *maxLat = [NSNumber numberWithDouble:0.0];
		NSNumber *minLon = [NSNumber numberWithDouble:0.0];
		NSNumber *maxLon = [NSNumber numberWithDouble:0.0];

		// [LIU] show average speed in mapView
		Coord *firstCoord		= [sortedCoords objectAtIndex:0];
		Coord *lastCoord	= [sortedCoords lastObject];
		NSTimeInterval duration = [lastCoord.recorded timeIntervalSinceDate:firstCoord.recorded];
		NSLog(@"duration = %.0fs", duration);
		[trip setDuration:[NSNumber numberWithDouble:duration]];
		double mph = ( [trip.distance doubleValue] / 1609.344 ) / ( [trip.duration doubleValue] / 3600. );
		NSDate *outputDate = [[NSDate alloc] initWithTimeInterval:(NSTimeInterval)[trip.duration doubleValue]
														sinceDate:fauxDate];
		self.navigationItem.prompt = [NSString stringWithFormat:@"elapsed: %@ ~ %@",
									  [inputFormatter stringFromDate:outputDate],
									  [dateFormatter stringFromDate:[trip startTime]]];
		
//		self.title = [NSString stringWithFormat:@"%.1f mi ~ %.1f mph elapsed: %@ ~ %@",
//					  [trip.distance doubleValue] / 1609.344, mph, [inputFormatter stringFromDate:outputDate],
//					  [dateFormatter stringFromDate:[trip startTime]] ];
		
		self.title = [NSString stringWithFormat:@"%.1f mi ~ %.1f mph",
					  [trip.distance doubleValue] / 1609.344, mph];
		
		for ( Coord *coord in sortedCoords )
		{
			// only plot unique coordinates to our map for performance reasons
			if ( !last ||
				(![coord.latitude  isEqualToNumber:last.latitude] &&
				 ![coord.longitude isEqualToNumber:last.longitude] ) )
			{
				CLLocationCoordinate2D coordinate;
				coordinate.latitude  = [coord.latitude doubleValue];
				coordinate.longitude = [coord.longitude doubleValue];
				
				pin = [[MapCoord alloc] init];
				pin.coordinate = coordinate;
				
				if ( first )
				{
					// add start point as a pin annotation
					first = NO;
					pin.first = YES;
					pin.title = @"Start";
					pin.subtitle = [dateFormatter stringFromDate:coord.recorded];
					//[mapView selectAnnotation:pin animated:YES];
					//NSLog(@"%@ ......first recorded time......", coord);
					// initialize min/max values to the first coord
					minLat = coord.latitude;
					maxLat = coord.latitude;
					minLon = coord.longitude;
					maxLon = coord.longitude;
				}
				else
				{
					// update min/max values
					if ( [minLat compare:coord.latitude] == NSOrderedDescending )
						minLat = coord.latitude;
					
					if ( [maxLat compare:coord.latitude] == NSOrderedAscending )
						maxLat = coord.latitude;
					
					if ( [minLon compare:coord.longitude] == NSOrderedDescending )
						minLon = coord.longitude;
					
					if ( [maxLon compare:coord.longitude] == NSOrderedAscending )
						maxLon = coord.longitude;
				}
				
				[mapView addAnnotation:pin];
				count++;
			}
			
			// update last coord pointer so we can cull redundant coords above
			last = coord;
		}
		
		// add end point as a pin annotation
		if ( (last = [sortedCoords lastObject]) )
		{
			pin.last = YES;
			pin.title = @"End";
			pin.subtitle = [dateFormatter stringFromDate:last.recorded];
			//[mapView selectAnnotation:pin animated:YES];
		}
		
		// if we had at least 1 coord
		if ( count )
		{
			
			// add a small fudge factor to ensure
			// North-most pins are visible
			double latDelta = kFudgeFactor * ( [maxLat doubleValue] - [minLat doubleValue] );
			if ( latDelta < kMinLatDelta )
				latDelta = kMinLatDelta;
			
			double lonDelta = [maxLon doubleValue] - [minLon doubleValue];
			if ( lonDelta < kMinLonDelta )
				lonDelta = kMinLonDelta;
			
			MKCoordinateRegion region = { { [minLat doubleValue] + latDelta / 2,
				[minLon doubleValue] + lonDelta / 2 },
				{ latDelta,
					lonDelta } };
			[mapView setRegion:region animated:NO];
		}
		else
		{
			// init map region to San Francisco
			MKCoordinateRegion region = { { 37.7620, -122.4350 }, { 0.10825, 0.10825 } };
			[mapView setRegion:region animated:NO];
		}
	}
	}
	else
	{
		// error: init map region to San Francisco
		MKCoordinateRegion region = { { 37.7620, -122.4350 }, { 0.10825, 0.10825 } };
		[mapView setRegion:region animated:NO];
	}

	LoadingView *loading = (LoadingView*)[self.parentViewController.view viewWithTag:909];
	//NSLog(@"loading: %@", loading);
	[loading performSelector:@selector(removeView) withObject:nil afterDelay:0.5];
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}




#pragma mark MKMapViewDelegate methods


- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
	//NSLog(@"mapViewWillStartLoadingMap");
}


- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
	NSLog(@"mapViewDidFailLoadingMap:withError: %@", [error localizedDescription]);
}


- (void)mapViewDidFinishLoadingMap:(MKMapView *)_mapView
{
	//NSLog(@"mapViewDidFinishLoadingMap");
	LoadingView *loading = (LoadingView*)[self.parentViewController.view viewWithTag:909];
	//NSLog(@"loading: %@", loading);
	[loading removeView];
}


- (MKAnnotationView *)mapView:(MKMapView *)_mapView
			viewForAnnotation:(id <MKAnnotation>)annotation
{
	//NSLog(@"viewForAnnotation");
	
	// If it's the user location, just return nil.
	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
	
	// Handle any custom annotations.
	if ([annotation isKindOfClass:[MapCoord class]])
	{
		MKAnnotationView* annotationView = nil;
		
		if ( [(MapCoord*)annotation first] )
		{
			// Try to dequeue an existing pin view first.
			//MKPinAnnotationView* pinView = (MKPinAnnotationView*)[mapView
			//													  dequeueReusableAnnotationViewWithIdentifier:@"FirstCoord"];
			MKAnnotationView* pinView = (MKPinAnnotationView*)[mapView
																  dequeueReusableAnnotationViewWithIdentifier:@"FirstCoord"];
			
			if ( !pinView )
			{
				// If an existing pin view was not available, create one
				//pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"FirstCoord"];
				pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"FirstCoord"];
				//pinView.animatesDrop = YES;
				pinView.canShowCallout = YES;
				//pinView.pinColor = MKPinAnnotationColorGreen;
				pinView.image = [UIImage imageNamed:@"PinGreen.png"];
			}
			
			annotationView = pinView;
		}
		else if ( [(MapCoord*)annotation last] )
		{
			// Try to dequeue an existing pin view first.
			//MKPinAnnotationView* pinView = (MKPinAnnotationView*)[mapView
			//													  dequeueReusableAnnotationViewWithIdentifier:@"LastCoord"];
			MKAnnotationView* pinView = (MKPinAnnotationView*)[mapView
																  dequeueReusableAnnotationViewWithIdentifier:@"LastCoord"];
			if ( !pinView )
			{
				// If an existing pin view was not available, create one
				//pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"LastCoord"];
				pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"LastCoord"];
				//pinView.animatesDrop = YES;
				pinView.canShowCallout = YES;
				//pinView.pinColor = MKPinAnnotationColorRed;
				pinView.image = [UIImage imageNamed:@"PinRed.png"];
			}
			
			annotationView = pinView;
		}
		else
		{
			// Try to dequeue an existing pin view first.
			annotationView = (MKAnnotationView*)[mapView
												 dequeueReusableAnnotationViewWithIdentifier:@"MapCoord"];
			
			if (!annotationView)
			{
				// If an existing pin view was not available, create one
				annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapCoord"];
				
				annotationView.image = [UIImage imageNamed:@"MapCoord.png"];
			}
		}
		
		return annotationView;
	}
	
	return nil;
}


@end
