//
//  ServerInteract.h
//  FloridaTripTracker
//
//  Created by Pinchao Liu on 3/13/17.
//
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>



@interface ServerInteract : NSObject

+ (NSData*) sendRequest:(id)inPostVars toURLAddress:(NSString*) URLString;
+ (BOOL)connected;

@end
