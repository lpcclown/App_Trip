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
//  MapViewController.h
//  CycleTracks
//
//  Copyright 2009-2013 SFCTA. All rights reserved.
//  Written by Matt Paul <mattpaul@mopimp.com> on 9/28/09.
//	For more information on the project, 
//	e-mail Elizabeth Sall at the SFCTA <elizabeth.sall@sfcta.org>

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "TripManager.h"


@interface MapViewController : UIViewController <MKMapViewDelegate, UIAlertViewDelegate>
{
	IBOutlet MKMapView *mapView;
	Trip *trip;
	//TripManager		*tripManager;
	UIBarButtonItem *doneButton;
	UIBarButtonItem *flipButton;
	UIView *infoView;
}


@property (nonatomic, strong) Trip *trip;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *flipButton;
@property (nonatomic, strong) UIView *infoView;
@property (weak, nonatomic) IBOutlet UIButton *viewTrips;
@property (weak, nonatomic) IBOutlet UIButton *addDetailInfo;
@property (weak, nonatomic) IBOutlet UIButton *removeTrip;//lx 0401
@property (weak, nonatomic) IBOutlet UILabel *tripInfo;

- (id)initWithTrip:(Trip *)trip;

@end
