//
//  ServerInteract.m
//  FloridaTripTracker
//
//  Created by Pinchao Liu on 3/13/17.
//
//

#import "ServerInteract.h"

@implementation ServerInteract

+ (NSData*) sendRequest:(id)inPostVars toURLAddress:(NSString*) URLString{
	if (![self connected]) {
		NSLog(@"%@",@"no internet connection");
		return nil;
	}
	else {
		NSData *postData;
		if ([inPostVars isKindOfClass:[NSDictionary class]] || [inPostVars isKindOfClass:[NSArray class]] ){
			postData= [NSJSONSerialization dataWithJSONObject:inPostVars options:nil error:nil];
		}
		else if([inPostVars isKindOfClass:[NSString class]]){
			postData = [inPostVars dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		}
		
		NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:URLString]];
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
		NSURLResponse *response;
		NSError *err;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		NSString *readableJsonText = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
		NSLog(@"Received Readable Json%@ from URLString: %@", readableJsonText, URLString);
		
		return responseData;
	}
}

+ (BOOL)connected
{
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [reachability currentReachabilityStatus];
	return networkStatus != NotReachable;
}


@end
