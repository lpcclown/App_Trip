//
//  WelcomeViewController.m
//  FloridaTripTracker
//
//  Created by Benaiah Pitts on 1/14/15.
//
//

#import "WelcomeViewController.h"
#import "OneTimeQuestionsViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

@synthesize textView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	[textView setText:@"\n\n\n\nPlease enter your household ID to begin. Be sure to select your name from the list of your household members to record your travel.\n\nThanks,\nMyTripDiary Team"];
	
	[self setTitle:@"Welcome to MyTripDiary App!"];//lx 0405
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)continueButtonPressed:(id)sender {
	OneTimeQuestionsViewController *vc= [[OneTimeQuestionsViewController alloc] initWithNibName:@"OneTimeQuestionsViewController" bundle:nil];
	
	[[self navigationController] pushViewController:vc animated:YES];
}
@end
