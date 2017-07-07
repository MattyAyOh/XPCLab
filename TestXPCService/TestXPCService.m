//
//  TestXPCService.m
//  TestXPCService
//
//  Created by Matt Ao on 1/27/17.
//  Copyright © 2017 TechSmith. All rights reserved.
//

#import "TestXPCService.h"

@interface TestXPCService() <TestProtocol>
@property NSXPCListenerEndpoint *helperEndpoint;
@end

@implementation TestXPCService

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

- (void)testXPCMethod:(void (^)(NSString *))reply
{
   reply(@"heythere");
}

- (void)testMethod
{
   NSLog(@"HEY THERE");
}

- (void)setAnonymousEndpoint:(NSXPCListenerEndpoint *)endpoint
{
   NSLog(@"SENDING ENDPOINT!: %@ (with: %@)", endpoint, self);
   self.helperEndpoint = endpoint;
}
//
//-(NSXPCListenerEndpoint *)getAnonymousEndpoint
//{
//   return [[NSXPCListener anonymousListener] endpoint];
//}

- (void)getAnonymousEndpoint:(void (^)(NSXPCListenerEndpoint *))reply
{
   NSLog(@"ATTEMPTING TO GET ENDPOINT: %@ (with: %@)", self.helperEndpoint, self);
   reply(self.helperEndpoint);
}

@end
