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
//	PickerViewController.m
//	CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/28/09.
//	For more information on the project,
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>


#import "CustomView.h"
#import "TripQuestionsViewController.h"
#import "TravelModePickerViewDataSource.h"
#import "TripManager.h"
#import "SavedTripsViewController.h"
#import "Trip.h"//lx
#import "User.h"//lx
#import "FloridaTripTrackerAppDelegate.h"//lx
#import "constants.h"
#import "ServerInteract.h"



@implementation TripQuestionsViewController

@synthesize customPickerView, customPickerDataSource, delegate, tripDescription;

@synthesize accidentSegment, fareCost, fareQuestion, householdMembers,nonHouseholdMembers, parkingCost, parkingSegment, scrollView, tollCost, tollSegment, travelModePicker, tmDataSource, saveButton, otherTripPurposeText;

//lx
@synthesize startTimeChange,endTimechange,householdmembersSegment,houseMembersdynamic,nonHouseholdmembersSegment,driverPassengerSegment,activityPicker,trip;
@synthesize activityPickerViewDataSource;
@synthesize housholdMemberselected,numofhousholdMemberselected,familyMember,cancel,cancelButton, startDatePicker, endDatePicker;
//*lx


// return the picker frame based on its size
- (CGRect)pickerFrameWithSize:(CGSize)size
{
	
	// layout at bottom of page
	
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect pickerRect = CGRectMake(	0.0,
								   screenRect.size.height - 84.0 - size.height,
								   size.width,
								   size.height);
	
	
	// layout at top of page
	//CGRect pickerRect = CGRectMake(	0.0, 0.0, size.width, size.height );
	
	// layout at top of page, leaving room for translucent nav bar
	//CGRect pickerRect = CGRectMake(	0.0, 43.0, size.width, size.height );
	//CGRect pickerRect = CGRectMake(	0.0, 78.0, size.width, size.height );
	return pickerRect;
}


- (void)createCustomPicker
{
	customPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
	customPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	// setup the data source and delegate for this picker
	customPickerDataSource = [[CustomPickerDataSource alloc] init];
	customPickerDataSource.parent = self;
	customPickerView.dataSource = customPickerDataSource;
	customPickerView.delegate = customPickerDataSource;
	
	// note we are using CGRectZero for the dimensions of our picker view,
	// this is because picker views have a built in optimum size,
	// you just need to set the correct origin in your view.
	//
	// position the picker at the bottom
	CGSize pickerSize = [customPickerView sizeThatFits:CGSizeZero];
	customPickerView.frame = [self pickerFrameWithSize:pickerSize];
	
	customPickerView.showsSelectionIndicator = YES;
	
	// add this picker to our view controller, initially hidden
	//customPickerView.hidden = NO;//lx let original purpose  hidden
	[self.view addSubview:customPickerView];
}


- (IBAction)cancel:(id)sender
{
	//[LIU]
	//[delegate didCancelPurpose];
	//[LIU] dismiss the page
	[self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)cancelButton:(id)sender
{
	//[LIU]
	//[delegate didCancelPurpose];
	//[LIU] dismiss the page
	[self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

//lx
- (IBAction)save:(id)sender
{
	if((numofhousholdMemberselected == 0 && [householdmembersSegment selectedSegmentIndex] == 0)){
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please select your household members on this trip transportation."
														message:nil
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}else{
		
		//lx
		if ([[travelModePicker delegate] pickerView:travelModePicker titleForRow:[travelModePicker selectedRowInComponent:0] forComponent:0].length == 0){
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please select your type of transportation."
															message:nil
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
		else if ([[activityPicker delegate] pickerView:activityPicker titleForRow:[activityPicker selectedRowInComponent:0] forComponent:0].length == 0){
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please select your PRIMARY activity."
															message:nil
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
		//*lx
		
		else{
			
			if ( [housholdMemberselected length] != 0){
				housholdMemberselected = [housholdMemberselected substringToIndex:[housholdMemberselected length]-1];
				NSLog(@"were any with you? is %@,housholdMemberselected finally:%@,so total householdmembers %@is on this trip",(([householdmembersSegment selectedSegmentIndex] == 0) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0]), housholdMemberselected,[NSNumber numberWithInteger:numofhousholdMemberselected] );
			}
			
			//[LIU] mark out furthur logic
			//[delegate didPickPurpose: tripAnswers];
			
			//[LIU] save updated trip into DB
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			FloridaTripTrackerAppDelegate *delegatea= [[UIApplication sharedApplication] delegate];
			NSManagedObjectContext *managedContext = [delegatea managedObjectContext];
			request.predicate = [NSPredicate predicateWithFormat:@"sysTripID = %@", trip.sysTripID];
			NSLog(@"To be updated trip ID is: %@", trip.sysTripID);
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:managedContext];
			[request setEntity:entity];
			NSArray *result = [managedContext executeFetchRequest:request error:nil];
			Trip *directedTrip = [result objectAtIndex:0];
			NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
			
			//[LIU]
			if ([startTimeChange.text rangeOfString:@"M"].location == NSNotFound) {
				//24h
				[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
			} else {
				//12h
				[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
			}
			NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
			[dateFormat setLocale:locale];
			
			//startTime && stopTime
			directedTrip.startTime=[dateFormat dateFromString:startTimeChange.text];
			directedTrip.stopTime=[dateFormat dateFromString:endTimechange.text];
			//travelBy
			directedTrip.travelBy = [[travelModePicker delegate] pickerView:travelModePicker titleForRow:[travelModePicker selectedRowInComponent:0] forComponent:0];
			//isMembers
			if([householdmembersSegment selectedSegmentIndex] !=-1){
				
				directedTrip.isMembers =(([householdmembersSegment selectedSegmentIndex] == 0) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0]);
			}else directedTrip.isMembers = @-1;
			//familyMembers && members (how many seleted)
			if ([directedTrip.isMembers  isEqual: @1]) {
				directedTrip.familyMembers = housholdMemberselected;
				directedTrip.members = [NSNumber numberWithInteger:numofhousholdMemberselected] ;
			}else{
				directedTrip.familyMembers = @"";
				directedTrip.members = @0;

			}
			
			//isnonMembers
			if([nonHouseholdmembersSegment selectedSegmentIndex] !=-1){
				directedTrip.isnonMembers =(([nonHouseholdmembersSegment selectedSegmentIndex] == 0) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0]);
			}else
				directedTrip.isnonMembers = @-1;
			
			//nonMembers
			if ([[nonHouseholdMembers text]  isEqual: @""]) {
				directedTrip.nonMembers=@0;
				NSLog(@"directedTrip.nonMembers is: %@", directedTrip.nonMembers);
			}else
				directedTrip.nonMembers =[NSNumber numberWithInt:[[nonHouseholdMembers text] intValue]];
			
			//driverType
			if([driverPassengerSegment selectedSegmentIndex] !=-1){
				directedTrip.driverType=([driverPassengerSegment selectedSegmentIndex] == 0) ? (@"Driver") : (@"Passenger") ;
			}else directedTrip.driverType = @"";
			
			//toll
			if([tollSegment selectedSegmentIndex] !=-1){
				
				directedTrip.toll =(([tollSegment selectedSegmentIndex] == 0) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0]);
			}else
				directedTrip.toll = @-1;
			
			//[LIU]
			//PickerViewDataSource *purposeAnswer= (PickerViewDataSource *)[activityPicker dataSource];
			//	NSString *otherText= [otherTripPurposeText text];
			//		if ([[purposeAnswer dataArray] objectAtIndex:11]) {
			//			[tripAnswers setObject:otherText forKey:@"purpose"];
			//		}
			directedTrip.purpose = [[activityPicker delegate] pickerView:activityPicker titleForRow:[activityPicker selectedRowInComponent:0] forComponent:0];
			
			
			NSLog(@"upload trip index as follows:\nstartTime is: %@\nstopTime is: %@\ntravelBy is: %@\nisMembers is: %@\nfamilyMembers is: %@\nmembers is: %@\nisnonMembers is: %@\nnonMembers is: %@\ndriverType is: %@\ntoll is: %@", startTimeChange.text,endTimechange.text, directedTrip.travelBy, directedTrip.isMembers, directedTrip.familyMembers, directedTrip.members, directedTrip.isnonMembers, directedTrip.nonMembers, directedTrip.driverType, directedTrip.toll);
			
			//[LIU] save updated trip into server
			NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
			NSEntityDescription *user = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedContext];
			[userRequest setEntity:user];
			NSArray *userInUserTable = [managedContext executeFetchRequest:userRequest error:nil];
			User *person= [userInUserTable objectAtIndex:0];
			NSString *deviceNum =person.deviceNum;
			NSDictionary *userDevice = [NSDictionary dictionaryWithObjectsAndKeys:deviceNum,@"device", nil];
			NSDateFormatter *dateFormatOnServer = [[NSDateFormatter alloc] init];
			[dateFormatOnServer setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];//[LIU] to update the date format as server acceptable
			[dateFormatOnServer setLocale:locale];
			NSString *startTime = [dateFormatOnServer stringFromDate: directedTrip.startTime];
			NSString *stopTime = [dateFormatOnServer stringFromDate: directedTrip.stopTime];
			NSDictionary *updatedTripInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											 trip.sysTripID,@"tripid",
											 @0,@"delays",
											 @0,@"fare",
											 directedTrip.isMembers,@"members",
											 directedTrip.familyMembers,@"membersDetail",
											 directedTrip.nonMembers,@"nonmembers",
											 @0,@"payForParking",
											 @0,@"payForParkingAmt",
											 directedTrip.purpose,@"purpose",
											 startTime,@"startTime",
											 stopTime,@"stopTime",
											 directedTrip.toll, @"toll",
											 @0, @"tollAmt",
											 directedTrip.travelBy, @"travelBy",
											 userDevice, @"user", nil];
			
			NSData *responseData= [ServerInteract sendRequest:updatedTripInfo toURLAddress:KUpdateTrip];
			if (responseData != nil){
				NSDictionary *serverFeedback = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
				NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
				
				
				if ([serverFeedbackString hasSuffix:@"was updated"]) {
					[trip setSuccTag:@1];//[LIU] 1 means succeed, 0 means failed
					
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Information To Server Succeed."
																	message:nil
																   delegate:self
														  cancelButtonTitle:@"OK"
														  otherButtonTitles:nil];
					[alert show];
					
					//[LIU] the model view to disappear
					[self dismissViewControllerAnimated:NO completion:^{
						SavedTripsViewController *savedTripsViewController = [[SavedTripsViewController alloc]initWithNibName:@"MainWindow" bundle:nil];
						[self.navigationController presentViewController:savedTripsViewController animated:YES completion:nil];
					}];
					
					NSLog(@"Update trip info succeed DB tag: succ_Tag:1");
					
				}
				
				else {
					[trip setSuccTag:@0];
					NSLog(@"Update trip info failed DB tag: succ_Tag:0");
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Information To Server Failed, Please Try Again Later."
																	message:nil
																   delegate:self
														  cancelButtonTitle:@"OK"
														  otherButtonTitles:nil];
					[alert show];
				}}else{		[trip setSuccTag:@0];
					NSLog(@"Update trip info failed DB tag: succ_Tag:0");
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInternetError
																	message:nil
																   delegate:self
														  cancelButtonTitle:@"OK"
														  otherButtonTitles:nil];
					[alert show];
				}
			
			//[LIU] save the latest info to DB.
			if ([managedContext save:nil]) {
				
				NSLog(@"Update Trip detailed info to DB succeed.");
				
			} else {
				
				NSLog(@"Update Trip detailed info to DB failed.");
				
			}
		}
	}
}

- (IBAction)backgroundTouched:(id)sender {
	[startTimeChange resignFirstResponder];
	[endTimechange resignFirstResponder];
	[fareCost resignFirstResponder];
	[householdMembers resignFirstResponder];
	[nonHouseholdMembers resignFirstResponder];
	[parkingCost resignFirstResponder];
	[tollCost resignFirstResponder];
}


- (IBAction)segmentChanged:(id)sender {
	
	if (nonHouseholdmembersSegment.selectedSegmentIndex == 1) {
		nonHouseholdMembers.text=@"0";
		nonHouseholdMembers.enabled = NO;
	}else if (nonHouseholdmembersSegment.selectedSegmentIndex == 0) {
		NSLog(@"[[trip nonMembers] intValue]is %@",[trip nonMembers]);
		if ([[trip nonMembers] intValue] <=0 ) {
			nonHouseholdMembers.text=@"";
			nonHouseholdMembers.enabled=YES;
			
		}else
		{nonHouseholdMembers.text=[[trip nonMembers] stringValue];
			nonHouseholdMembers.enabled=YES;
		}
	}
	
	if ([sender tag] == 1) {
		if ([sender selectedSegmentIndex] == 1) {
			[tollCost setText:@""];
			[tollCost setHidden:NO];
		}
		else [tollCost setHidden:YES];
	}
	
	
	else if ([sender tag] == 2) {
		if ([sender selectedSegmentIndex] == 1) {
			[parkingCost setText:@""];
			[parkingCost setHidden:NO];
		}
		else [parkingCost setHidden:YES];
	}
}

//[LIU]
- (id)initWithTrip:(Trip *)tripFromMapView
{
	
	//if (self = [super init]) {
	if (self = [self initWithNibName:@"TripPurposePicker" bundle:nil]) {
		NSLog(@"TripQuestionViewController initWithTrip");
		self.trip = tripFromMapView;
	}
	//[LIU]0314 provide db info to page
	
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
 
	//[LIU]
	if ([startTimeChange.text rangeOfString:@"M"].location == NSNotFound) {
		//24h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	} else {
		//12h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	}
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[dateFormat setLocale:locale];
	
	NSLog(@"[[trip travelBy] intValue]%@",[trip travelBy]);
	NSLog(@"[[trip isMembers] intValue]%@",[trip isMembers]);
	NSLog(@"[[trip familyMembers] intValue]%@",[trip familyMembers]);
	NSLog(@"[[trip isnonMembers] intValue]%@",[trip isnonMembers]);
	
	NSLog(@"[[trip nonMembers] intValue]%@",[trip nonMembers]);
	
	NSLog(@"[[trip driverType] intValue]%@",[trip driverType]);
	NSLog(@"[[trip toll] intValue]%@",[trip toll]);
	NSLog(@"[[trip purpose] intValue]%@",[trip purpose]);
	
	if([trip.purpose length] == 0)
	{
		[householdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		[householdmembersSegment setEnabled:NO];
		[nonHouseholdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		[nonHouseholdmembersSegment setEnabled:NO];
		[nonHouseholdMembers setEnabled:NO];
		[driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		[driverPassengerSegment setEnabled:NO];
		[tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		[tollSegment setEnabled:NO];
		
	}
	
	startTimeChange.text = [dateFormat stringFromDate: trip.startTime];
	endTimechange.text= [dateFormat stringFromDate: trip.stopTime];//lx 0401
//	NSLog(@"screen display time:%@",startTimeChange.text);
//	NSLog(@"screen display time:%@",endTimechange.text);
 
	NSDate * date1 = [dateFormat dateFromString:startTimeChange.text];
	NSDate * date2 = [dateFormat dateFromString:endTimechange.text];

	[ startDatePicker setDate:date1 animated:YES];
	[ endDatePicker setDate:date2 animated:YES];//lx 0405



	//	startTimeChange.text= [NSDateFormatter localizedStringFromDate:trip.startTime
	//														 dateStyle:NSDateFormatterShortStyle
	//														 timeStyle:NSDateFormatterMediumStyle];
	//	endTimechange.text=[NSDateFormatter localizedStringFromDate:trip.stopTime
	//														 dateStyle:NSDateFormatterShortStyle
	//														 timeStyle:NSDateFormatterMediumStyle];
	
	TravelModePickerViewDataSource *travelBy= (TravelModePickerViewDataSource *)[travelModePicker dataSource];
	for (int i= 0; i < [[travelBy travelModes] count]; i++) {
		if ([[trip travelBy] compare:[[travelBy travelModes] objectAtIndex:i]] == NSOrderedSame) {
			[travelModePicker selectRow:i inComponent:0 animated:NO];
		}
		
	}
	if([[trip isMembers]intValue]==0){
		[householdmembersSegment setSelectedSegmentIndex:1];//lx 0405
	}else if([[trip isMembers]intValue]==1){
		
		[householdmembersSegment setSelectedSegmentIndex:0];
	
	}else {
		[householdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	}
	
//	[householdmembersSegment setSelectedSegmentIndex:[[trip isMembers] intValue]];
	if([trip.isMembers intValue]<=0){
		numofhousholdMemberselected=0;
	}
	else
		numofhousholdMemberselected=[trip.members intValue];
	
	if([trip.members intValue]<=0){
		numofhousholdMemberselected=0;
	}
	else
		numofhousholdMemberselected=[trip.members intValue];
	
	
	if([trip.isnonMembers intValue]==0){
		[nonHouseholdmembersSegment setSelectedSegmentIndex:1];//lx 0405
	}else if([trip.isnonMembers intValue]==1){
		
		[nonHouseholdmembersSegment setSelectedSegmentIndex:0];
		
	}else {
		[nonHouseholdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	}
	
//	[nonHouseholdmembersSegment setSelectedSegmentIndex:[[trip isnonMembers] intValue]];
	
	if([trip.isnonMembers intValue]<=0){
		nonHouseholdMembers.text=@"0";
		nonHouseholdMembers.enabled= NO;
	}
	else
		nonHouseholdMembers.text=[trip.nonMembers stringValue];
	NSLog(@"nonHouseholdMembers.text is %@",nonHouseholdMembers.text);
	
	
	if ([[trip driverType] compare:@"Driver"] == NSOrderedSame) {
		[driverPassengerSegment setSelectedSegmentIndex:0];
	}else
	{
		if ([[trip driverType] compare:@"Passenger"] == NSOrderedSame) {
			[driverPassengerSegment setSelectedSegmentIndex:1];
		}else
		{
			[driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		}
	}
	
	
	if([trip.toll intValue]==0){
		[tollSegment setSelectedSegmentIndex:1];//lx 0405
	}else if([trip.toll intValue]==1){
		
		[tollSegment setSelectedSegmentIndex:0];
		
	}else {
		[tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
	}


	
	
	PickerViewDataSource *purpose= (PickerViewDataSource *)[activityPicker dataSource];
	for (int i= 0; i < [[purpose dataArray] count]; i++) {
		if ([[trip purpose] compare:[[purpose dataArray] objectAtIndex:i]] == NSOrderedSame) {
			[activityPicker selectRow:i inComponent:0 animated:NO];
		}
	}
	
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation

{
	
	// Return YES for supported orientations
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	//return [titleArray count];
	return 1;
}

//draw table cell

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = (UITableViewCell*)[tableView
											   
											   dequeueReusableCellWithIdentifier:CellIdentifier];
	if(cell == nil)
		
	{
		cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier];
		[[cell textLabel] setText:[dataArray1 objectAtIndex:indexPath.row]];
		cell.backgroundColor=[UIColor blackColor];//lx
		cell.textLabel.textColor=[UIColor whiteColor];//lx
		cell.accessibilityNavigationStyle=[UIColor whiteColor];//lx
		
		UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
		cell.accessoryView = switchView;
		
		if ([trip.isMembers  isEqual: @1]){
			DataTable.hidden = NO;
			NSString *familyMembers = [trip familyMembers];
			NSArray *familyMembersAdded = [familyMembers componentsSeparatedByString: @","];
			NSLog(@"familyMembersAdded are %@",familyMembersAdded);
			NSArray *arrayFamilyMembersAdded = [[NSMutableArray alloc] initWithArray:familyMembersAdded];
			for (int i = 0 ; i < arrayFamilyMembersAdded.count; i++) {
				//for (int j = 0 ;j < dataArray1.count; j++){
				if([[arrayFamilyMembersAdded objectAtIndex: i] caseInsensitiveCompare: [dataArray1 objectAtIndex:indexPath.row]] == NSOrderedSame){
					NSLog(@"%@", [arrayFamilyMembersAdded objectAtIndex: i]);
					NSLog(@"%@",[dataArray1 objectAtIndex:indexPath.row]);
					//[LIU0314] Add the async to UISwith, otherwise cannot turn it on.
					dispatch_async(dispatch_get_main_queue(), ^{
						[switchView setOn:YES animated:YES];
					});
				}else{
					[switchView setOn:NO animated:NO];
				}
				//}
			}
			
		}
		
		
		[switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
		NSLog(@"Cell is ....%@",cell);
		// Add a UISwitch to the accessory view.
		
		switchView.tag = indexPath.row;
		switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"menuItemSwitch"];
		[switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
	}
	
	return cell;
	
	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	CGPoint point=scrollView.contentOffset;
	cancel.frame= CGRectMake(0, point.y, cancel.bounds.size.width, 44 );
	
}
//lx


- (void)switchChanged:(id)sender {
	UISwitch *switchControl = sender;
	NSInteger *switchtag=switchControl.tag;
	if (switchControl.on == YES) {
		NSLog(@"initial numofhousholdMemberselected%d",numofhousholdMemberselected);
		housholdMemberselected = [housholdMemberselected stringByAppendingFormat:@"%@,", [dataArray1 objectAtIndex:switchtag]];
		numofhousholdMemberselected++;
		
		NSLog(@"housholdMemberselected........%@ and %d",housholdMemberselected,numofhousholdMemberselected);
	}else{
		NSLog(@"%d",numofhousholdMemberselected);
		
		
		NSString *string =[[dataArray1 objectAtIndex:switchtag] stringByAppendingString:@","];
		
		housholdMemberselected = [housholdMemberselected stringByReplacingOccurrencesOfString:string withString:@""];
		numofhousholdMemberselected=numofhousholdMemberselected -1;
		NSLog(@"housholdMemberselected........%@ and %d",housholdMemberselected,numofhousholdMemberselected);
		
	}
	NSLog(@"final numofhousholdMemberselected%d",numofhousholdMemberselected);
	
}
//update raw hight
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	
	return 40;
	
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [dataArray1 count];
}



- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
	NSLog(@"initWithNibNamed");
	if (self = [super initWithNibName:nibName bundle:nibBundle])
	{
		//NSLog(@"PickerViewController init");
		[self createCustomPicker];
		
		// picker defaults to top-most item => update the description
		[self pickerView:customPickerView didSelectRow:0 inComponent:0];
	}
	
	CGSize cg;
	cg.height= saveButton.frame.size.height + saveButton.frame.origin.y + 20;
	cg.width= saveButton.frame.size.width;
	[scrollView setContentSize:cg];
	
	tmDataSource= [[TravelModePickerViewDataSource alloc] init];
	travelModePicker.dataSource= tmDataSource;
	travelModePicker.delegate= tmDataSource;
	tmDataSource.parent= self;
	
	// hide conditional fields
	[parkingCost setHidden:YES];
	[tollCost setHidden:YES];
	[otherTripPurposeText setHidden:YES];
	
	return self;
}


- (id)initWithPurpose:(NSInteger)index
{
	if (self = [self init])
	{
		//NSLog(@"PickerViewController initWithPurpose: %d", index);
		
		// update the picker
		[customPickerView selectRow:index inComponent:0 animated:YES];
		
		// update the description
		[self pickerView:customPickerView didSelectRow:index inComponent:0];
	}
	return self;
}

-(void)viewWillAppear:(BOOL)animated{

	if([trip purpose].length == 0){
		[householdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		[nonHouseholdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		[driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		[tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		//lx 0325
	}
	
	
	
	if ([trip familyMembers] != nil && ![[trip familyMembers]  isEqual: @""] ){
		housholdMemberselected = [[trip familyMembers] stringByAppendingString:@","];
	}
	else{
		housholdMemberselected = @"";
	}
	
	
	NSLog(@"%@", housholdMemberselected);
	
}
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	
    
	self.title = NSLocalizedString(@"Trip Details", @"");
	//lx
	
	FloridaTripTrackerAppDelegate *delegatea= [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *managedContext = [delegatea managedObjectContext];
	//[LIU] obtain familymember info from db
	NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *user = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedContext];
	[userRequest setEntity:user];
	NSArray *userInUserTable = [managedContext executeFetchRequest:userRequest error:nil];
	User *person= [userInUserTable objectAtIndex:0];
	familyMember =person.familyMembers;
	NSArray * familyMembersload = [familyMember componentsSeparatedByString: @","];
	//[LIU0402]add predicate to filter out the self member
	NSArray * newFamilyMembersload = [familyMembersload filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"NOT(SELF beginswith %@)", person.name]];
	//	NSLog(@"New Family Members: %@",newFamilyMembersload);
	dataArray1 = [[NSMutableArray alloc] initWithArray:newFamilyMembersload];
	//	NSLog(@"Family Members: %@",dataArray1);
	//	NSLog(@"Person ID: %@",person.name);
	
	double tableheight=120;
	if ([dataArray1 count]>3) {
		tableheight=120;
	}
	else tableheight=40*[dataArray1 count];
	DataTable = [[UITableView alloc] initWithFrame:CGRectMake(8, 528, 340,tableheight)];
	//[LIU0407]Disable the selection animation in tableview.
	DataTable.allowsSelection = NO;
	[DataTable setDelegate:self];
	[DataTable setDataSource:self];
	[DataTable flashScrollIndicators];
	[self.view addSubview:DataTable];
	tripDescription.editable = NO;
	if (familyMember.length==0) {
		householdmembersSegment.enabled = NO;
	}
	[DataTable setHidden:YES];
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	//[LIU]
	if ([startTimeChange.text rangeOfString:@"M"].location == NSNotFound) {
		//24h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	} else {
		//12h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	}
	
	//[LIU0314] add date picker
	self.startDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
	[self.startDatePicker setDatePickerMode:UIDatePickerModeDateAndTime];
	[self.startDatePicker addTarget:self action:@selector(onStartDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
	self.startTimeChange.inputView = self.startDatePicker;
	
	
	self.endDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
	[self.endDatePicker setDatePickerMode:UIDatePickerModeDateAndTime];
	[self.endDatePicker addTarget:self action:@selector(onStopDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
	self.endTimechange.inputView = self.endDatePicker;
	//lx initialization
	//startTimeChange = [NSString stringFromDate: Trip.starTime];
	
	//[LIU] sample code for getting trip info from db
	//	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	//	FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
	//	NSManagedObjectContext *managedContext = [delegate managedObjectContext];
	//
	//	//[LIU] Obtain coords info
	//	NSEntityDescription *coordLocal = [NSEntityDescription entityForName:@"CoordLocal" inManagedObjectContext:managedContext];
	//	[request setEntity:coordLocal];
	//	NSInteger count = [managedContext countForFetchRequest:request error:nil];
	//	NSLog(@"Saved coords count and going to send:  = %ld", count);
	//	NSArray *coordInCoordLocal = [managedContext executeFetchRequest:request error:nil];
	//
	//	//[LIU] Obtain user's device number in user table
	//	NSEntityDescription *user = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedContext];
	//	[request setEntity:user];
	//	NSArray *userInUserTable = [managedContext executeFetchRequest:request error:nil];
	//	User *person= [userInUserTable objectAtIndex:0];
	//	NSString *deviceNum =person.deviceNum;
	//
	//	NSLog(@"Device number for sending coords: %@", deviceNum);
	
	//[NSDateFormatter localizedStringFromDate:[NSDate date]
	//dateStyle:NSDateFormatterShortStyle
	//timeStyle:NSDateFormatterFullStyle]
	
	
	activityPickerViewDataSource= [[PickerViewDataSource alloc] initWithArray:[[NSArray alloc] initWithObjects:
																			   @"",
																			   kTripPurposeHomeString,
																			   kTripPurposeWorkString,
																			   kTripPurposeWorkRelatedString,
																			   kTripPurposeCollegeString,
																			   kTripPurposeSchoolString,
																			   kTripPurposePersonalBizString,
																			   kTripPurposeMealString,
																			   kTripPurposeSocialString,
																			   kTripPurposeShoppingString,
																			   kTripPurposeRecreationString,
																			   kTripPurposeEntertainmentString,
																			   kTripPurposePickUpString,
																			   kTripPurposeOtherString,
																			   nil]];
	
	
	
	activityPicker.dataSource= activityPickerViewDataSource;
	activityPicker.delegate= activityPickerViewDataSource;
	
	[activityPicker setTintColor:[UIColor whiteColor]];
	//*lx
	
	
	//*lx
	
	
	tripDescription.font = [UIFont fontWithName:@"Arial" size:16];
	//[self.view addSubview:description];
	[fareCost setText:@""];
	[fareQuestion setHidden:YES];
	[fareCost setHidden:YES];
	[houseMembersdynamic setHidden:YES];
 
 //lx0314
	
	
}

//[LIU0314] Add datePicker
- (void)onStartDatePickerValueChanged:(UIDatePicker *)datePickerInput
{
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	//[LIU]
	if ([startTimeChange.text rangeOfString:@"M"].location == NSNotFound) {
		//24h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	} else {
		//12h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	}
	NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	[dateFormat setLocale:locale];
	self.startTimeChange.text = [dateFormat stringFromDate:datePickerInput.date];
}
- (void)onStopDatePickerValueChanged:(UIDatePicker *)datePickerInput
{
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	//[LIU]
	if ([endTimechange.text rangeOfString:@"M"].location == NSNotFound) {
		//24h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	} else {
		//12h
		[dateFormat setDateFormat:@"MM/dd/yyyy, hh:mm:ss a"];
	}
	self.endTimechange.text = [dateFormat stringFromDate:datePickerInput.date];
}


// called after the view controller's view is released and set to nil.
// For example, a memory warning which causes the view to be purged. Not invoked as a result of -dealloc.
// So release any properties that are loaded in viewDidLoad or can be recreated lazily.


- (void)viewDidUnload
{
	[super viewDidUnload];
	self.customPickerView = nil;
	self.customPickerDataSource = nil;
}

# pragma mark - UITextFieldDelegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
	[textField endEditing:YES];
	[textField resignFirstResponder];
	return YES;
}
//lx
- (IBAction)segmentedControlChanged:(id)sender
{
	
	
	if (householdmembersSegment.selectedSegmentIndex == 1)
	{
		NSLog(@"householdmembersSegment selects NO ");
		[DataTable setHidden:YES];

	}else {
		
		NSLog(@"householdmembersSegment selects YES ");
//		if(familyMember.length ==  0){
//			
//			[DataTable setHidden:YES];
//			
//		}else
			[DataTable setHidden:NO];}
	
	
}
//*lx

#pragma mark UIPickerViewDelegate


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	//lx 0401
 if (pickerView == travelModePicker) {
	 if ([trip.purpose length] == 0) {
		 [householdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		 [householdmembersSegment setEnabled:YES];
		 
		 [nonHouseholdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
		 [nonHouseholdmembersSegment setEnabled:YES];
		 
		 //		 nonHouseholdMembers.text = @"0";
		 if (row  == 7 || row == 8  ) {
			 [driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			 [driverPassengerSegment setEnabled:NO];
			 [tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			 [tollSegment setEnabled:NO];
		 }else
		 {
			 if (row > 2) {
				 
				 [driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 [driverPassengerSegment setEnabled:NO];
				 
				 [tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 [tollSegment setEnabled:YES];
			 }
			 
			 else {
				 [driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 [driverPassengerSegment setEnabled:YES];
				 
				 [tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 [tollSegment setEnabled:YES];
			 }
		 }
	 }else{
		 if (row  == 7 || row == 8 ) {
			 if([[trip isMembers]intValue]==0){
				 [householdmembersSegment setSelectedSegmentIndex:1];//lx 0405
				
			 }else if([[trip isMembers]intValue]==1){
				 
				 [householdmembersSegment setSelectedSegmentIndex:0];
				
			 }else{
				 [householdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			 }
			 
//			 [householdmembersSegment setSelectedSegmentIndex:[[trip isMembers] intValue]];
			 
			 if([[trip isnonMembers]intValue]==0){
				 [nonHouseholdmembersSegment setSelectedSegmentIndex:1];//lx 0405
				 
			 }else if([[trip isnonMembers]intValue]==1){
				 
				 [nonHouseholdmembersSegment setSelectedSegmentIndex:0];
				 
			 }else{
				 [nonHouseholdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			 }

//			 [nonHouseholdmembersSegment setSelectedSegmentIndex:[[trip isnonMembers] intValue]];
			 
			 [driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			 [driverPassengerSegment setEnabled:NO];
			 
			 [tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			 [tollSegment setEnabled:NO];
		 }else
		 {
			 if (row > 2 ) {
				 if([[trip isMembers]intValue]==0){
					 [householdmembersSegment setSelectedSegmentIndex:1];//lx 0405
					 
				 }else if([[trip isMembers]intValue]==1){
					 
					 [householdmembersSegment setSelectedSegmentIndex:0];
					 
				 }else{
					 [householdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 }
//				 [householdmembersSegment setSelectedSegmentIndex:[[trip isMembers] intValue]];
				 
				 
				 if([[trip isnonMembers]intValue]==0){
					 [nonHouseholdmembersSegment setSelectedSegmentIndex:1];//lx 0405
					 
				 }else if([[trip isnonMembers]intValue]==1){
					 
					 [nonHouseholdmembersSegment setSelectedSegmentIndex:0];
					 
				 }else{
					 [nonHouseholdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 }
				 
//				 [nonHouseholdmembersSegment setSelectedSegmentIndex:[[trip isnonMembers] intValue]];
				 
				 [driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 [driverPassengerSegment setEnabled:NO];
				 
				 if([[trip toll]intValue]==0){
					 [tollSegment setSelectedSegmentIndex:1];//lx 0405
					 
				 }else if([[trip toll]intValue]==1){
					 
					 [tollSegment setSelectedSegmentIndex:0];
					 
				 }else{
					 [tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 }
				 
//				 [tollSegment setSelectedSegmentIndex:[[trip toll] intValue]];
				 [tollSegment setEnabled:YES];

			 }
			 
			 else {
				 if([[trip isMembers]intValue]==0){
					 [householdmembersSegment setSelectedSegmentIndex:1];//lx 0405
					 
				 }else if([[trip isMembers]intValue]==1){
					 
					 [householdmembersSegment setSelectedSegmentIndex:0];
					 
				 }else{
					 [householdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 }
//				 [householdmembersSegment setSelectedSegmentIndex:[[trip isMembers] intValue]];
				 
				 if([[trip isnonMembers]intValue]==0){
					 [nonHouseholdmembersSegment setSelectedSegmentIndex:1];//lx 0405
					 
				 }else if([[trip isnonMembers]intValue]==1){
					 
					 [nonHouseholdmembersSegment setSelectedSegmentIndex:0];
					 
				 }else{
					 [nonHouseholdmembersSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 }
				 
//				 [nonHouseholdmembersSegment setSelectedSegmentIndex:[[trip isnonMembers] intValue]];
				 //driverType
				 if ([[trip driverType] compare:@"Driver"] == NSOrderedSame) {
					 [driverPassengerSegment setSelectedSegmentIndex:0];
				 }else
				 {
					 if ([[trip driverType] compare:@"Passenger"] == NSOrderedSame) {
						 [driverPassengerSegment setSelectedSegmentIndex:1];
					 }else
					 {
						 [driverPassengerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
					 }
				 }
				 [driverPassengerSegment setEnabled:YES];
				 
				 if([[trip toll]intValue]==0){
					 [tollSegment setSelectedSegmentIndex:1];//lx 0405
					 
				 }else if([[trip toll]intValue]==1){
					 
					 [tollSegment setSelectedSegmentIndex:0];
					 
				 }else{
					 [tollSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
				 }
				 [tollSegment setEnabled:YES];
			 }
		 }
	 
	 }
	 
	 
	 
	 
 }//*lx
	if (pickerView.tag == 1) {
		switch (row) {
			case 1:
				[fareQuestion setHidden:NO];
				[fareCost setHidden:NO];
				break;
			case 0:
			case 2:
			case 3:
			case 4:
			case 5:
			case 6:
			case 7:
			default:
				[fareCost setText:@""];
				[fareQuestion setHidden:YES];
				[fareCost setHidden:YES];
				break;
		}
	}
	else {
		switch (row) {
				
			case 0:
				tripDescription.text = kDescHome;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 1:
				tripDescription.text = kDescWork;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 2:
				tripDescription.text = kDescRecreation;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 3:
				tripDescription.text = kDescShopping;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 4:
				tripDescription.text = kDescSocial;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 5:
				tripDescription.text = kDescMeal;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 6:
				tripDescription.text = kDescSchool;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 7:
				tripDescription.text = kDescCollege;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 8:
				tripDescription.text = kDescDaycare;
				[otherTripPurposeText setText:@""];
				[otherTripPurposeText setHidden:YES];
				break;
			case 9:
			default:
				tripDescription.text = kDescOther;
				[otherTripPurposeText setHidden:NO];
				break;
		}
	}
}

#pragma mark UITextFieldDelegate Functions
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	
	UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarStyleBlack target:textField action:@selector(resignFirstResponder)];
	[barButton setTitle:@"Done"];
	UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	toolbar.items = [NSArray arrayWithObjects: flex, barButton, nil];
	
	[toolbar setBarStyle:UIBarStyleBlack];
	
	[textField setInputAccessoryView:toolbar];
	
	//oldPosition= scrollView.contentOffset;
	//[[self scrollView] setContentOffset:CGPointMake(0, textField.frame.origin.y) animated:YES];
	
	return YES;
}
@end

