//
//  TravelModePickerViewDataSource.h
//  FloridaTripTracker
//
//  Created by Benaiah Pitts on 12/18/14.
//
//

#import <Foundation/Foundation.h>

@interface TravelModePickerViewDataSource : NSObject <UIPickerViewDataSource, UIPickerViewDelegate>

@property NSMutableArray *travelModes;

// Travel Mode descriptions
@property NSString *travelModePersonalVehicle;
@property NSString *travelModePublicTransit;
@property NSString *travelModeSchoolBus;
@property NSString *travelModeWalk;
@property NSString *travelModeBicycle;
@property NSString *travelModeCarpool;
@property NSString *travelModeOther;
//lx
@property NSString *travelModePersonalbigVehicle;
@property NSString *travelModePersonalsmallVehicle;
@property NSString *travelModePublicBus;
@property NSString *travelModeTaxiCab;
@property NSString *travelModeCarService;
@property NSString *travelModeWalked;

//*lx

@property (nonatomic, strong) id<UIPickerViewDelegate> parent;

@end
