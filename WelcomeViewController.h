//
//  WelcomeViewController.h
//  FloridaTripTracker
//
//  Created by Benaiah Pitts on 1/14/15.
//
//

#import <UIKit/UIKit.h>

@interface WelcomeViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *textView;
- (IBAction)continueButtonPressed:(id)sender;

@end
