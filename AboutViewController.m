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
//  AboutViewController.m
//  CycleTracks
//
//  Created by Matt Paul on 2/23/10.
//  Copyright 2010 mopimp productions. All rights reserved.
//

#import "AboutViewController.h"
#import "constants.h"


@implementation AboutViewController
@synthesize instruction;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
	UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FDOT"]]];
	self.navigationItem.rightBarButtonItem = item;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kInstructionsURL]]];
	instruction.delegate = self;
	instruction.enablesReturnKeyAutomatically = NO;
	instruction.font = [UIFont fontWithName:@"Arial" size:20];
	instruction.keyboardAppearance = UIKeyboardAppearanceAlert;
	instruction.keyboardType = UIKeyboardTypeDefault;
	instruction.returnKeyType = UIReturnKeyDone;
	instruction.text = KAppInstructions;
	instruction.backgroundColor = [UIColor blackColor];
	instruction.textColor = [UIColor whiteColor];
	instruction.editable = NO;
//	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"before after"];
//	NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
//	textAttachment.image = [UIImage imageNamed:@"SurveyLogo1.jpg"];
//	
//	CGFloat oldWidth = textAttachment.image.size.width;
//	
//	//I'm subtracting 10px to make the image display nicely, accounting
//	//for the padding inside the textView
//	CGFloat scaleFactor = oldWidth / (instruction.frame.size.width - 10);
//	textAttachment.image = [UIImage imageWithCGImage:textAttachment.image.CGImage scale:scaleFactor orientation:UIImageOrientationUp];
//	NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
//	[attributedString replaceCharactersInRange:NSMakeRange(6, 1) withAttributedString:attrStringWithImage];
//	instruction.attributedText = attributedString;
	
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




@end
