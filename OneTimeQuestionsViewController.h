//
//  OneTimeQuestionsViewController.h
//  FloridaTripTracker
//
//  Created by Benaiah Pitts on 12/29/14.
//
//

#import <UIKit/UIKit.h>
#import "PickerViewDataSourceParent.h"
@class PickerViewDataSource;
@class TravelModePickerViewDataSource;
@class User;
@class LoadingView;

@interface OneTimeQuestionsViewController : UIViewController <UIScrollViewDelegate, PickerViewDataSourceParent, UIAlertViewDelegate>{
LoadingView *loading;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gender;
@property (weak, nonatomic) IBOutlet UIPickerView *agePicker;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fullTimeSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *partTimeSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fiveMonthSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unemployedSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *retiredSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *workAtHomeSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *homemakerSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *selfEmployedSegment;
@property (weak, nonatomic) IBOutlet UIStepper *workTripStepper;
@property (weak, nonatomic) IBOutlet UILabel *workTripNumber;
@property (weak, nonatomic) IBOutlet UISegmentedControl *studentSegment;
@property (weak, nonatomic) IBOutlet UILabel *studentStatusLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *studentStatusPicker;
@property (weak, nonatomic) IBOutlet UISegmentedControl *licenseSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *transitPassSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *disabledPassSegment;


//lx

@property (weak, nonatomic) IBOutlet UIPickerView *namePicker;//lxx
@property (weak, nonatomic) IBOutlet UITextField *householdID;//lxx
@property (weak, nonatomic) IBOutlet UITextField *rehouseholdID;//lxx
@property (weak, nonatomic) IBOutlet UITextField *userinfoid;
@property (weak, nonatomic) IBOutlet UITextField *reuserinfoid;
@property (weak, nonatomic) IBOutlet UITextField *initialinfo;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderinfo;
@property (weak, nonatomic) IBOutlet UIPickerView *ageinfo;
@property (weak, nonatomic) IBOutlet UITextView *familymembersinfo;
@property (weak, nonatomic) IBOutlet UISegmentedControl *driverlicense;
@property (strong, nonatomic) NSString *deviceNum;

@property (weak, nonatomic) IBOutlet UILabel *q1;
@property (weak, nonatomic) IBOutlet UILabel *q2;
@property (weak, nonatomic) IBOutlet UILabel *q3;
@property (weak, nonatomic) IBOutlet UILabel *q4;
@property (weak, nonatomic) IBOutlet UILabel *q5;
@property (weak, nonatomic) IBOutlet UILabel *q6;
@property (weak, nonatomic) IBOutlet UILabel *modifylabel;
@property (nonatomic, strong) PickerViewDataSource *ageinfoDataSource;
@property (nonatomic, strong) PickerViewDataSource *namePickerDataSource;//lxx

@property (weak, nonatomic) IBOutlet UIButton *submitID;//lxx
@property (weak, nonatomic) IBOutlet UIButton *submit;
@property (weak, nonatomic) IBOutlet UINavigationBar *confirmlabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmyes;
@property (weak, nonatomic) IBOutlet UIButton *confirmno;
@property (weak, nonatomic) IBOutlet UIButton *modify;

//*lx

@property NSManagedObjectContext *managedContext;
@property User *user;
@property NSArray* memberArray;

- (IBAction)ageSegmentChanged:(id)sender;

//lx
- (IBAction)backgroundTouched:(id)sender;


- (IBAction)submitIDButtonTapped:(id)sender;
- (IBAction)submitButtonTapped:(id)sender;
- (IBAction)confirmyesButtonTapped:(id)sender;
- (IBAction)confirmnoButtonTapped:(id)sender;
- (IBAction)modifyButtonTapped:(id)sender;
//*lx
@end
