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
//	PickerViewController.h
//	CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/28/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>

#import <UIKit/UIKit.h>
#import "CustomPickerDataSource.h"
#import "TripPurposeDelegate.h"
#import "PickerViewDataSource.h"
#import "OneTimeQuestionsViewController.h"
@class TravelModePickerViewDataSource;
@class PickerViewDataSource;//lx
@class Trip;//lx
@class User;//lx

@interface TripQuestionsViewController : UIViewController <UIPickerViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>
{
	id <TripPurposeDelegate> delegate;
	UIPickerView			*customPickerView;
	CustomPickerDataSource	*customPickerDataSource;
	
	UITableView *DataTable;
	
	NSMutableArray *dataArray1;

	
	//UITextView				*description;
}


@property (nonatomic, strong) id <TripPurposeDelegate> delegate;
@property (nonatomic, strong) IBOutlet UIPickerView *customPickerView;
@property (nonatomic, strong) CustomPickerDataSource *customPickerDataSource;

@property (weak, nonatomic) IBOutlet UITextView *tripDescription;
//@property (nonatomic, strong) UITextView *description;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *otherTripPurposeText;
@property (weak, nonatomic) IBOutlet UIPickerView *travelModePicker;
@property (weak, nonatomic) IBOutlet UITextField *householdMembers;
@property (weak, nonatomic) IBOutlet UITextField *nonHouseholdMembers;
@property (weak, nonatomic) IBOutlet UISegmentedControl *accidentSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tollSegment;
@property (weak, nonatomic) IBOutlet UITextField *tollCost;
@property (weak, nonatomic) IBOutlet UISegmentedControl *parkingSegment;
@property (weak, nonatomic) IBOutlet UITextField *parkingCost;
@property (weak, nonatomic) IBOutlet UILabel *fareQuestion;
@property (weak, nonatomic) IBOutlet UITextField *fareCost;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *startDatePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *endDatePicker;

@property (nonatomic, strong) TravelModePickerViewDataSource *tmDataSource;


//lx
@property (weak, nonatomic) IBOutlet UITextField *startTimeChange;
@property (weak, nonatomic) IBOutlet UITextField *endTimechange;
@property (weak, nonatomic) IBOutlet UISegmentedControl *householdmembersSegment;
@property (weak, nonatomic) IBOutlet UITableViewCell *houseMembersdynamic;
@property (weak, nonatomic) IBOutlet UISegmentedControl *nonHouseholdmembersSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *driverPassengerSegment;
@property (weak, nonatomic) IBOutlet UIPickerView *activityPicker;


@property (nonatomic, strong) PickerViewDataSource *activityPickerViewDataSource;
//@property (nonatomic, strong) PickerViewDataSource *travelModePicker;
@property NSManagedObjectContext *managedContext;
@property User *user;

@property (strong, nonatomic) NSString *housholdMemberselected;
@property (nonatomic) int numofhousholdMemberselected;
@property (weak, nonatomic) IBOutlet UINavigationBar *cancel;

@property (strong, nonatomic) NSString *familyMember;




//*lx
//[LIU]
@property (nonatomic, strong) Trip *trip;
- (id)initWithTrip:(Trip *)tripFromMapView;


- (id)initWithPurpose:(NSInteger)index;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)backgroundTouched:(id)sender;
- (IBAction)segmentChanged:(id)sender;
- (IBAction)segmentedControlChanged:(id)sender;

@end
