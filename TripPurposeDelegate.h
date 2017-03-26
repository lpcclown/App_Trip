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
//  TripPurposeDelegate.h
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/22/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>


#define kTripPurposeHome			0
#define kTripPurposeWork			1
#define kTripPurposeWorkRelated		2
#define kTripPurposeRecreation		3
#define kTripPurposeShopping		4
#define kTripPurposeSocial			5
#define kTripPurposeMeal			6
#define kTripPurposeSchool			7
#define kTripPurposeCollege			8
#define kTripPurposePersonalBiz		9
#define kTripPurposeEntertainment	10
#define kTripPurposePickUp			11
#define kTripPurposeOther			12


#define kTripPurposeHomeIcon			@"commute.png"
#define kTripPurposeWorkIcon			@"work-related.png"
#define kTripPurposeWorkRelatedIcon		@"work-related.png"
#define kTripPurposeRecreationIcon		@"exercise.png"
#define kTripPurposeShoppingIcon		@"shopping.png"
#define kTripPurposeSocialIcon			@"social.png"
#define kTripPurposeMealIcon			@"social.png"
#define kTripPurposeSchoolIcon			@"school.png"
#define kTripPurposeCollegeIcon			@"school.png"
#define kTripPurposePersonalBizIcon		@"other.png"
#define kTripPurposeEntertainmentIcon	@"exercise.png"
#define kTripPurposePickUpIcon			@"errands.png"
#define kTripPurposeOtherIcon			@"other.png"

#define kTripPurposeHomeString			@"Home activities (personal care, chores, or sleeping)"
#define kTripPurposeWorkString			@"Paid work (at place of employment or home)"
#define kTripPurposeWorkRelatedString	@"Work related (business travel, meeting, home service)"
#define kTripPurposeRecreationString	@"Recreation/leisure (running, hiking, working outs, social groups)"
#define kTripPurposeShoppingString		@"Shopping"
#define kTripPurposeSocialString		@"Visiting friends and relatives"
#define kTripPurposeMealString			@"Dining and Drinking (restaurant, drive-thru, coffee, bar)"
#define kTripPurposeSchoolString		@"Other school activities (studying, student meetings, clubs)"
#define kTripPurposeCollegeString		@"Attend classes (K-12, college, and professional)"
#define kTripPurposePersonalBizString	@"Personal business (medical, dental, banking, social services)"
#define kTripPurposeEntertainmentString	@"Entertainment/cultural events (concerts, movies, plays, and sports games)"
#define kTripPurposePickUpString		@"Pick-up/Drop-off passengers (spouse, child, friends, and relatives)"
#define kTripPurposeOtherString			@"Other"


@protocol TripPurposeDelegate <NSObject>

@required
- (NSString *)getPurposeString:(unsigned int)index;
- (NSString *)setPurpose:(unsigned int)index;

@optional
- (void)didCancelPurpose;
- (void)didPickPurpose:(NSMutableDictionary *)tripAnswers;

@end
