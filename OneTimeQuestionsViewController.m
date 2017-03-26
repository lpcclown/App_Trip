//
//  OneTimeQuestionsViewController.m
//  FloridaTripTracker
//
//  Created by Benaiah Pitts on 12/29/14.
//
//

#import "OneTimeQuestionsViewController.h"
#import "PickerViewDataSource.h"
#import "TravelModePickerViewDataSource.h"
#import "FloridaTripTrackerAppDelegate.h"
#import "User.h"
#import "constants.h"
#import "LoadingView.h"
#import "ServerInteract.h"

@class User;

@interface OneTimeQuestionsViewController ()

@end

@implementation OneTimeQuestionsViewController

@synthesize  gender, studentStatusPicker, studentStatusLabel, workTripNumber, workTripStepper, disabledPassSegment, fiveMonthSegment, fullTimeSegment, homemakerSegment, licenseSegment, partTimeSegment, retiredSegment, selfEmployedSegment, studentSegment, transitPassSegment, unemployedSegment, workAtHomeSegment;
@synthesize scrollView;
@synthesize managedContext;

//lx
@synthesize userinfoid,reuserinfoid,initialinfo,genderinfo,ageinfo,familymembersinfo,driverlicense,deviceNum,namePicker,householdID,rehouseholdID,submitID;
@synthesize submit,q1,q2,q3,q4,q5,q6,modifylabel,confirmlabel,confirmyes,confirmno,modify;//lxx

@synthesize ageinfoDataSource,namePickerDataSource, memberArray;//lxx


//*lx

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self= [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	/*CGSize cg;
	 UILabel *label= (UILabel *)[self.view viewWithTag:-1];
	 cg.height= label.frame.size.height + label.frame.origin.y + 20;
	 cg.width= scrollView.frame.size.width;
	 [scrollView setContentSize:cg];
	 [scrollView setFrame:[[UIScreen mainScreen] bounds]];
	 NSLog(@"init: content height %f, frame height: %f",cg.height,scrollView.frame.size.height);*/
	
	return self;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	//lx UIView *view= (UIView *)[self.view viewWithTag:-1];
	//lx cg.height= (view.frame.size.height * 6) + view.frame.origin.y + 20;
	//lx cg.width= scrollView.frame.size.width;
	//lx [scrollView setContentSize:cg];
	[scrollView setFrame:[[UIScreen mainScreen] bounds]];
	[[self view] layoutSubviews];
}

#pragma mark UIViewController overrides

- (void)viewDidLoad {
	[super viewDidLoad];
	self.scrollView.contentSize = CGSizeMake(320, 500);
	// Do any additional setup after loading the view from its nib.
	UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FDOT"]]];
	self.navigationItem.rightBarButtonItem = item;
	
	
	/*[scrollView setFrame:[[UIScreen mainScreen] bounds]];
	 CGSize cg;
	 UILabel *label= (UILabel *)[self.view viewWithTag:-1];
	 cg.height= label.frame.size.height + label.frame.origin.y + 20;
	 cg.width= scrollView.frame.size.width;
	 [scrollView setContentSize:cg];
	 NSLog(@"content height %f, frame height: %f",cg.height,scrollView.frame.size.height);*/
	//lx
	ageinfoDataSource= [[PickerViewDataSource alloc] initWithArray:[[NSArray alloc] initWithObjects:@"0-4", @"5-15", @"16-21", @"22-49", @"50-64", @"65 or older", nil]];
	ageinfoDataSource.parent= self;
	ageinfo.dataSource = ageinfoDataSource;
	ageinfo.delegate = ageinfoDataSource;
	
	//the time to enter user id
	
	namePicker.hidden = YES;//lxx
	userinfoid.hidden = YES;//lxx
	reuserinfoid.hidden = YES;//lxx
	
	submit.hidden = YES;//lxx
	
	
	initialinfo.hidden = YES;
	genderinfo.hidden = YES;
	ageinfo.hidden = YES;
	familymembersinfo.hidden = YES;
	driverlicense.hidden = YES;
	q2.hidden = YES;
	q3.hidden = YES;
	q4.hidden = YES;
	q5.hidden = YES;
	q6.hidden = YES;
	modifylabel.hidden = YES;
	confirmlabel.hidden = YES;
	confirmyes.hidden = YES;
	confirmno.hidden = YES;
	modify.hidden = YES;
	
	[studentStatusLabel setTextColor:[UIColor grayColor]];
	[studentStatusPicker setUserInteractionEnabled:NO];
	[studentStatusPicker setTintColor:[UIColor whiteColor]];
	
	FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
	managedContext= [delegate managedObjectContext];
	
	if ([delegate hasUserInfoBeenSaved]) {
		self.scrollView.contentSize = CGSizeMake(320, 920);
		[self loadUserSettings];
		[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
		self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
		/*CGSize cg;
		 UILabel *label= (UILabel *)[self.view viewWithTag:-1];
		 cg.height= label.frame.size.height + label.frame.origin.y + 20;
		 cg.width= scrollView.frame.size.width;
		 NSLog(@"frame size: %f",cg.height);
		 [scrollView setContentSize:cg];*/
	}
	else
		[self setTitle:@"My Trip Diary"];
}

#pragma mark UIPickerViewDelegate



- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	if (pickerView == ageinfo) {//lx remember change it into ageinfo
		if (row < 2) {
			[fullTimeSegment setSelectedSegmentIndex:0];
			[partTimeSegment setSelectedSegmentIndex:0];
			[fiveMonthSegment setSelectedSegmentIndex:0];
			[unemployedSegment setSelectedSegmentIndex:0];
			[retiredSegment setSelectedSegmentIndex:0];
			[workAtHomeSegment setSelectedSegmentIndex:0];
			[homemakerSegment setSelectedSegmentIndex:0];
			[selfEmployedSegment setSelectedSegmentIndex:0];
			[licenseSegment setSelectedSegmentIndex:0];
			[driverlicense setSelectedSegmentIndex:0];//lx
			[fullTimeSegment setEnabled:NO];
			[partTimeSegment setEnabled:NO];
			[fiveMonthSegment setEnabled:NO];
			[unemployedSegment setEnabled:NO];
			[retiredSegment setEnabled:NO];
			[workAtHomeSegment setEnabled:NO];
			[homemakerSegment setEnabled:NO];
			[selfEmployedSegment setEnabled:NO];
			[licenseSegment setEnabled:NO];
			[driverlicense setEnabled:NO];//lx
			
		}
		
		else {
			[fullTimeSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[partTimeSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[fiveMonthSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[unemployedSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[retiredSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[workAtHomeSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[homemakerSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[selfEmployedSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[licenseSegment setSelectedSegmentIndex:UISegmentedControlNoSegment];
			[driverlicense setSelectedSegmentIndex:UISegmentedControlNoSegment];//lx
			[fullTimeSegment setEnabled:YES];
			[partTimeSegment setEnabled:YES];
			[fiveMonthSegment setEnabled:YES];
			[unemployedSegment setEnabled:YES];
			[retiredSegment setEnabled:YES];
			[workAtHomeSegment setEnabled:YES];
			[homemakerSegment setEnabled:YES];
			[selfEmployedSegment setEnabled:YES];
			[licenseSegment setEnabled:YES];
			[driverlicense setEnabled:YES];//lx
		}
	}
}
- (IBAction)submitIDButtonTapped:(id)sender {
	
	NSString *errors= @"";
	
	NSString *householdIdinput = [householdID text];
	NSString *rehouseholdIdinput = [rehouseholdID text];
	NSData *responseData = [ServerInteract sendRequest:householdIdinput toURLAddress:KGetMembers];
	if (responseData != nil){
		NSDictionary *readableJsonText = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
		NSError *errorJson=nil;
		NSMutableArray *memberNameInfo= [NSMutableArray new];
		if ([readableJsonText count] != 0){
			memberArray = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&errorJson];
			
			//[LIU] Iterate members in the feedback info
			NSEnumerator *e = [memberArray objectEnumerator];
			id object;
			while (object = [e nextObject]) {
				NSDictionary *singleMemberInfo = object;
				[memberNameInfo addObject:[singleMemberInfo objectForKey:@"name"]];//used for pick view
			}
		}
		
		if ([householdIdinput isEqualToString: rehouseholdIdinput ]) {
			
			
			if (householdIdinput.length > 0 && [readableJsonText count] != 0) {
				
				householdID.text = householdIdinput;
				rehouseholdID.text = rehouseholdIdinput;
				
				householdID.enabled = NO;
				rehouseholdID.enabled = NO;
				householdID.textColor = [UIColor grayColor];
				rehouseholdID.textColor = [UIColor grayColor];
				submitID.hidden = YES;
				namePicker.hidden = NO;
				
				submit.hidden = NO;//lxx
				
				
				namePickerDataSource= [[PickerViewDataSource alloc] initWithArray:memberNameInfo];
				namePickerDataSource.parent= self;//lx
				namePicker.dataSource= namePickerDataSource;
				namePicker.delegate= namePickerDataSource;
				
				
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Household ID not found, please try again."
																message:errors
															   delegate:self
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
				
			}
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Household ID not match!"
															message:errors
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	}else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInternetError
														message:errors
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}	
}//lx

- (IBAction)submitButtonTapped:(id)sender {
	self.scrollView.contentSize = CGSizeMake(320, 1100);
	//NSString *selectedMemberName = @"Man";
	NSString *selectedMemberName = [[namePicker delegate] pickerView:namePicker titleForRow:[namePicker selectedRowInComponent:0] forComponent:0];
	
	
	for (id singleMemberInfo in memberArray) {
		if ([selectedMemberName isEqualToString:[singleMemberInfo objectForKey:@"name"]]){
			NSString * userIdLoad = singleMemberInfo[@"userid"];
			//[LIU] still need to use getUser service to obtain detailed info, the getMembers service is only available for name and userid, not for others.
			NSData *responseData = [ServerInteract sendRequest:userIdLoad toURLAddress:kGetUser];
			
			NSDictionary *readableJsonText = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
			
			//[LIU] change readableJsonText to singleMemberInfo, once we only need getMembers service
			userinfoid.text =userIdLoad;
			NSString * initialload = readableJsonText[@"initial"];
			NSArray * familyMembersload = readableJsonText[@"familyMembers"];
			NSString * deviceNumload = readableJsonText[@"deviceNum"];
			NSString * driverLicload = readableJsonText[@"driverLic"];
			NSString * genderload = readableJsonText[@"gender"];
			NSString * ageload = readableJsonText[@"age"];
			
			//get familymembers
			
			NSString * familyMembers = @"";
			NSString * familystring = @"";
			//if (familyMembers != nil && ![familyMembers isEqual: @""]){
			for(NSArray *members in familyMembersload){
				NSLog(@"Array:%@",members);
				familystring = [familystring stringByAppendingFormat:@"%@,", members];
			}
			//}
			//if ( [familystring length] != 0){
			familyMembers = [familystring substringToIndex:[familystring length]-1];
			//	NSLog(@"familyMemebers:%@", familyMembers);
			//}
			
			
			
			if (userIdLoad.length > 0 && userIdLoad != nil && ![userIdLoad isEqualToString: @""]) {
				//errors= [errors stringByAppendingString:@"Please enter the number of household members.\n"];
				
				if ( (NSNull *)initialload == [NSNull null]){
					initialinfo.text = @"";
				}
				else
				{initialinfo.text = initialload;}
				familymembersinfo.text = familyMembers;
				
				
				if ([genderload compare:@"M"] == NSOrderedSame) {
					[genderinfo setSelectedSegmentIndex:0];
				}
				else
					[genderinfo setSelectedSegmentIndex:1];
				
				
				PickerViewDataSource *age= (PickerViewDataSource *)[ageinfo dataSource];
				for (int i= 0; i < [[age dataArray] count]; i++) {
					if ([ageload compare:[[age dataArray] objectAtIndex:i]] == NSOrderedSame) {
						[ageinfo selectRow:i inComponent:0 animated:NO];
					}
				}
				if (driverLicload != nil && (NSNull *)driverLicload != [NSNull null]){
					if ([driverLicload compare:@"0"] == NSOrderedSame) {
						[driverlicense setSelectedSegmentIndex:0];
					}
					else
						[driverlicense setSelectedSegmentIndex:1];
				}
				if (deviceNumload != Nil && (NSNull *)deviceNumload != [NSNull null]) {
					deviceNum= deviceNumload;
				} else {
					FloridaTripTrackerAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
					//[LIU]
					//deviceNum = delegate.uniqueIDHash;
					deviceNum= [NSString stringWithFormat: @"appledeviceid-%@", delegate.uniqueIDHash];
					
				}
				NSLog(@"initialize deviceNum:%@",deviceNum);
				//show user information to confirm
				submit.hidden = YES;
				confirmlabel.hidden = YES;
				modify.hidden = YES;
				
				initialinfo.hidden = NO;
				genderinfo.hidden = NO;
				ageinfo.hidden = NO;
				familymembersinfo.hidden = NO;
				driverlicense.hidden = NO;
				q2.hidden = NO;
				q3.hidden = NO;
				q4.hidden = NO;
				q5.hidden = NO;
				q6.hidden = NO;
				modifylabel.hidden = NO;
				confirmlabel.hidden = NO;
				confirmyes.hidden = NO;
				confirmno.hidden = NO;
				modify.hidden = YES;
				
				userinfoid.enabled = NO;
				reuserinfoid.enabled = NO;
				initialinfo.enabled = NO;
				familymembersinfo.editable = NO;
				genderinfo.enabled = NO;
				[ageinfo setUserInteractionEnabled:NO];
				driverlicense.enabled = NO;
				q3.enabled = NO;
				
				userinfoid.textColor = [UIColor grayColor];
				reuserinfoid.textColor = [UIColor grayColor];
				initialinfo.textColor = [UIColor grayColor];
				familymembersinfo.textColor = [UIColor grayColor];
				
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"User ID not found, please try again."
																message:nil
															   delegate:self
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
				
			}
		}
		
	}}
//confirmyes
- (IBAction)confirmyesButtonTapped:(id)sender{
	
	userinfoid.enabled = NO;
	userinfoid.textColor = [UIColor grayColor];
	
	reuserinfoid.enabled = NO;
	reuserinfoid.textColor = [UIColor grayColor];
	
	initialinfo.enabled = YES;
	initialinfo.textColor = [UIColor whiteColor];
	
	familymembersinfo.editable = NO;
	familymembersinfo.textColor = [UIColor grayColor];
	q3.textColor = [UIColor grayColor];
	
	genderinfo.enabled = YES;
	[ageinfo setUserInteractionEnabled:YES];
	[driverlicense setEnabled:YES];
	
	modifylabel.hidden = YES;
	confirmlabel.hidden = YES;
	confirmyes.hidden = YES;
	confirmno.hidden = YES;
	modify.hidden = NO;
	NSLog(@"confirm后deviceNUM:%@", deviceNum);
	User *user= [self getNewOrExistingUser];
	NSLog(@"user info:%@",user);
	
	if ( user != nil )
	{
		NSString *genderString =([genderinfo selectedSegmentIndex] == 0) ? (@"M") : (@"F");
		NSString *ageString = [[ageinfo delegate] pickerView:ageinfo titleForRow:[ageinfo selectedRowInComponent:0] forComponent:0];
		NSString *driverLicString = ([driverlicense selectedSegmentIndex] == 0) ? (@"0") : (@"1");
		NSNumber *driverLicNumber = ([driverlicense selectedSegmentIndex] == 0) ? (@0) : (@1);
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:userinfoid.text,@"userid",deviceNum,@"deviceNum",@"",@"status",initialinfo.text,@"initial",genderString,@"gender",ageString,@"age",driverLicNumber,@"driverLic",@"",@"familyMembers", nil];
		
		NSData *responseData = [ServerInteract sendRequest:userInfo toURLAddress:kUpdateUserInfo];
		
		NSDictionary *serverFeedback= [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
		
		NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
		
		[user setUserid:[userinfoid text]];
		[user setHouseholdID:[householdID text]];
		[user setName:[[namePicker delegate] pickerView:namePicker titleForRow:[namePicker selectedRowInComponent:0] forComponent:0]];
		[user setInitial:[initialinfo text]];
		[user setFamilyMembers:[familymembersinfo text]];
		[user setGender: genderString];
		[user setAge:ageString];
		[user setDriverlicense: driverLicString];
		[user setDeviceNum:deviceNum];
		
		if ([serverFeedbackString hasSuffix:@"was saved"]) {
			[user setSuccTag:@1];//[LIU] 1 means succeed, 0 means failed
			
			[managedContext save:nil];
			
			FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
			[delegate createMainView];
			
			NSLog(@"Update user info succeed DB tag: succ_Tag:1");
			
		}
		
		else {
			[user setSuccTag:@0];
			NSLog(@"Update user info failed DB tag: succ_Tag:0");
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Information To Server Failed!"
															message:nil
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	}
	else{
		[user setSuccTag:@0];
		NSLog(@"Update user info failed DB tag: succ_Tag:0");
	}
}
//confirmno
- (IBAction)confirmnoButtonTapped:(id)sender{
	userinfoid.enabled = YES;
	userinfoid.textColor = [UIColor whiteColor];
	reuserinfoid.enabled = YES;
	reuserinfoid.textColor = [UIColor whiteColor];
	initialinfo.enabled = YES;
	
	initialinfo.hidden = YES;
	genderinfo.hidden = YES;
	ageinfo.hidden = YES;
	familymembersinfo.hidden = YES;
	driverlicense.hidden = YES;
	q2.hidden = YES;
	q3.hidden = YES;
	q4.hidden = YES;
	q5.hidden = YES;
	q6.hidden = YES;
	modifylabel.hidden = YES;
	confirmlabel.hidden = YES;
	confirmyes.hidden = YES;
	confirmno.hidden = YES;
	modify.hidden = YES;
	submit.hidden = NO;
}

//modify the user information
- (IBAction)modifyButtonTapped:(id)sender{
	
	//LoadingView *loading = [LoadingView loadingViewInView:self.view];
	//loading.tag = 910;
	//loading		= [LoadingView loadingViewInView:self.parentViewController.view];
	//[self.view addSubview:loading];
	
	NSLog(@"after modification deviceNum%@", deviceNum);
	
	confirmlabel.hidden = YES;
	confirmyes.hidden = YES;
	confirmno.hidden = YES;
	submit.hidden = YES;
	
	
	User *user= [self getNewOrExistingUser];
	NSLog(@"user info:%@",user);
	
	if ( user != nil )
	{
		NSString *genderString =([genderinfo selectedSegmentIndex] == 0) ? (@"M") : (@"F");
		NSString *ageString = [[ageinfo delegate] pickerView:ageinfo titleForRow:[ageinfo selectedRowInComponent:0] forComponent:0];
		NSString *driverLicString = ([driverlicense selectedSegmentIndex] == 0) ? (@"0") : (@"1");
		NSNumber *driverLicNumber = ([driverlicense selectedSegmentIndex] == 0) ? (@0) : (@1);
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:userinfoid.text,@"userid",deviceNum,@"deviceNum",@"",@"status",initialinfo.text,@"initial",genderString,@"gender",ageString,@"age",driverLicNumber,@"driverLic",@"",@"familyMembers", nil];
		
		NSData *responseData = [ServerInteract sendRequest:userInfo toURLAddress:kUpdateUserInfo];
		
		if (responseData != nil){
			NSDictionary *serverFeedback= [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
			NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
			
			[user setUserid:[userinfoid text]];
			[user setHouseholdID:[householdID text]];
			[user setName:[[namePicker delegate] pickerView:namePicker titleForRow:[namePicker selectedRowInComponent:0] forComponent:0]];
			[user setInitial:[initialinfo text]];
			[user setFamilyMembers:[familymembersinfo text]];
			[user setGender: genderString];
			[user setAge:ageString];
			[user setDriverlicense: driverLicString];
			[user setDeviceNum:deviceNum];
			
			if ([serverFeedbackString hasSuffix:@"was saved"]) {
				[user setSuccTag:@1];//[LIU] 1 means succeed, 0 means failed
				
				NSLog(@"Update user info failed DB tag: succ_Tag:1");
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update User Information To Server Succeed!"
																message:nil
															   delegate:self
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
				[managedContext save:nil];
				
				FloridaTripTrackerAppDelegate *delegate= [[UIApplication sharedApplication] delegate];
				[delegate createMainView];
				
				NSLog(@"Update user info succeed DB tag: succ_Tag:1");
			}
			else {
				[user setSuccTag:@0];
				NSLog(@"Update user info failed DB tag: succ_Tag:0");
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update User Information To Server Failed!"
																message:nil
															   delegate:self
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:nil];
				[alert show];
			}
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kInternetError
															message:nil
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	}
	else{
		[user setSuccTag:@0];
		NSLog(@"Update user info failed DB tag: succ_Tag:0");
	}
}

- (IBAction)backgroundTouched:(id)sender {
	[userinfoid resignFirstResponder];
	[reuserinfoid resignFirstResponder];
	[initialinfo resignFirstResponder];
	[familymembersinfo resignFirstResponder];
	[genderinfo resignFirstResponder];
	[ageinfo resignFirstResponder];
	[driverlicense resignFirstResponder];
	
}

//lx
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

- (void)loadUserSettings {
	
	namePicker.hidden = YES;
	q2.frame = CGRectMake(8, 190, 568, 44);
	
	initialinfo.frame = CGRectMake(8, 242, 568, 30 );
	
	q3.frame = CGRectMake(8, 280, 568, 44 );
	
	familymembersinfo.frame = CGRectMake(8, 280+38, 568,30);
	
	q4.frame = CGRectMake(8, 280+38+52, 568,44);
	
	genderinfo.frame = CGRectMake(8,280+38+52+38, 568, 28);
	
	q5.frame = CGRectMake(8, 280+38+52+38+52, 568, 44);
	
	ageinfo.frame = CGRectMake(8,  280+38+52+38+52+38, 568, 162);
	
	q6.frame = CGRectMake(8,  280+38+52+38+52+38+52+162-44, 568, 44);
	
	driverlicense.frame = CGRectMake(8, 280+38+52+38+52+38+52+162-44+38, 568, 28);
	modify.frame = CGRectMake(8, 280+38+52+38+52+38+52+162-44+38+52, 568, 44);
	
	
	namePicker.hidden= YES;
	initialinfo.hidden = NO;
	genderinfo.hidden = NO;
	ageinfo.hidden = NO;
	familymembersinfo.hidden = NO;
	driverlicense.hidden = NO;
	q2.hidden = NO;
	q3.hidden = NO;
	q4.hidden = NO;
	q5.hidden = NO;
	q6.hidden = NO;
	modify.hidden = NO;
	confirmlabel.hidden = YES;
	confirmyes.hidden = YES;
	confirmno.hidden = YES;
	submit.hidden = YES;
	submitID.hidden = YES;
	
	userinfoid.enabled = NO;
	userinfoid.textColor = [UIColor grayColor];
	
	reuserinfoid.enabled = NO;
	reuserinfoid.textColor = [UIColor grayColor];
	
	householdID.enabled = NO;
	householdID.textColor = [UIColor grayColor];
	
	rehouseholdID.enabled = NO;
	rehouseholdID.textColor = [UIColor grayColor];
	
	familymembersinfo.editable = NO;
	familymembersinfo.textColor = [UIColor grayColor];
	q3.textColor = [UIColor grayColor];
	
	genderinfo.enabled = YES;
	[ageinfo setUserInteractionEnabled:YES];
	[driverlicense setEnabled:YES];
	
	
	
	User *user= [self getNewOrExistingUser];
	//NSLog(@"Latest user info：%@",user);
	
	[fullTimeSegment setSelectedSegmentIndex:[[user empFullTime] intValue]];
	[homemakerSegment setSelectedSegmentIndex:[[user empHomemaker] intValue]];
	[fiveMonthSegment setSelectedSegmentIndex:[[user empLess5Months]intValue]];
	[partTimeSegment setSelectedSegmentIndex:[[user empPartTime]intValue]];
	[retiredSegment setSelectedSegmentIndex:[[user empRetired]intValue]];
	[selfEmployedSegment setSelectedSegmentIndex:[[user empSelfEmployed]intValue]];
	[unemployedSegment setSelectedSegmentIndex:[[user empUnemployed]intValue]];
	[workAtHomeSegment setSelectedSegmentIndex:[[user empWorkAtHome]intValue]];
	[disabledPassSegment setSelectedSegmentIndex:[[user hasADisabledParkingPass]intValue]];
	[licenseSegment setSelectedSegmentIndex:[[user hasADriversLicense]intValue]];
	[transitPassSegment setSelectedSegmentIndex:[[user hasATransitPass]intValue]];
	[studentSegment setSelectedSegmentIndex:[[user isAStudent]intValue]];
	
	[workTripNumber setText:[[user numWorkTrips] stringValue]];
	q1.text=@"1.The UserID assigned to you";
	householdID.text= user.userid;
	rehouseholdID.text= user.userid;	//lx
	userinfoid.text=user.userid;
	reuserinfoid.text=user.userid;
	initialinfo.text=user.initial;
	familymembersinfo.text=user.familyMembers;
	deviceNum = user.deviceNum;
	
	PickerViewDataSource *age= (PickerViewDataSource *)[ageinfo dataSource];
	for (int i= 0; i < [[age dataArray] count]; i++) {
		if ([[user age] compare:[[age dataArray] objectAtIndex:i]] == NSOrderedSame) {
			[ageinfo selectRow:i inComponent:0 animated:NO];
		}
	}
	
	//[initialinfo setText:[[user initial] stringValue]];
	if ([[user gender] compare:@"M"] == NSOrderedSame) {
		[genderinfo setSelectedSegmentIndex:0];	}
	else
		[genderinfo setSelectedSegmentIndex:1];
	[driverlicense setSelectedSegmentIndex:[[user driverlicense]intValue]];
	
	
	//*lx
	
	//	NSLog(@"test.............gender%@", [user gender] );
	//	NSLog(@"test.............deviceNum%@", [user deviceNum] );
	
	if ([[user gender] compare:@"M"] == NSOrderedSame) {
		[gender setSelectedSegmentIndex:0];	}
	else
		[gender setSelectedSegmentIndex:1];
	
	
	
	PickerViewDataSource *ageDataSource= (PickerViewDataSource *)[ageinfo dataSource];
	for (int i= 0; i < [[ageDataSource dataArray] count]; i++) {
		if ([[user age] compare:[[ageDataSource dataArray] objectAtIndex:i]] == NSOrderedSame) {
			[ageinfo selectRow:i inComponent:0 animated:NO];
		}
	}
	
	NSString *genderString =([genderinfo selectedSegmentIndex] == 0) ? (@"M") : (@"F");
	NSString *ageString = [[ageinfo delegate] pickerView:ageinfo titleForRow:[ageinfo selectedRowInComponent:0] forComponent:0];
	NSNumber *driverLicNumber = ([driverlicense selectedSegmentIndex] == 0) ? (@0) : (@1);
	if (user.succTag == 0) {//lx
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:userinfoid.text,@"userid",deviceNum,@"deviceNum",@"",@"status",initialinfo.text,@"initial",genderString,@"gender",ageString,@"age",driverLicNumber,@"driverLic",@"",@"familyMembers", nil];
		
		NSData *responseData = [ServerInteract sendRequest:userInfo toURLAddress:kUpdateUserInfo];
		
		NSDictionary *serverFeedback= [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
		
		NSString *serverFeedbackString = [serverFeedback objectForKey:@"Result"];
		
		if ([serverFeedbackString hasSuffix:@"was saved"]) {
			[user setSuccTag:@1];//[LIU] 1 means succeed, 0 means failed
			
			NSLog(@"Re-Update user info succeed DB tag: succ_Tag:1");
		}else {
			[user setSuccTag:@0];
			NSLog(@"Re-Update user info failed DB tag: succ_Tag:0");
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update Information To Server Failed!"
															message:nil
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
		
	}//*lx
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

//lx
- (IBAction)ageSegmentChanged:(id)sender {
	
	if ([ageinfo selectedRowInComponent:0] == 1) {
		[studentStatusLabel setTextColor:[UIColor blackColor]];
		[studentStatusPicker setUserInteractionEnabled:YES];
		PickerViewDataSource *ds= (PickerViewDataSource *)[studentStatusPicker delegate];//lx explain how to set picker.
		[ds setTextColor:[UIColor whiteColor]];
	}
	else {
		[studentStatusLabel setTextColor:[UIColor grayColor]];
		[studentStatusPicker setUserInteractionEnabled:NO];
		PickerViewDataSource *ds= (PickerViewDataSource *)[studentStatusPicker delegate];
		[ds setTextColor:[UIColor grayColor]];
	}
}
//*lx

- (User *)getNewOrExistingUser {
	User *person;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedContext];
	[request setEntity:entity];
	NSError *error;
	NSInteger count = [managedContext countForFetchRequest:request error:&error];
	NSLog(@"saved user count  = %ld", count);
	if ( count == 0 )
	{
		// create an empty User entity
		person= [self createUser];
	}
	
	NSMutableArray *mutableFetchResults = [[managedContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
		NSLog(@"no saved user");
		if ( error != nil )
			NSLog(@"OneTimeQuestion saveButtonTapped fetch error %@, %@", error, [error localizedDescription]);
	}
	
	person= [mutableFetchResults objectAtIndex:0];
	return person;
	
	
}

- (User *)createUser
{
	// Create and configure a new instance of the User entity
	User *noob = (User *)[NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:managedContext];
	
	NSError *error;
	if (![managedContext save:&error]) {
		// Handle the error.
		NSLog(@"createUser error %@, %@", error, [error localizedDescription]);
	}
	
	return noob;
}
@end
