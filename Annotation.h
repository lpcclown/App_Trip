//
//  Annotation.h
//  FloridaTripTracker
//
//  Created by Pinchao Liu on 2/17/17.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Annotation : NSObject <MKAnnotation>

@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy) NSString * title;
@property(nonatomic, copy) NSString * subtitle;

@end
