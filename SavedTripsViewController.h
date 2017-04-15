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
//  SavedTripsViewController.h
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 8/10/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "ActivityIndicatorDelegate.h"
#import "RecordingInProgressDelegate.h"
#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>

@class LoadingView;
@class MapViewController;
@class Trip;
@class TripManager;

@interface SavedTripsViewController : UITableViewController 
	<TripPurposeDelegate,
	UIActionSheetDelegate,
	UIAlertViewDelegate,
	UINavigationControllerDelegate>
{
	NSMutableArray *trips;
    NSManagedObjectContext *managedObjectContext;
	
	id <RecordingInProgressDelegate> delegate;
	TripManager *tripManager;
	Trip *selectedTrip;
	
	LoadingView *loading;
	//[LIU]used to request day trip from server
	//NSMutableURLRequest *request;
	//NSString *deviceUniqueIdHash;
	NSMutableDictionary *postVars;

}

@property (nonatomic, strong) NSMutableArray *trips;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) id <RecordingInProgressDelegate> delegate;
@property (nonatomic, strong) TripManager *tripManager;
@property (nonatomic, strong) Trip *selectedTrip;
//[LIU]
//@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) UILabel *labelView;
@property (nonatomic, strong) NSMutableDictionary *postVars;
@property (nonatomic, strong) NSString *deviceUniqueIdHash;
@property (nonatomic, strong) NSDictionary *responseDict;
@property Trip *trip;
@property NSManagedObjectContext *managedContext;
@property BOOL firstTimeLoad;
@property NSInteger *countNewTrips;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (void)initTripManager:(TripManager*)manager;//lx
- (BOOL)connected;

//[LIU0414] add the refresh flag, only refresh at the first time
@property BOOL refreshFlag;

// DEPRECATED
- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context;
- (id)initWithTripManager:(TripManager*)manager;

@end
