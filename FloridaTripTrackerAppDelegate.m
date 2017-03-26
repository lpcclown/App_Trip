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
//  FloridaTripTrackerAppDelegate.m
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/21/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>

#import <CommonCrypto/CommonDigest.h>

#import "constants.h"
#import "FloridaTripTrackerAppDelegate.h"
#import "PersonalInfoViewController.h"
#import "OneTimeQuestionsViewController.h"
#import "RecordTripViewController.h"
#import "SavedTripsViewController.h"
#import "TripManager.h"
#import "WelcomeViewController.h"
#import "User.h"


@implementation FloridaTripTrackerAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize uniqueIDHash;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// disable screen lock
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	//[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
		UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
		UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
		[[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
	} else {
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
		
		//[application setApplicationIconBadgeNumber:3];
	}
	
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
	
    NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        // Handle the error.
    }
	
	// init our unique ID hash
	[self initUniqueIDHash];
	
	// initialize trip manager with the managed object context
	TripManager *manager = [[TripManager alloc] initWithManagedObjectContext:context];
	
	
	/*
	 // initialize each tab's root view controller with the trip manager	
	 RecordTripViewController *recordTripViewController = [[[RecordTripViewController alloc]
	 initWithTripManager:manager]
	 autorelease];
	 
	 // create tab bar items for the tabs themselves
	 UIImage *image = [UIImage imageNamed:@"tabbar_record.png"];
	 UITabBarItem *recordTab = [[UITabBarItem alloc] initWithTitle:@"Record New Trip" image:image tag:101];
	 recordTripViewController.tabBarItem = recordTab;
	 
	 SavedTripsViewController *savedTripsViewController = [[[SavedTripsViewController alloc]
	 initWithTripManager:manager]
	 autorelease];
	 
	 // RecordingInProgressDelegate
	 savedTripsViewController.delegate = recordTripViewController;
	 
	 image = [UIImage imageNamed:@"tabbar_view.png"];
	 UITabBarItem *viewTab = [[UITabBarItem alloc] initWithTitle:@"View Saved Trips" image:image tag:102];
	 savedTripsViewController.tabBarItem = viewTab;
	 
	 // create a navigation controller stack for each tab, set delegates to respective root view controller
	 UINavigationController *recordTripNavController = [[UINavigationController alloc]
	 initWithRootViewController:recordTripViewController];
	 recordTripNavController.delegate = recordTripViewController;
	 recordTripNavController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	 
	 UINavigationController *savedTripsNavController = [[UINavigationController alloc]
	 initWithRootViewController:savedTripsViewController];
	 savedTripsNavController.delegate = savedTripsViewController;
	 savedTripsNavController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	 */
	
	if ([self hasUserInfoBeenSaved]) {
		UINavigationController	*recordNav	= (UINavigationController*)[tabBarController.viewControllers
																	objectAtIndex:2];
		//[navCon popToRootViewControllerAnimated:NO];
		recordVC	= (RecordTripViewController *)[recordNav topViewController];
		[recordVC initTripManager:manager];
	
	
		UINavigationController	*tripsNav	= (UINavigationController*)[tabBarController.viewControllers
																	objectAtIndex:1];
		//[navCon popToRootViewControllerAnimated:NO];
		SavedTripsViewController *tripsVC	= (SavedTripsViewController *)[tripsNav topViewController];
		tripsVC.delegate					= recordVC;
		[tripsVC initTripManager:manager];

		// select [LIU] trips tab at launch
		tabBarController.selectedIndex = 1;
		
		[window setFrame:[[UIScreen mainScreen] bounds]];
		[window addSubview:tabBarController.view];
		[window setRootViewController:tabBarController];
		[window makeKeyAndVisible];
	}
	
	else {
		WelcomeViewController *vc= [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil];
		UINavigationController *nav= [[UINavigationController alloc] initWithRootViewController:vc];
		
		[nav setNavigationBarHidden:NO];
		[[nav navigationBar] setBarStyle:UIBarStyleBlack];
	
		[window setFrame:[[UIScreen mainScreen] bounds]];
		[window setRootViewController:nav];
		[window makeKeyAndVisible];
	}
}

- (void) createMainView {
	// initialize trip manager with the managed object context
	TripManager *manager = [[TripManager alloc] initWithManagedObjectContext:[self managedObjectContext]];
	
	UINavigationController	*recordNav	= (UINavigationController*)[tabBarController.viewControllers
																	objectAtIndex:2];
	//[navCon popToRootViewControllerAnimated:NO];
	recordVC	= (RecordTripViewController *)[recordNav topViewController];
	[recordVC initTripManager:manager];
	
	
	UINavigationController	*tripsNav	= (UINavigationController*)[tabBarController.viewControllers
																	objectAtIndex:1];
	//[navCon popToRootViewControllerAnimated:NO];
	SavedTripsViewController *tripsVC	= (SavedTripsViewController *)[tripsNav topViewController];
	tripsVC.delegate					= recordVC;
	[tripsVC initTripManager:manager];
	
	// select [LIU] trips tab at launch
	tabBarController.selectedIndex = 1;
	
	//UINavigationController	*nav	= (UINavigationController*)[tabBarController.viewControllers objectAtIndex:3];
	//PersonalInfoViewController *vc	= (PersonalInfoViewController *)[nav topViewController];
	//vc.managedObjectContext			= [self managedObjectContext];
	
	[window setFrame:[[UIScreen mainScreen] bounds]];
	[window addSubview:tabBarController.view];
	[window setRootViewController:tabBarController];
	[window makeKeyAndVisible];
}


- (void)initUniqueIDHash
{
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	const char * uniqueIDStr = [UIDevice currentDevice].identifierForVendor.UUIDString.UTF8String;
	CC_MD5(uniqueIDStr, (int) strlen(uniqueIDStr), result);
	NSString *uniqueID = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
						  result[0], result[1], result[2], result[3],
						  result[4], result[5], result[6], result[7],
						  result[8], result[9], result[10], result[11],
						  result[12], result[13], result[14], result[15]
						  ];
	
	NSLog(@"uniqueID: %@", [UIDevice currentDevice].identifierForVendor);	
	NSLog(@"Hashed uniqueID: %@", uniqueID);
	self.uniqueIDHash = uniqueID; // save for later.
}

- (BOOL)hasUserInfoBeenSaved
{
	BOOL					response = NO;
	NSManagedObjectContext	*context = [self managedObjectContext];
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
			if (user != nil && (user.age != nil))
			{
				response = YES;
			}
		}
		else
		{
			// Handle the error.
			if ( error != nil )
				NSLog(@"PersonalInfo viewDidLoad fetch error %@, %@", error, [error localizedDescription]);
		}
	}
	
	return response;
}

/** 
 * Nofity the OS we're going to be doing stuff in the background -- recording, updating the timer, etc.
 */
- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    if (recordVC) {
        // Let the RecordTripViewController take care of its business
        [recordVC handleBackgrounding];
    }
    
    // If we're not recording -- don't bother with the background task
    if (recordVC && ![recordVC recording]) {
        //NSLog(@"applicationDidEnterBackground - bgTask=%d (should be zero)", bgTask);
        return;
    }
    
    bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Background Handler: End background because time ran out, cleaning up task.");
            
            // time's up - end the background task
			//[LIU0314]
			//[application endBackgroundTask:bgTask];
            
        });
    }];

    //NSLog(@"applicationDidEnterBackground - bgTask=%d", bgTask);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    //NSLog(@"applicationWillEnterForeground - bgTask=%d", bgTask);
    if (bgTask) {
        [application endBackgroundTask:bgTask];        
    }
    bgTask = 0;

    if (recordVC) {
        [recordVC handleForegrounding];
        if (recordVC.recording) {
            tabBarController.selectedIndex = 1;
        }
    }
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	
    if (recordVC) {
        [recordVC handleTermination];
    }
    
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			NSLog(@"applicationWillTerminate: Unresolved error %@, %@", error, [error userInfo]);
			abort();
        } 
    }
}

#pragma mark Version & Build Functions
/** See http://stackoverflow.com/questions/7608632/how-do-i-get-the-current-version-of-my-ios-project-in-code **/

+ (NSString *) appVersion
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

+ (NSString *) build
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
}

+ (NSString *) versionBuild
{
	NSString * version = [self appVersion];
	NSString * build = [self build];
	
	NSString * versionBuild = [NSString stringWithFormat: @"v%@", version];
	
	if (![version isEqualToString: build]) {
		versionBuild = [NSString stringWithFormat: @"%@(%@)", versionBuild, build];
	}
	
	return versionBuild;
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"CycleTracks.sqlite"]];
	//[PLIU] to check where is the file in simulator
#if TARGET_IPHONE_SIMULATOR
	// where are you?
	NSLog(@"Documents Directory: %@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);
#endif
	NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }    
	
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	[application registerForRemoteNotifications];
	//[application setApplicationIconBadgeNumber:99999];
}


#pragma mark -
#pragma mark Memory management



@end

