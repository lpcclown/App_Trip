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
//  SavedTripsViewController.m
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 8/10/09.
//	For more information on the project,
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>


#import "constants.h"
#import "Coord.h"
#import "LoadingView.h"
#import "MapViewController.h"
#import "TripQuestionsViewController.h"
#import "SavedTripsViewController.h"
#import "Trip.h"
#import "User.h"
#import "TripManager.h"
#import "TripPurposeDelegate.h"
#import "RecordTripViewController.h"
#import "FloridaTripTrackerAppDelegate.h"
#import "NSDate+Utils.h"

#define kAccessoryViewX	282.0
#define kAccessoryViewY 24.0

#define kCellReuseIdentifierCheck		@"CheckMark"
#define kCellReuseIdentifierExclamation @"Exclamataion"
#define kCellReuseIdentifierInProgress	@"InProgress"

#define kRowHeight	75
#define kTagTitle	1
#define kTagDetail	2
#define kTagImage	3


@interface TripCell : UITableViewCell
{
}

- (void)setTitle:(NSString *)title;
- (void)setDetail:(NSString *)detail;
- (void)setDirty;

@end

@implementation TripCell


- (void)setTitle:(NSString *)title
{
	self.textLabel.text = title;
	[self setNeedsDisplay];
}

- (void)setDetail:(NSString *)detail
{
	self.detailTextLabel.text = detail;
	[self setNeedsDisplay];
}

- (void)setDirty
{
	[self setNeedsDisplay];
}

@end

@implementation SavedTripsViewController

@synthesize delegate, managedObjectContext;
@synthesize trips, tripManager, selectedTrip, postVars,responseDict;
@synthesize managedContext,labelView,firstTimeLoad,countNewTrips;//lx


- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
	if (self = [super init]) {
		self.managedObjectContext = context;
		
		// Set the title NOTE: important for tab bar tab item to set title here before view loads
		self.title = @"View Saved Trips";
	}
	return self;
}

- (void)initTripManager:(TripManager*)manager
{
	self.tripManager = manager;
}

- (id)initWithTripManager:(TripManager*)manager
{
	if (self = [super init]) {
		//NSLog(@"SavedTripsViewController::initWithTripManager");
		self.tripManager = manager;
		
		// Set the title NOTE: important for tab bar tab item to set title here before view loads
		self.title = @"View Saved Trips";
	}
	return self;
}

//[LIU]
- (BOOL)connected
{
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [reachability currentReachabilityStatus];
	return networkStatus != NotReachable;
}

//[LIU]
- (NSInteger) requestDayTrips:(NSDictionary *)inPostVars{
	
	NSData *postData= [NSJSONSerialization dataWithJSONObject:inPostVars options:nil error:nil];
	NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
	//[LIU] This request is used to get day trips from server, the feedback information will be saved into two
	//tables. The table of Trip and Coord.
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:kGetTripURL]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	NSURLResponse *response;
	NSError *err;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
	
	NSString *readableJsonText = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
	NSLog(@"Received Readable Json%@", readableJsonText);
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
			FloridaTripTrackerAppDelegate *appDelegate = (FloridaTripTrackerAppDelegate *)[[UIApplication sharedApplication]delegate];
			NSManagedObjectContext *context = [appDelegate managedObjectContext];
			
			NSManagedObject *newTrip = [NSEntityDescription insertNewObjectForEntityForName:@"Trip" inManagedObjectContext:context];
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
			NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
			[dateFormat setLocale:locale];
			NSDictionary *singleTripInfo = object;
			
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

- (void)refreshTableView
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	FloridaTripTrackerAppDelegate *delegatea= [[UIApplication sharedApplication] delegate];
	managedContext = [delegatea managedObjectContext];
	
	//[LIU] Obtain coords info
	NSEntityDescription *trip = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:managedContext];
	[request setEntity:trip];
	//[LIU] Configure sort order
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"stopTime" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	NSError *error = nil;
	NSMutableArray *tripsInOriginalTripTable = [[tripManager.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	NSString *tripID = @"-1";
	NSString *latestStopTime = @"";
	if ([tripsInOriginalTripTable count] != 0){
		Trip *latestTrip = [tripsInOriginalTripTable objectAtIndex:0];
		//	NSInteger count = [managedContext countForFetchRequest:request error:nil];
		//	NSLog(@"trip count  = %ld", count);
		//[LIU] Used to convert date format to string format to put in json
		NSDateFormatter *dateFormatOnServer = [[NSDateFormatter alloc] init];
		NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		[dateFormatOnServer setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];//[LIU] to update the date format as server acceptable
		[dateFormatOnServer setLocale:locale];
		NSLog(@"latestTrip.sysTripID--------------------%@", latestTrip.sysTripID);
		if (latestTrip.stopTime != nil){
			latestStopTime = [dateFormatOnServer stringFromDate: latestTrip.stopTime];}
		tripID = [latestTrip.sysTripID stringValue];
	}
	
	
	//[LIU] Obtain user's device number in user table
	//[LIU] Previous request is sord by stopTime, so it cannot be used for User table
	NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *user = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedContext];
	[userRequest setEntity:user];
	NSArray *userInUserTable = [managedContext executeFetchRequest:userRequest error:nil];
	User *person= [userInUserTable objectAtIndex:0];
	//NSString *deviceNum =person.deviceNum;
	NSString *userID = person.userid;
	//[LIU] Get trip info from server: getDayTrip
	NSDictionary *requestDayTripsAugs = [NSDictionary dictionaryWithObjectsAndKeys:tripID,@"tripid",@"",@"startTime",latestStopTime,@"stopTime",userID,@"user", nil];
	//[LIU] The return flag is used to set the start button if show warnning info about "refreshing"
	//NSInteger countNewTrips = [self requestDayTrips:requestDayTripsAugs];
	if ([self connected]){
		[self requestDayTrips:requestDayTripsAugs];
	}
	
	//[LIU]
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:tripManager.managedObjectContext];
	[request setEntity:entity];
	[request setSortDescriptors:sortDescriptors];
	
	NSInteger countAllLocalTrip = [tripManager.managedObjectContext countForFetchRequest:request error:&error];
	NSLog(@"count trip.........records.....= %ld", countAllLocalTrip);
	
	NSMutableArray *tripsInNewTripTable = [[tripManager.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (tripsInNewTripTable == nil) {
		// Handle the error.
		NSLog(@"no saved trips");
		if ( error != nil )
			NSLog(@"Unresolved error2 %@, %@", error, [error userInfo]);
	}
	
	[self setTrips:tripsInNewTripTable];
	
	request.predicate = [NSPredicate predicateWithFormat:@"purpose == %@", @""];
	NSInteger countPendingLocalTrip = [tripManager.managedObjectContext countForFetchRequest:request error:&error];
	// [LIU] add header button "Start" in the saved trip table
	UIButton *headerButton = [UIButton buttonWithType:UIButtonTypeCustom];
	// [LIU] set button frame
	
	headerButton.layer.cornerRadius = 5;
	headerButton.titleLabel.numberOfLines=0;
	
	//[LIU] let the button have a line hint info about generating trips if server has pending trips.
	headerButton.frame = CGRectMake(10, 0, self.view.bounds.size.width-20, 50);
	[headerButton setTitle:@"   START/CONTINUE RECORDING" forState:UIControlStateNormal];
	[headerButton setBackgroundImage:[[UIImage imageNamed:@"start_button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(48,20,48,20) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
	
	headerButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
	[headerButton addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];

	
	[self.tableView reloadData];
	
	//[LIU] add button event
	//[LIU] link button to the tableview
	//self.tableView.tableHeaderView = headerButton;
	//[LIU] there are more info need to show in header part, change it as UIView, then we can add anything we want.
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, self.view.bounds.size.width-20, 120)];
	labelView = [[UILabel alloc] initWithFrame:CGRectMake(15, 50, self.view.bounds.size.width-20, 60)];
	//UILabel *labelView = [[UILabel alloc] init];
	labelView.numberOfLines = 0;
	labelView.text = [NSString stringWithFormat:@"Here are %ld trips loaded to local. %ld of them are pending to add detailed information. Latest refresh request gets %d new trips.", countAllLocalTrip ,countPendingLocalTrip,
					  (int)countNewTrips];
	labelView.font =[UIFont fontWithName:@"Helvetica-Bold" size:15];
	labelView.textColor = [UIColor colorWithRed:(188/255.f) green:(188/255.f) blue:(188/255.f) alpha:1.0];
	[headerView addSubview:labelView];
	[headerView addSubview:headerButton];
	self.tableView.tableHeaderView = headerView;
	//[LIU] add app right top cornor reminder
	[UIApplication sharedApplication].applicationIconBadgeNumber = countPendingLocalTrip;
	
	if (self.refreshControl) {
		NSString *title = @"";
		if (![self connected]) {
			title = [NSString stringWithFormat:@"No Internet Connectivity..."];
			NSLog(@"%@",@"no internet connection");
			// Not connected
		}
		else {
			title = [NSString stringWithFormat:@"Loading Trips From Server"];
		}
		NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
																	forKey:NSForegroundColorAttributeName];
		NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
		self.refreshControl.attributedTitle = attributedTitle;
		//[LIU] change it to add stop and pending effect
		//[self.refreshControl endRefreshing];
		//[LIU0313]
		[self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.5];
	}
	switch ((int)countPendingLocalTrip ) {
   
  case 0:
   break;
  default:
  {}
   UIAlertView *alert = [[UIAlertView alloc] initWithTitle: [NSString stringWithFormat:@"%ld of them are pending to add detailed information" ,countPendingLocalTrip]
               message:nil
												  delegate:self
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
   [alert show];
   
	}
	
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	//[LIU] used when having multiple section in tableview
	id  sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
	return [sectionInfo name];
}
//[LIU0325] add sections into tableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return [[[self tripSectionShow] sections] count];
}

- (NSFetchedResultsController *) tripSectionShow
{
	if (_fetchedResultsController != nil) {
		return _fetchedResultsController;
	}
	
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Trip"];
	
	NSString *key = @"startTime";
	
	fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:key
																 ascending:NO]];
	
	FloridaTripTrackerAppDelegate *delegatea= [[UIApplication sharedApplication] delegate];
	managedContext = [delegatea managedObjectContext];
	//NSManagedObjectContext *context;
	//managedContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
	
	NSFetchedResultsController *aFetchedResultsController;
	aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																	managedObjectContext:managedContext
																	  sectionNameKeyPath:@"dateSection"
																			   cacheName:nil];
	
	self.fetchedResultsController = aFetchedResultsController;
	
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		// Replace this implementation with code to handle the error appropriately.
		// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	
	return _fetchedResultsController;
	//[aFetchedResultsController performFetch:nil];
	
	//return [[aFetchedResultsController sections] count];
}


//[LIU] jump to page "record"
- (void)record:(id)sender
{
	[self.tabBarController setSelectedIndex:2];
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	//self.navigationItem.prompt = @" ";

	self.tableView.rowHeight = kRowHeight;
	self.tableView.backgroundView= nil;
	self.tableView.backgroundColor= [UIColor blackColor];
	
	// Set up the buttons.
	//[LIU]Disable this button, which was used to delete trip in savedTripView.
	//self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	
	//[LIU] Add function to pull down refresh
	self.refreshControl = [[UIRefreshControl alloc] init];
	self.refreshControl.backgroundColor = [UIColor blackColor];
	self.refreshControl.tintColor = [UIColor whiteColor];
	[self.refreshControl addTarget:self
							action:@selector(refreshTableView)
				  forControlEvents:UIControlEventValueChanged];
	
	//LoadingView *loading1 = (LoadingView*)[self.parentViewController.view viewWithTag:910];
	//[loading1 performSelector:@selector(removeView) withObject:nil afterDelay:0.5];
	
	// load trips from CoreData
	//[self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.5];
	// no trip selection by default
	selectedTrip = nil;
	//firstTimeLoad = YES;
}



- (void)viewWillAppear:(BOOL)animated
{	self.navigationController.interactivePopGestureRecognizer.enabled = NO;//lx 0325
	//self.navigationItem.prompt = nil;
	UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FDOT"]]];
	self.navigationItem.rightBarButtonItem = item;
	//[LIU0309] Add function to pull down refresh
	//[self refreshTableView];
	
	[super viewWillAppear:animated];
	
	NSString *title = [NSString stringWithFormat:@"Loading Trips From Server"];
	NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
																forKey:NSForegroundColorAttributeName];
	NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
	self.refreshControl.attributedTitle = attributedTitle;

	if (![self connected]) {
		NSLog(@"%@",@"no internet connection");
		// Not connected
	}
	else {
		//[LIU] below lines are used to refresh table and showing refresh effect when viewWillAppear
		self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
		[self.refreshControl beginRefreshing];
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[self refreshTableView];
			
		});
	}

}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	self.trips = nil;
	/*
	 self.locationManager = nil;
	 self.addButton = nil;
	 */
}


- (void)_recalculateDistanceForSelectedTripMap
{
	// important if we call from a background thread
	@autoreleasepool { // Top-level pool
		
		// instantiate a temporary TripManager to recalcuate distance
		TripManager *mapTripManager = [[TripManager alloc] initWithTrip:selectedTrip];
		CLLocationDistance newDist	= [mapTripManager calculateTripDistance:selectedTrip];
		
		// save updated distance to CoreData
		[mapTripManager.trip setDistance:[NSNumber numberWithDouble:newDist]];
		
		NSError *error;
		if (![mapTripManager.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"_recalculateDistanceForSelectedTripMap error %@, %@", error, [error localizedDescription]);
		}
		
		tripManager.dirty = YES;
		
		[self performSelectorOnMainThread:@selector(_displaySelectedTripMap) withObject:nil waitUntilDone:NO];
	}  // Release the objects in the pool.
}


- (void)_displaySelectedTripMap
{
	// important if we call from a background thread
	@autoreleasepool { // Top-level pool
		
		if ( selectedTrip )
		{
			MapViewController *mvc = [[MapViewController alloc] initWithTrip:selectedTrip];
			[[self navigationController] pushViewController:mvc animated:YES];
			selectedTrip = nil;
		}
		
	}  // Release the objects in the pool.
}


// display map view
- (void)displaySelectedTripMap
{
	loading		= [LoadingView loadingViewInView:self.parentViewController.view];
	loading.tag = 909;
	
	[self performSelectorInBackground:@selector(_recalculateDistanceForSelectedTripMap) withObject:nil];
}


#pragma mark Table view methods

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//[LIU0325] original one section
	//return [trips count];
	//[LIU0325] multiple section
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
	return [sectionInfo numberOfObjects];
}

- (TripCell *)getCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
	TripCell *cell = (TripCell*)[self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
	{
		cell = [[TripCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
		[cell setBackgroundColor:[UIColor blackColor]];
		cell.textLabel.textColor=[UIColor whiteColor];
		cell.detailTextLabel.textColor= [UIColor whiteColor];
		cell.detailTextLabel.numberOfLines = 2;
		if ( [reuseIdentifier  isEqual: kCellReuseIdentifierExclamation] )
		{
			// add exclamation point
			UIImage		*image		= [UIImage imageNamed:@"exclamation_point.png"];
			UIImageView *imageView	= [[UIImageView alloc] initWithImage:image];
			imageView.frame = CGRectMake( kAccessoryViewX, kAccessoryViewY, image.size.width, image.size.height );
			imageView.tag	= kTagImage;
			//[cell.contentView addSubview:imageView];
			cell.accessoryView = imageView;
		}
	}
	else
		[[cell.contentView viewWithTag:kTagImage] setNeedsDisplay];
	
	// slide accessory view out of the way during editing
	cell.editingAccessoryView = cell.accessoryView;
	
	return cell;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"cellForRowAtIndexPath");
	
	// A date formatter for timestamp
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	Trip *trip;


	long x = 0;
	
	for (int a = 0 ; a < indexPath.section; a++){
		x += [tableView.dataSource tableView:tableView numberOfRowsInSection: a];
	}
	
	trip = (Trip *)[trips objectAtIndex:indexPath.row + x];
	
	TripCell *cell = nil;
	
	// check for recordingInProgress
	//[LIU0313]Trip *recordingInProgress = [delegate getRecordingInProgress];
	/*
	 NSLog(@"trip: %@", trip);
	 NSLog(@"recordingInProgress: %@", recordingInProgress);
	 */
	
	NSString *tripStatus = nil;
	
	// completed
	if ( trip.purpose.length != 0 )
	{
		cell = [self getCellWithReuseIdentifier:kCellReuseIdentifierCheck];
		//cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
		UIImage	*image = nil;
		// add check mark
		image = [UIImage imageNamed:@"GreenCheckMark2.png"];
		
		int index = [TripPurpose getPurposeIndex:trip.purpose];
		NSLog(@"trip.purpose: %d => %@", index, trip.purpose);
		//int index =0;
		
		// add purpose icon
		switch ( index ) {
				
			case kTripPurposeHome:
				image = [UIImage imageNamed:kTripPurposeHomeIcon];
				break;
			case kTripPurposeWork:
				image = [UIImage imageNamed:kTripPurposeWorkIcon];
				break;
			case kTripPurposeRecreation:
				image = [UIImage imageNamed:kTripPurposeRecreationIcon];
				break;
			case kTripPurposeShopping:
				image = [UIImage imageNamed:kTripPurposeShoppingIcon];
				break;
			case kTripPurposeSocial:
				image = [UIImage imageNamed:kTripPurposeSocialIcon];
				break;
			case kTripPurposeMeal:
				image = [UIImage imageNamed:kTripPurposeMealIcon];
				break;
			case kTripPurposeSchool:
				image = [UIImage imageNamed:kTripPurposeSchoolIcon];
				break;
			case kTripPurposeCollege:
				image = [UIImage imageNamed:kTripPurposeCollegeIcon];
				break;
			case kTripPurposePersonalBiz:
				image = [UIImage imageNamed:kTripPurposePersonalBizIcon];
				break;
			case kTripPurposeEntertainment:
				image = [UIImage imageNamed:kTripPurposeEntertainmentIcon];
				break;
			case kTripPurposePickUp:
				image = [UIImage imageNamed:kTripPurposePickUpIcon];
				break;
			case kTripPurposeOther:
				image = [UIImage imageNamed:kTripPurposeOtherIcon];
				break;
			default:
				image = [UIImage imageNamed:@"GreenCheckMark2.png"];
		}
		
		UIImageView *imageView	= [[UIImageView alloc] initWithImage:image];
		imageView.frame			= CGRectMake( kAccessoryViewX, kAccessoryViewY, image.size.width, image.size.height );
		
		cell.accessoryView = imageView;
		
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n(With added detail info.)",
									 [dateFormatter stringFromDate:[trip startTime]]];
		tripStatus = @"(With added detail info.)";
	}
	
	// saved but not yet uploaded
	else if ( trip.purpose.length == 0 )
	{
		cell = [self getCellWithReuseIdentifier:kCellReuseIdentifierExclamation];
		//cell = [tableView dequeueReusableCellWithIdentifier:@"Trip" forIndexPath:indexPath];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n(Without added detail info.)",
									 [dateFormatter stringFromDate:[trip startTime]]];
		tripStatus = @"(Without added detail info.)";
	}
	
	// recording for this trip is still in progress (or just completed)
	// NOTE: this test may break when attempting re-upload
	//[LIU] no in progress trip
//	else if ( trip == recordingInProgress )
//	{
//		cell = [self getCellWithReuseIdentifier:kCellReuseIdentifierInProgress];
//		/*
//		 cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n(recording in progress)",
//		 [dateFormatter stringFromDate:[trip start]]];
//		 */
//		[cell setDetail:[NSString stringWithFormat:@"%@\n(recording in progress)", [dateFormatter stringFromDate:[trip startTime]]]];
//		tripStatus = @"(recording in progress)";
//	}
//	
//	// this trip was orphaned (an abandoned previous recording)
//	else
//	{
//		cell = [self getCellWithReuseIdentifier:kCellReuseIdentifierExclamation];
//		tripStatus = @"(recording interrupted)";
//	}
	
	/*
	 cell.textLabel.text = [NSString stringWithFormat:@"%@ (%.0fm, %.fs)",
	 trip.purpose, [trip.distance doubleValue], [trip.duration doubleValue]];
	 */
	cell.detailTextLabel.tag	= kTagDetail;
	cell.textLabel.tag			= kTagTitle;
	
	/*
	 cell.textLabel.text = [NSString stringWithFormat:@"%@: %.0fm",
	 trip.purpose, [trip.distance doubleValue]];
	 */
	
	// display duration, distance as navbar prompt
	static NSDateFormatter *inputFormatter = nil;
	if ( inputFormatter == nil )
		inputFormatter = [[NSDateFormatter alloc] init];
	
	[inputFormatter setDateFormat:@"HH:mm:ss"];
	NSDate *fauxDate = [inputFormatter dateFromString:@"00:00:00"];
	[inputFormatter setDateFormat:@"HH:mm:ss"];
	NSLog(@"trip duration: %f", [trip.duration doubleValue]);
	NSDate *outputDate = [[NSDate alloc] initWithTimeInterval:(NSTimeInterval)[trip.duration doubleValue]
													sinceDate:fauxDate];
	
	double mph = ( [trip.distance doubleValue] / 1609.344 ) / ( [trip.duration doubleValue] / 3600. );
	/*
	 cell.textLabel	= [NSString stringWithFormat:@"%.1f mi ~ %.1f mph ~ %@",
	 [trip.distance doubleValue] / 1609.344,
	 mph,
	 trip.purpose
	 ]];
	 */
	cell.textLabel.text			= [dateFormatter stringFromDate:[trip startTime]];
	//[LIU0313]
//	cell.detailTextLabel.text	= [NSString stringWithFormat:@"%@: %.1f mi ~ %.1f mph\nelapsed time: %@",
//								   trip.purpose,
//								   [trip.distance doubleValue] / 1609.344,
//								   mph,
//								   [inputFormatter stringFromDate:outputDate]
//								   ];
	cell.detailTextLabel.text	= [NSString stringWithFormat:@"%@",trip.purpose];
	
	//[LIU0325]
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	[self.fetchedResultsController objectAtIndexPath:indexPath];
}
- (void)promptToConfirmPurpose
{
	NSLog(@"promptToConfirmPurpose");
	
	// construct purpose confirmation string
	NSString *purpose = nil;
	if ( tripManager != nil )
		//	purpose = [self getPurposeString:[tripManager getPurposeIndex]];
		purpose = tripManager.trip.purpose;
	
	//NSString *confirm = [NSString stringWithFormat:@"This trip has not yet been uploaded. Confirm the trip's purpose to try again: %@", purpose];
	NSString *confirm = [NSString stringWithFormat:@"This trip has not yet been uploaded. Try now?"];
	
	// present action sheet
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:confirm
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil
													otherButtonTitles:@"Upload", nil];
	
	actionSheet.actionSheetStyle	= UIActionSheetStyleBlackTranslucent;
	[actionSheet showInView:self.tabBarController.view];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Navigation logic may go here. Create and push another view controller.
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	// identify trip by row
	//NSLog(@"didSelectRow: %d", indexPath.row);
	selectedTrip = (Trip *)[trips objectAtIndex:indexPath.row];
	NSLog(@"+++++++++++++++++++++++++++++tableview selected trip+++++++++++++++++++++++++++++++++++%@", selectedTrip);
	
	// check for recordingInProgress
	Trip *recordingInProgress = [delegate getRecordingInProgress];
	
	// if trip not yet uploaded => prompt to re-upload
	if ( recordingInProgress != selectedTrip )
	{
		/*[LIU] No need this if condition all the items go to mapView to check and add more detailed info or remove
		 if ( !selectedTrip.uploaded )
		 {
			// init new TripManager instance with selected trip
			// release previously set tripManager
			
			tripManager = [[TripManager alloc] initWithTrip:selectedTrip];
			//tripManager.activityDelegate = self;
			tripManager.alertDelegate = self;
			
			// prompt to upload
			[self promptToConfirmPurpose];
		 }
		 
		 // else => goto map view
		 else
		 */
		[self displaySelectedTripMap];
	}
	//else disallow selection of recordingInProgress
}

//[LIU] useless code, disabled delete function in savedTripView
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	Trip *tempTrip= (Trip *)[trips objectAtIndex:indexPath.row];
	
	// if trip is not in progress and hasn't been uploaded
	if ( ![cell.reuseIdentifier  isEqual: kCellReuseIdentifierInProgress] && !tempTrip.uploaded)
	{
		// it can be deleted
		//[LIU] changed it from true to false, since no trip need to be delete from this page.
		return true;
	}
	// otherwise, no
	return false;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	//[LIU]this delete activity should be done in map page.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSLog(@"Delete");
		
		// Delete the managed object at the given index path.
		NSManagedObject *tripToDelete = [trips objectAtIndex:indexPath.row];
		[tripManager.managedObjectContext deleteObject:tripToDelete];
		
		// Update the array and table view.
		[trips removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
		// Commit the change.
		NSError *error;
		if (![tripManager.managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"Unresolved error %@", [error localizedDescription]);
		}
	}
	else if ( editingStyle == UITableViewCellEditingStyleInsert )
		NSLog(@"INSERT");
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */



#pragma mark UINavigationController


- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated
{
	if ( viewController == self )
	{
		//NSLog(@"willShowViewController:self");
		self.title = @"View Saved Trips";
	}
	else
	{
		//NSLog(@"willShowViewController:else");
		self.title = @"Back";
		self.tabBarItem.title = @"View Saved Trips"; // important to maintain the same tab item title
	}
}


#pragma mark UIActionSheet delegate methods


// NOTE: implement didDismissWithButtonIndex to process after sheet has been dismissed
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	//NSLog(@"actionSheet clickedButtonAtIndex %d", buttonIndex);
	switch ( buttonIndex )
	{
			/*
			 case kActionSheetButtonDiscard:
			 NSLog(@"Discard");
			 
			 // Delete the selectedTrip
			 //NSManagedObject *tripToDelete = [trips objectAtIndex:indexPath.row];
			 [tripManager.managedObjectContext deleteObject:selectedTrip];
			 
			 // Update the array and table view.
			 //[trips removeObjectAtIndex:indexPath.row];
			 NSUInteger index = [trips indexOfObject:selectedTrip];
			 [trips removeObjectAtIndex:index];
			 selectedTrip = nil;
			 
			 // TODO: get indexPath for animation
			 //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
			 [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:YES];
			 //[self.tableView reloadData];
			 
			 // Commit the change.
			 NSError *error;
			 if (![tripManager.managedObjectContext save:&error]) {
				// Handle the error.
				NSLog(@"Unresolved error %@", [error localizedDescription]);
			 }
			 break;
			 */
			/*
			 case kActionSheetButtonConfirm:
			 NSLog(@"Confirm => creating Trip Notes dialog");
			 [tripManager promptForTripNotes];
			 break;
			 */
			//case kActionSheetButtonChange:
			//[LIU] This case 0 need to happen when the button of MapView of adding detail is tabbed.
		case 0: {
			NSLog(@"Upload => push Trip Purpose picker");
			/*
			 // NOTE: this code to get purposeIndex fails for the load a saved trip case
			 PickerViewController *pickerViewController = [[PickerViewController alloc]
			 initWithPurpose:[tripManager getPurposeIndex]];
			 [pickerViewController setDelegate:self];
			 [[self navigationController] pushViewController:pickerViewController animated:YES];
			 [pickerViewController release];
			 */
			
			// Trip Purpose
			NSLog(@"INIT + PUSH");
			TripQuestionsViewController *pickerViewController = [[TripQuestionsViewController alloc]
																 initWithNibName:@"TripPurposePicker" bundle:nil];
			[pickerViewController setDelegate:self];
			//[[self navigationController] pushViewController:pickerViewController animated:YES];
			[self.navigationController presentViewController:pickerViewController animated:YES completion:nil];
			break;
			
			//case kActionSheetButtonCancel:
		}
		case 1:
		default:
			NSLog(@"Cancel");
			[self displaySelectedTripMap];
			break;
	}
}


// called if the system cancels the action sheet (e.g. homescreen button has been pressed)
- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	NSLog(@"actionSheetCancel");
}


#pragma mark UIAlertViewDelegate methods


// NOTE: method called upon closing save error / success alert
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag) {
		case 202:
		{
			//NSLog(@"zeroDistance didDismissWithButtonIndex: %d", buttonIndex);
			switch (buttonIndex) {
				case 0:
					// nothing to do
					break;
				case 1:
				default:
					// Recalculate
					//[tripManager recalculateTripDistances];
					break;
			}
		}
			break;
		case 303:
		{
			//NSLog(@"unSyncedTrips didDismissWithButtonIndex: %d", buttonIndex);
			switch (buttonIndex) {
				case 0:
					// Nevermind
					[self displaySelectedTripMap];
					break;
				case 1:
				default:
					// Upload Now
					break;
			}
		}
			break;
		//lx set for pending trip alert
		case 0:
		{
			break;
		}
		//*lx
		default:
		{
			//NSLog(@"SavedTripsView alertView: didDismissWithButtonIndex: %d", buttonIndex);
			[self displaySelectedTripMap];
		}
	}
}


#pragma mark TripPurposeDelegate methods


- (NSString *)setPurpose:(unsigned int)index
{
	return [tripManager setPurpose:index];
}


- (NSString *)getPurposeString:(unsigned int)index
{
	return [tripManager getPurposeString:index];
}


- (void)didCancelPurpose
{
	//[LIU] TODO this function does not work.
	//[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didPickPurpose:(NSMutableDictionary *)tripAnswers
{
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	//[tripManager setPurpose:[tripAnswers objectForKey:@"purposeInt"]];
	
	FloridaTripTrackerAppDelegate *delegate1= [[UIApplication sharedApplication] delegate];
	managedContext= [delegate1 managedObjectContext];
	
	//[LIU]this is incorrect, should not use a new trip, should save to original trip.
	Trip *trip=[[Trip alloc]init];
	
	[trip  setTravelBy:[tripAnswers objectForKey:@"travelBy"]];
	//[trip  setPurpose:[self getPurposeString:[tripAnswers objectForKey:@"purposeInt"]]];
	[trip  setPurpose:[tripAnswers objectForKey:@"purpose"]];
	[trip  setFare:[tripAnswers objectForKey:@"fare"]];
	[trip  setDelays:[tripAnswers objectForKey:@"delays"]];
	[trip  setMembers:[tripAnswers objectForKey:@"members"]];
	[trip  setNonMembers:[tripAnswers objectForKey:@"nonmembers"]];
	[trip  setPayForParking:[tripAnswers objectForKey:@"payForParking"]];
	[trip  setToll:[tripAnswers objectForKey:@"toll"]];
	[trip  setPayForParkingAmt:[tripAnswers objectForKey:@"payForParkingAmt"]];
	[trip  setTollAmt:[tripAnswers objectForKey:@"tollAmt"]];
	
	
	//lx
	[trip  setIsMembers:[tripAnswers objectForKey:@"isMembers"]];
	[trip  setFamilyMembers:[tripAnswers objectForKey:@"familyMembers"]];
	[trip  setIsnonMembers:[tripAnswers objectForKey:@"isnonMembers"]];
	[trip  setDriverType:[tripAnswers objectForKey:@"driverType"]];
	
	
	NSError *error;
	if (![managedContext save:&error]) {
		// Handle the error.
		NSLog(@"updatetripanswer error %@, %@", error, [error localizedDescription]);
	}
	
	//*lx
	//[LIU]
	//[tripManager saveTrip];
}


@end

